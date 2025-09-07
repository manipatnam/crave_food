// lib/models/restaurant.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String restaurantId; // Google Place ID
  final String name;
  final String address;
  final GeoPoint coordinates;
  final String googlePlaceId;

  // Google Places data
  final List<String> cuisineTypes;
  final String? priceLevel;
  final double? googleRating;
  final int? googleReviewCount;
  final String? phoneNumber;
  final String? website;

  // Aggregated review data (updated via Cloud Functions or batch operations)
  final ReviewStats reviewStats;

  // Metadata
  final DateTime? firstReviewDate;
  final DateTime? lastReviewDate;
  final DateTime lastUpdated;

  // Featured reviews (top 3 for quick access)
  final List<FeaturedReview> featuredReviews;

  Restaurant({
    required this.restaurantId,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.googlePlaceId,
    this.cuisineTypes = const [],
    this.priceLevel,
    this.googleRating,
    this.googleReviewCount,
    this.phoneNumber,
    this.website,
    required this.reviewStats,
    this.firstReviewDate,
    this.lastReviewDate,
    required this.lastUpdated,
    this.featuredReviews = const [],
  });

  // Create from Firestore document
  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Restaurant(
      restaurantId: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      coordinates: data['coordinates'] ?? const GeoPoint(0, 0),
      googlePlaceId: data['googlePlaceId'] ?? '',
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      priceLevel: data['priceLevel'],
      googleRating: (data['googleRating'] as num?)?.toDouble(),
      googleReviewCount: data['googleReviewCount'],
      phoneNumber: data['phoneNumber'],
      website: data['website'],
      reviewStats: ReviewStats.fromMap(data['reviewStats'] ?? {}),
      firstReviewDate: data['firstReviewDate'] != null 
          ? (data['firstReviewDate'] as Timestamp).toDate() 
          : null,
      lastReviewDate: data['lastReviewDate'] != null 
          ? (data['lastReviewDate'] as Timestamp).toDate() 
          : null,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      featuredReviews: (data['featuredReviews'] as List<dynamic>?)
              ?.map((reviewData) => FeaturedReview.fromMap(reviewData as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Create from Google Places data
  factory Restaurant.fromGooglePlaces(Map<String, dynamic> googleData, String placeId) {
    // Extract location
    final location = googleData['geometry']?['location'];
    final geoPoint = location != null 
        ? GeoPoint(location['lat'].toDouble(), location['lng'].toDouble())
        : const GeoPoint(0, 0);

    // Extract cuisine types and clean them up
    final types = (googleData['types'] as List<dynamic>?)
        ?.map((type) => type.toString())
        .where((type) => !['establishment', 'point_of_interest'].contains(type))
        .take(5)
        .toList() ?? [];

    // Format price level
    String? priceLevel;
    if (googleData['price_level'] != null) {
      final level = googleData['price_level'] as int;
      priceLevel = '\$' * level;
    }

    return Restaurant(
      restaurantId: placeId,
      name: googleData['name'] ?? '',
      address: googleData['formatted_address'] ?? googleData['vicinity'] ?? '',
      coordinates: geoPoint,
      googlePlaceId: placeId,
      cuisineTypes: types,
      priceLevel: priceLevel,
      googleRating: (googleData['rating'] as num?)?.toDouble(),
      googleReviewCount: googleData['user_ratings_total'],
      phoneNumber: googleData['formatted_phone_number'],
      website: googleData['website'],
      reviewStats: ReviewStats.empty(), // Empty stats for new restaurant
      lastUpdated: DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'coordinates': coordinates,
      'googlePlaceId': googlePlaceId,
      'cuisineTypes': cuisineTypes,
      'priceLevel': priceLevel,
      'googleRating': googleRating,
      'googleReviewCount': googleReviewCount,
      'phoneNumber': phoneNumber,
      'website': website,
      'reviewStats': reviewStats.toMap(),
      'firstReviewDate': firstReviewDate != null ? Timestamp.fromDate(firstReviewDate!) : null,
      'lastReviewDate': lastReviewDate != null ? Timestamp.fromDate(lastReviewDate!) : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'featuredReviews': featuredReviews.map((review) => review.toMap()).toList(),
    };
  }

  // Create copy with modified fields
  Restaurant copyWith({
    String? restaurantId,
    String? name,
    String? address,
    GeoPoint? coordinates,
    String? googlePlaceId,
    List<String>? cuisineTypes,
    String? priceLevel,
    double? googleRating,
    int? googleReviewCount,
    String? phoneNumber,
    String? website,
    ReviewStats? reviewStats,
    DateTime? firstReviewDate,
    DateTime? lastReviewDate,
    DateTime? lastUpdated,
    List<FeaturedReview>? featuredReviews,
  }) {
    return Restaurant(
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      priceLevel: priceLevel ?? this.priceLevel,
      googleRating: googleRating ?? this.googleRating,
      googleReviewCount: googleReviewCount ?? this.googleReviewCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      reviewStats: reviewStats ?? this.reviewStats,
      firstReviewDate: firstReviewDate ?? this.firstReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      featuredReviews: featuredReviews ?? this.featuredReviews,
    );
  }

  // Display helpers
  String get cuisineDisplay {
    if (cuisineTypes.isEmpty) return '';
    return cuisineTypes
        .take(3) // Show max 3 cuisine types
        .map((type) => type.replaceAll('_', ' ').split(' ').map((word) => 
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' '))
        .join(' • ');
  }

  String get ratingDisplay {
    if (reviewStats.totalReviews > 0) {
      return '${reviewStats.avgOverallRating.toStringAsFixed(1)} (${reviewStats.totalReviews} reviews)';
    } else if (googleRating != null) {
      return '${googleRating!.toStringAsFixed(1)} (Google)';
    }
    return 'No ratings';
  }

  // For debugging
  @override
  String toString() {
    return 'Restaurant(id: $restaurantId, name: $name, totalReviews: ${reviewStats.totalReviews})';
  }
}

// Aggregated review statistics
class ReviewStats {
  final int totalReviews;
  final int publicReviews;
  final int friendsOnlyReviews;

  // Multi-dimensional averages
  final double avgOverallRating;
  final double avgFoodRating;
  final double avgServiceRating;
  final double avgAmbienceRating;
  final double avgValueRating;

  // Rating distribution (1-5 stars)
  final Map<String, int> ratingDistribution;

  ReviewStats({
    this.totalReviews = 0,
    this.publicReviews = 0,
    this.friendsOnlyReviews = 0,
    this.avgOverallRating = 0.0,
    this.avgFoodRating = 0.0,
    this.avgServiceRating = 0.0,
    this.avgAmbienceRating = 0.0,
    this.avgValueRating = 0.0,
    this.ratingDistribution = const {},
  });

  factory ReviewStats.empty() {
    return ReviewStats(
      ratingDistribution: {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
      },
    );
  }

  factory ReviewStats.fromMap(Map<String, dynamic> map) {
    return ReviewStats(
      totalReviews: map['totalReviews'] ?? 0,
      publicReviews: map['publicReviews'] ?? 0,
      friendsOnlyReviews: map['friendsOnlyReviews'] ?? 0,
      avgOverallRating: (map['avgOverallRating'] as num?)?.toDouble() ?? 0.0,
      avgFoodRating: (map['avgFoodRating'] as num?)?.toDouble() ?? 0.0,
      avgServiceRating: (map['avgServiceRating'] as num?)?.toDouble() ?? 0.0,
      avgAmbienceRating: (map['avgAmbienceRating'] as num?)?.toDouble() ?? 0.0,
      avgValueRating: (map['avgValueRating'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: Map<String, int>.from(map['ratingDistribution'] ?? {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0,
        '5': 0,
      }),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalReviews': totalReviews,
      'publicReviews': publicReviews,
      'friendsOnlyReviews': friendsOnlyReviews,
      'avgOverallRating': avgOverallRating,
      'avgFoodRating': avgFoodRating,
      'avgServiceRating': avgServiceRating,
      'avgAmbienceRating': avgAmbienceRating,
      'avgValueRating': avgValueRating,
      'ratingDistribution': ratingDistribution,
    };
  }

  ReviewStats copyWith({
    int? totalReviews,
    int? publicReviews,
    int? friendsOnlyReviews,
    double? avgOverallRating,
    double? avgFoodRating,
    double? avgServiceRating,
    double? avgAmbienceRating,
    double? avgValueRating,
    Map<String, int>? ratingDistribution,
  }) {
    return ReviewStats(
      totalReviews: totalReviews ?? this.totalReviews,
      publicReviews: publicReviews ?? this.publicReviews,
      friendsOnlyReviews: friendsOnlyReviews ?? this.friendsOnlyReviews,
      avgOverallRating: avgOverallRating ?? this.avgOverallRating,
      avgFoodRating: avgFoodRating ?? this.avgFoodRating,
      avgServiceRating: avgServiceRating ?? this.avgServiceRating,
      avgAmbienceRating: avgAmbienceRating ?? this.avgAmbienceRating,
      avgValueRating: avgValueRating ?? this.avgValueRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
}

// Featured review for quick access
class FeaturedReview {
  final String reviewId;
  final String userId;
  final String userName;
  final double overallRating;
  final String writtenReview;
  final int helpfulCount;
  final DateTime reviewDate;

  FeaturedReview({
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.overallRating,
    required this.writtenReview,
    required this.helpfulCount,
    required this.reviewDate,
  });

  factory FeaturedReview.fromMap(Map<String, dynamic> map) {
    return FeaturedReview(
      reviewId: map['reviewId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      overallRating: (map['overallRating'] as num?)?.toDouble() ?? 0.0,
      writtenReview: map['writtenReview'] ?? '',
      helpfulCount: map['helpfulCount'] ?? 0,
      reviewDate: (map['reviewDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'userName': userName,
      'overallRating': overallRating,
      'writtenReview': writtenReview,
      'helpfulCount': helpfulCount,
      'reviewDate': Timestamp.fromDate(reviewDate),
    };
  }

  // Create featured review from full review
  factory FeaturedReview.fromRestaurantReview(dynamic restaurantReview) {
    return FeaturedReview(
      reviewId: restaurantReview.id,
      userId: restaurantReview.userId,
      userName: restaurantReview.userName,
      overallRating: restaurantReview.ratings.overallRating,
      writtenReview: restaurantReview.writtenReview.length > 100 
          ? '${restaurantReview.writtenReview.substring(0, 100)}...'
          : restaurantReview.writtenReview,
      helpfulCount: restaurantReview.helpfulCount,
      reviewDate: restaurantReview.reviewDate,
    );
  }
}