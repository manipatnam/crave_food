// lib/services/reviews_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/restaurant_review.dart';
import '../models/review_enums.dart';
import 'dart:math' as math;

enum ReviewSortType {
  newest,
  oldest,
  highestRated,
  lowestRated,
  mostHelpful,
}

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get current user name for denormalization
  String get _currentUserName => _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Anonymous';

  // Get restaurant reviews collection reference
  CollectionReference get _reviewsCollection => _firestore.collection('restaurant_reviews');

  // Add a new review
  Future<String> addReview(RestaurantReview review) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('🍽️ ReviewsService: Adding review for ${review.restaurantName}');

      // Generate document reference with auto-ID
      final docRef = _reviewsCollection.doc();
      
      // Update review with generated ID and current user info
      final reviewToAdd = review.copyWith(
        id: docRef.id,
        userId: _currentUserId!,
        userName: _currentUserName,
        userDisplayName: _auth.currentUser?.displayName,
        reviewDate: DateTime.now(),
        lastUpdated: DateTime.now(),
        searchTerms: _generateSearchTerms(review),
      );

      // Add to Firestore
      await docRef.set(reviewToAdd.toFirestore());

      print('✅ ReviewsService: Review added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ ReviewsService: Error adding review: $e');
      throw 'Failed to add review: $e';
    }
  }

  // Update an existing review
  Future<void> updateReview(RestaurantReview review) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    if (review.userId != _currentUserId) {
      throw 'You can only update your own reviews';
    }

    try {
      print('🍽️ ReviewsService: Updating review ${review.id}');

      final updatedReview = review.copyWith(
        lastUpdated: DateTime.now(),
        searchTerms: _generateSearchTerms(review),
      );

      await _reviewsCollection.doc(review.id).update(updatedReview.toFirestore());

      print('✅ ReviewsService: Review updated successfully');
    } catch (e) {
      print('❌ ReviewsService: Error updating review: $e');
      throw 'Failed to update review: $e';
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('🍽️ ReviewsService: Deleting review $reviewId');

      // Check if user owns the review
      final reviewDoc = await _reviewsCollection.doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw 'Review not found';
      }

      final reviewData = reviewDoc.data() as Map<String, dynamic>;
      if (reviewData['userId'] != _currentUserId) {
        throw 'You can only delete your own reviews';
      }

      await _reviewsCollection.doc(reviewId).delete();

      print('✅ ReviewsService: Review deleted successfully');
    } catch (e) {
      print('❌ ReviewsService: Error deleting review: $e');
      throw 'Failed to delete review: $e';
    }
  }

  // Get reviews for a specific restaurant
  Stream<List<RestaurantReview>> getRestaurantReviews(
    String restaurantId, {
    ReviewSortType sortBy = ReviewSortType.newest,
    int limit = 20,
  }) {
    print('🍽️ ReviewsService: Getting reviews for restaurant: $restaurantId');

    Query query = _reviewsCollection
        .where('restaurantId', isEqualTo: restaurantId)
        .where('privacy', isEqualTo: 'public') // Only public reviews for now
        .limit(limit);

    // Apply sorting
    query = _applySorting(query, sortBy);

    return query.snapshots().map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();
      
      print('📊 ReviewsService: Found ${reviews.length} reviews for restaurant');
      return reviews;
    });
  }

  // Get all public reviews (main feed)
  Stream<List<RestaurantReview>> getPublicReviews({
    ReviewSortType sortBy = ReviewSortType.newest,
    int limit = 20,
  }) {
    print('🍽️ ReviewsService: Getting public reviews feed');

    Query query = _reviewsCollection
        .where('privacy', isEqualTo: 'public')
        .limit(limit);

    query = _applySorting(query, sortBy);

    return query.snapshots().map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();
      
      print('📊 ReviewsService: Found ${reviews.length} public reviews');
      return reviews;
    });
  }

  // Get reviews by current user
  Stream<List<RestaurantReview>> getUserReviews({
    String? userId,
    ReviewSortType sortBy = ReviewSortType.newest,
    int limit = 50,
  }) {
    final targetUserId = userId ?? _currentUserId;
    
    if (targetUserId == null) {
      print('❌ ReviewsService: No user ID provided');
      return Stream.value([]);
    }

    print('🍽️ ReviewsService: Getting reviews for user: $targetUserId');

    Query query = _reviewsCollection
        .where('userId', isEqualTo: targetUserId)
        .limit(limit);

    // If viewing other user's reviews, only show public ones
    if (targetUserId != _currentUserId) {
      query = query.where('privacy', isEqualTo: 'public');
    }

    query = _applySorting(query, sortBy);

    return query.snapshots().map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();
      
      print('📊 ReviewsService: Found ${reviews.length} reviews for user');
      return reviews;
    });
  }

  // Get a specific review by ID
  Future<RestaurantReview?> getReviewById(String reviewId) async {
    try {
      print('🍽️ ReviewsService: Getting review by ID: $reviewId');

      final doc = await _reviewsCollection.doc(reviewId).get();
      
      if (doc.exists) {
        final review = RestaurantReview.fromFirestore(doc);
        print('✅ ReviewsService: Review found');
        return review;
      }
      
      print('⚠️ ReviewsService: Review not found');
      return null;
    } catch (e) {
      print('❌ ReviewsService: Error getting review by ID: $e');
      return null;
    }
  }

  // Search reviews by restaurant name or review content
  Future<List<RestaurantReview>> searchReviews(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    try {
      print('🔍 ReviewsService: Searching reviews for: "$query"');

      final queryLower = query.toLowerCase();

      // Get recent reviews and filter client-side (Firestore limitations)
      final snapshot = await _reviewsCollection
          .where('privacy', isEqualTo: 'public')
          .orderBy('reviewDate', descending: true)
          .limit(100) // Get more to filter from
          .get();

      final allReviews = snapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();

      // Client-side filtering
      final filteredReviews = allReviews.where((review) {
        return review.restaurantName.toLowerCase().contains(queryLower) ||
               review.writtenReview.toLowerCase().contains(queryLower) ||
               review.searchTerms.any((term) => term.toLowerCase().contains(queryLower));
      }).take(limit).toList();

      print('📊 ReviewsService: Found ${filteredReviews.length} matching reviews');
      return filteredReviews;
    } catch (e) {
      print('❌ ReviewsService: Error searching reviews: $e');
      return [];
    }
  }

  // Add helpful vote to a review
  Future<void> addHelpfulVote(String reviewId) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('🍽️ ReviewsService: Adding helpful vote to review: $reviewId');

      await _firestore.runTransaction((transaction) async {
        final reviewRef = _reviewsCollection.doc(reviewId);
        final reviewSnapshot = await transaction.get(reviewRef);

        if (!reviewSnapshot.exists) {
          throw 'Review not found';
        }

        final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
        final likedByUsers = List<String>.from(reviewData['likedByUsers'] ?? []);

        if (likedByUsers.contains(_currentUserId)) {
          throw 'You have already voted this review as helpful';
        }

        likedByUsers.add(_currentUserId!);
        final helpfulCount = reviewData['helpfulCount'] ?? 0;

        transaction.update(reviewRef, {
          'likedByUsers': likedByUsers,
          'helpfulCount': helpfulCount + 1,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ ReviewsService: Helpful vote added successfully');
    } catch (e) {
      print('❌ ReviewsService: Error adding helpful vote: $e');
      throw 'Failed to add helpful vote: $e';
    }
  }

  // Remove helpful vote from a review
  Future<void> removeHelpfulVote(String reviewId) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('🍽️ ReviewsService: Removing helpful vote from review: $reviewId');

      await _firestore.runTransaction((transaction) async {
        final reviewRef = _reviewsCollection.doc(reviewId);
        final reviewSnapshot = await transaction.get(reviewRef);

        if (!reviewSnapshot.exists) {
          throw 'Review not found';
        }

        final reviewData = reviewSnapshot.data() as Map<String, dynamic>;
        final likedByUsers = List<String>.from(reviewData['likedByUsers'] ?? []);

        if (!likedByUsers.contains(_currentUserId)) {
          throw 'You have not voted this review as helpful';
        }

        likedByUsers.remove(_currentUserId!);
        final helpfulCount = reviewData['helpfulCount'] ?? 0;

        transaction.update(reviewRef, {
          'likedByUsers': likedByUsers,
          'helpfulCount': math.max<int>(0, helpfulCount - 1),
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ ReviewsService: Helpful vote removed successfully');
    } catch (e) {
      print('❌ ReviewsService: Error removing helpful vote: $e');
      throw 'Failed to remove helpful vote: $e';
    }
  }

  // Get review statistics for current user
  Future<Map<String, dynamic>> getUserReviewStats() async {
    if (_currentUserId == null) {
      return {
        'totalReviews': 0,
        'publicReviews': 0,
        'friendsReviews': 0,
        'privateReviews': 0,
        'averageRating': 0.0,
        'totalHelpfulVotes': 0,
      };
    }

    try {
      print('📊 ReviewsService: Getting user review statistics');

      final snapshot = await _reviewsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final reviews = snapshot.docs
          .map((doc) => RestaurantReview.fromFirestore(doc))
          .toList();

      final publicReviews = reviews.where((r) => r.privacy == ReviewPrivacy.public).length;
      final friendsReviews = reviews.where((r) => r.privacy == ReviewPrivacy.friends).length;
      final privateReviews = reviews.where((r) => r.privacy == ReviewPrivacy.private).length;

      final totalHelpfulVotes = reviews.fold<int>(0, (sum, review) => sum + review.helpfulCount);
      
      final averageRating = reviews.isNotEmpty
          ? reviews.fold<double>(0.0, (sum, review) => sum + review.ratings.overallRating) / reviews.length
          : 0.0;

      final stats = {
        'totalReviews': reviews.length,
        'publicReviews': publicReviews,
        'friendsReviews': friendsReviews,
        'privateReviews': privateReviews,
        'averageRating': averageRating,
        'totalHelpfulVotes': totalHelpfulVotes,
      };

      print('📊 ReviewsService: User stats - Total: ${reviews.length}, Avg Rating: ${averageRating.toStringAsFixed(1)}');
      return stats;
    } catch (e) {
      print('❌ ReviewsService: Error getting user review stats: $e');
      return {
        'totalReviews': 0,
        'publicReviews': 0,
        'friendsReviews': 0,
        'privateReviews': 0,
        'averageRating': 0.0,
        'totalHelpfulVotes': 0,
      };
    }
  }

  // Check if current user has reviewed a restaurant
  Future<bool> hasUserReviewedRestaurant(String restaurantId) async {
    if (_currentUserId == null) return false;

    try {
      final snapshot = await _reviewsCollection
          .where('restaurantId', isEqualTo: restaurantId)
          .where('userId', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ ReviewsService: Error checking user review: $e');
      return false;
    }
  }

  // Helper method to apply sorting to queries
  Query _applySorting(Query query, ReviewSortType sortBy) {
    switch (sortBy) {
      case ReviewSortType.newest:
        return query.orderBy('reviewDate', descending: true);
      case ReviewSortType.oldest:
        return query.orderBy('reviewDate', descending: false);
      case ReviewSortType.highestRated:
        return query.orderBy('ratings.overallRating', descending: true);
      case ReviewSortType.lowestRated:
        return query.orderBy('ratings.overallRating', descending: false);
      case ReviewSortType.mostHelpful:
        return query.orderBy('helpfulCount', descending: true);
    }
  }

  // Generate search terms for better discoverability
  List<String> _generateSearchTerms(RestaurantReview review) {
    final terms = <String>[];
    
    // Restaurant name terms
    terms.addAll(review.restaurantName.toLowerCase().split(' '));
    
    // Dish names
    for (final dish in review.dishReviews) {
      terms.addAll(dish.dishName.toLowerCase().split(' '));
    }
    
    // Review content keywords (simple extraction)
    final reviewWords = review.writtenReview.toLowerCase().split(' ');
    terms.addAll(reviewWords.where((word) => word.length > 3).take(10));
    
    // Remove duplicates and filter out common words
    final filteredTerms = terms
        .where((term) => term.length > 2)
        .where((term) => !['the', 'and', 'was', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had', 'her', 'his', 'how', 'man', 'new', 'now', 'old', 'see', 'two', 'way', 'who', 'boy', 'did', 'has', 'let', 'put', 'say', 'she', 'too', 'use'].contains(term))
        .toSet()
        .toList();
    
    return filteredTerms.take(20).toList(); // Limit to 20 terms
  }

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      print('🔍 ReviewsService: Testing Firestore connection...');
      
      // Try to read from Firestore
      await _reviewsCollection.limit(1).get();
      print('✅ ReviewsService: Firestore connection test successful');
      
      return true;
    } catch (e) {
      print('❌ ReviewsService: Firestore connection test failed: $e');
      return false;
    }
  }
}