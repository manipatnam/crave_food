// lib/services/restaurants_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/restaurant.dart';
import '../models/restaurant_review.dart';
import '../services/google_places_services.dart';
import '../models/place_model.dart';
import '../models/review_enums.dart';

class RestaurantsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GooglePlacesService _placesService = GooglePlacesService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get restaurants collection reference
  CollectionReference get _restaurantsCollection => _firestore.collection('restaurants');

  // Get or create restaurant from Google Places data
  Future<Restaurant> getOrCreateRestaurant(String googlePlaceId) async {
    try {
      print('🏪 RestaurantsService: Getting or creating restaurant: $googlePlaceId');

      // Check if restaurant already exists in cache
      final existingDoc = await _restaurantsCollection.doc(googlePlaceId).get();
      
      if (existingDoc.exists) {
        print('✅ RestaurantsService: Restaurant found in cache');
        return Restaurant.fromFirestore(existingDoc);
      }

      // Fetch from Google Places API
      print('🔍 RestaurantsService: Fetching restaurant from Google Places API');
      final placeDetails = await _placesService.getPlaceDetails(googlePlaceId);
      
      if (placeDetails == null) {
        throw 'Could not fetch restaurant details from Google Places';
      }

      // Convert PlaceModel to Restaurant and cache it
      final restaurant = _convertPlaceModelToRestaurant(placeDetails);
      await _restaurantsCollection.doc(googlePlaceId).set(restaurant.toFirestore());

      print('✅ RestaurantsService: Restaurant cached successfully');
      return restaurant;
    } catch (e) {
      print('❌ RestaurantsService: Error getting or creating restaurant: $e');
      throw 'Failed to get restaurant data: $e';
    }
  }

  // Get restaurant by ID from cache
  Future<Restaurant?> getRestaurantById(String restaurantId) async {
    try {
      print('🏪 RestaurantsService: Getting restaurant by ID: $restaurantId');

      final doc = await _restaurantsCollection.doc(restaurantId).get();
      
      if (doc.exists) {
        print('✅ RestaurantsService: Restaurant found');
        return Restaurant.fromFirestore(doc);
      }
      
      print('⚠️ RestaurantsService: Restaurant not found in cache');
      return null;
    } catch (e) {
      print('❌ RestaurantsService: Error getting restaurant by ID: $e');
      return null;
    }
  }

  // Search restaurants (combining cached data and Google Places)
  Future<List<Restaurant>> searchRestaurants(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];

    try {
      print('🔍 RestaurantsService: Searching restaurants for: "$query"');

      List<Restaurant> results = [];

      // 1. Search in cached restaurants first
      final cachedResults = await _searchCachedRestaurants(query, limit: limit ~/ 2);
      results.addAll(cachedResults);

      // 2. Search Google Places for additional results
      if (results.length < limit) {
        final googleResults = await _searchGooglePlaces(query, limit: limit - results.length);
        results.addAll(googleResults);
      }

      // Remove duplicates based on restaurantId
      final uniqueResults = <String, Restaurant>{};
      for (final restaurant in results) {
        uniqueResults[restaurant.restaurantId] = restaurant;
      }

      final finalResults = uniqueResults.values.take(limit).toList();
      print('📊 RestaurantsService: Found ${finalResults.length} restaurants');
      
      return finalResults;
    } catch (e) {
      print('❌ RestaurantsService: Error searching restaurants: $e');
      return [];
    }
  }

  // Update restaurant aggregated stats (called when reviews are added/updated)
  Future<void> updateRestaurantStats(String restaurantId) async {
    try {
      print('📊 RestaurantsService: Updating stats for restaurant: $restaurantId');

      // Get all reviews for this restaurant
      final reviewsSnapshot = await _firestore
          .collection('restaurant_reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      final reviews = reviewsSnapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();

      if (reviews.isEmpty) {
        print('⚠️ RestaurantsService: No reviews found for restaurant');
        return;
      }

      // Calculate aggregated statistics
      final stats = _calculateRestaurantStats(reviews);

      // Get featured reviews (top 3 by helpful votes)
      final featuredReviews = _getFeaturedReviews(reviews);

      // Update restaurant document
      final restaurantRef = _restaurantsCollection.doc(restaurantId);
      await restaurantRef.update({
        'reviewStats': stats.toMap(),
        'firstReviewDate': reviews.isNotEmpty 
            ? Timestamp.fromDate(reviews.map((r) => r.reviewDate).reduce((a, b) => a.isBefore(b) ? a : b))
            : null,
        'lastReviewDate': reviews.isNotEmpty 
            ? Timestamp.fromDate(reviews.map((r) => r.reviewDate).reduce((a, b) => a.isAfter(b) ? a : b))
            : null,
        'featuredReviews': featuredReviews.map((r) => r.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ RestaurantsService: Restaurant stats updated successfully');
    } catch (e) {
      print('❌ RestaurantsService: Error updating restaurant stats: $e');
      // Don't throw here to avoid blocking review operations
    }
  }

  // Get restaurants near a location
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
    int limit = 20,
  }) async {
    try {
      print('🗺️ RestaurantsService: Getting restaurants near ($latitude, $longitude)');

      // For now, get from Google Places directly
      // Future: implement geo-queries on cached restaurants
      final places = await _placesService.getNearbyRestaurants(
        latitude: latitude,
        longitude: longitude,
        radius: (radiusInKm * 1000).round(), // Convert to meters
      );

      final restaurants = <Restaurant>[];
      
      for (final place in places.take(limit)) {
        try {
          // Try to get cached version first, otherwise convert from PlaceModel
          final cachedRestaurant = await getRestaurantById(place.placeId);
          if (cachedRestaurant != null) {
            restaurants.add(cachedRestaurant);
          } else {
            restaurants.add(_convertPlaceModelToRestaurant(place));
          }
        } catch (e) {
          print('⚠️ RestaurantsService: Error processing place ${place.name}: $e');
          // Continue with other places
        }
      }

      print('📊 RestaurantsService: Found ${restaurants.length} nearby restaurants');
      return restaurants;
    } catch (e) {
      print('❌ RestaurantsService: Error getting nearby restaurants: $e');
      return [];
    }
  }

  // Get trending restaurants (most reviewed recently)
  Future<List<Restaurant>> getTrendingRestaurants({
    int days = 7,
    int limit = 10,
  }) async {
    try {
      print('📈 RestaurantsService: Getting trending restaurants (last $days days)');

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      // Get recent reviews
      final recentReviewsSnapshot = await _firestore
          .collection('restaurant_reviews')
          .where('reviewDate', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .where('privacy', isEqualTo: 'public')
          .get();

      // Count reviews per restaurant
      final restaurantReviewCounts = <String, int>{};
      for (final doc in recentReviewsSnapshot.docs) {
        final data = doc.data();
        final restaurantId = data['restaurantId'] as String;
        restaurantReviewCounts[restaurantId] = (restaurantReviewCounts[restaurantId] ?? 0) + 1;
      }

      // Sort by review count and get restaurant details
      final sortedRestaurants = restaurantReviewCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final trendingRestaurants = <Restaurant>[];
      
      for (final entry in sortedRestaurants.take(limit)) {
        try {
          final restaurant = await getRestaurantById(entry.key);
          if (restaurant != null) {
            trendingRestaurants.add(restaurant);
          }
        } catch (e) {
          print('⚠️ RestaurantsService: Error getting trending restaurant ${entry.key}: $e');
        }
      }

      print('📊 RestaurantsService: Found ${trendingRestaurants.length} trending restaurants');
      return trendingRestaurants;
    } catch (e) {
      print('❌ RestaurantsService: Error getting trending restaurants: $e');
      return [];
    }
  }

  // Get top-rated restaurants
  Future<List<Restaurant>> getTopRatedRestaurants({int limit = 10}) async {
    try {
      print('⭐ RestaurantsService: Getting top-rated restaurants');

      final snapshot = await _restaurantsCollection
          .where('reviewStats.totalReviews', isGreaterThan: 0)
          .orderBy('reviewStats.totalReviews')
          .orderBy('reviewStats.avgOverallRating', descending: true)
          .limit(limit * 2) // Get more to filter properly
          .get();

      final restaurants = snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .where((restaurant) => restaurant.reviewStats.totalReviews >= 2) // At least 2 reviews
          .toList();

      // Sort by average rating (client-side for better control)
      restaurants.sort((a, b) => b.reviewStats.avgOverallRating.compareTo(a.reviewStats.avgOverallRating));

      final topRated = restaurants.take(limit).toList();
      print('📊 RestaurantsService: Found ${topRated.length} top-rated restaurants');
      
      return topRated;
    } catch (e) {
      print('❌ RestaurantsService: Error getting top-rated restaurants: $e');
      return [];
    }
  }

  // Delete restaurant from cache (admin function)
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      print('🗑️ RestaurantsService: Deleting restaurant: $restaurantId');

      await _restaurantsCollection.doc(restaurantId).delete();

      print('✅ RestaurantsService: Restaurant deleted successfully');
    } catch (e) {
      print('❌ RestaurantsService: Error deleting restaurant: $e');
      throw 'Failed to delete restaurant: $e';
    }
  }

  // PRIVATE HELPER METHODS

  // Search in cached restaurants
  Future<List<Restaurant>> _searchCachedRestaurants(String query, {int limit = 10}) async {
    try {
      final queryLower = query.toLowerCase();

      // Get restaurants from cache (limited search capability)
      final snapshot = await _restaurantsCollection.limit(50).get();
      
      final restaurants = snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .where((restaurant) {
            return restaurant.name.toLowerCase().contains(queryLower) ||
                   restaurant.cuisineTypes.any((cuisine) => cuisine.toLowerCase().contains(queryLower));
          })
          .take(limit)
          .toList();

      print('📊 RestaurantsService: Found ${restaurants.length} cached restaurants matching "$query"');
      return restaurants;
    } catch (e) {
      print('❌ RestaurantsService: Error searching cached restaurants: $e');
      return [];
    }
  }

  // Search Google Places and convert to Restaurant models
  Future<List<Restaurant>> _searchGooglePlaces(String query, {int limit = 10}) async {
    try {
      final places = await _placesService.searchPlaces(query);
      
      final restaurants = places
          .take(limit)
          .map((place) => _convertPlaceModelToRestaurant(place))
          .toList();

      print('📊 RestaurantsService: Found ${restaurants.length} restaurants from Google Places');
      return restaurants;
    } catch (e) {
      print('❌ RestaurantsService: Error searching Google Places: $e');
      return [];
    }
  }

  // Convert PlaceModel to Restaurant
  Restaurant _convertPlaceModelToRestaurant(PlaceModel place) {
    return Restaurant(
      restaurantId: place.placeId,
      name: place.name,
      address: place.displayAddress,
      coordinates: place.geoPoint,
      googlePlaceId: place.placeId,
      cuisineTypes: place.types,
      priceLevel: place.priceLevel,
      googleRating: place.rating,
      googleReviewCount: place.userRatingsTotal,
      phoneNumber: place.phoneNumber,
      website: place.website,
      reviewStats: ReviewStats.empty(),
      lastUpdated: DateTime.now(),
    );
  }

  // Calculate aggregated statistics from reviews
  ReviewStats _calculateRestaurantStats(List<RestaurantReview> reviews) {
    if (reviews.isEmpty) return ReviewStats.empty();

    final publicReviews = reviews.where((r) => r.privacy == ReviewPrivacy.public).toList();
    final friendsOnlyReviews = reviews.where((r) => r.privacy == ReviewPrivacy.friends).toList();

    // Calculate averages
    final avgOverall = reviews.fold<double>(0.0, (sum, r) => sum + r.ratings.overallRating) / reviews.length;
    final avgFood = reviews.fold<double>(0.0, (sum, r) => sum + r.ratings.foodRating) / reviews.length;
    final avgService = reviews.fold<double>(0.0, (sum, r) => sum + r.ratings.serviceRating) / reviews.length;
    final avgAmbience = reviews.fold<double>(0.0, (sum, r) => sum + r.ratings.ambienceRating) / reviews.length;
    final avgValue = reviews.fold<double>(0.0, (sum, r) => sum + r.ratings.valueRating) / reviews.length;

    // Calculate rating distribution
    final distribution = <String, int>{
      '1': 0,
      '2': 0,
      '3': 0,
      '4': 0,
      '5': 0,
    };

    for (final review in reviews) {
      final rating = review.ratings.overallRating.round().toString();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return ReviewStats(
      totalReviews: reviews.length,
      publicReviews: publicReviews.length,
      friendsOnlyReviews: friendsOnlyReviews.length,
      avgOverallRating: avgOverall,
      avgFoodRating: avgFood,
      avgServiceRating: avgService,
      avgAmbienceRating: avgAmbience,
      avgValueRating: avgValue,
      ratingDistribution: distribution,
    );
  }

  // Get featured reviews (top 3 most helpful)
  List<FeaturedReview> _getFeaturedReviews(List<RestaurantReview> reviews) {
    if (reviews.isEmpty) return [];

    // Sort by helpful count and take top 3
    final sortedReviews = [...reviews]
      ..sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));

    return sortedReviews
        .take(3)
        .map((review) => FeaturedReview.fromRestaurantReview(review))
        .toList();
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      print('🔍 RestaurantsService: Testing Firestore connection...');
      
      await _restaurantsCollection.limit(1).get();
      print('✅ RestaurantsService: Firestore connection test successful');
      
      return true;
    } catch (e) {
      print('❌ RestaurantsService: Firestore connection test failed: $e');
      return false;
    }
  }
}