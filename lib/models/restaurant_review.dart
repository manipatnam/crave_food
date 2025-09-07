// lib/models/restaurant_review.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dish_review.dart';
import 'review_enums.dart';

class RestaurantReview {
  final String id;
  final String restaurantId; // Google Place ID
  final String userId;

  // Restaurant info (denormalized for query efficiency)
  final String restaurantName;
  final String restaurantAddress;
  final GeoPoint restaurantCoordinates;

  // User info (denormalized)
  final String userName;
  final String? userDisplayName;

  // Multi-dimensional ratings (1-5 scale, allows decimals)
  final ReviewRatings ratings;

  // Dish-level reviews
  final List<DishReview> dishReviews;

  // Content
  final String writtenReview;
  final List<String> photoUrls; // User uploaded photos (Phase 2)

  // Visit context
  final DateTime visitDate;
  final VisitType visitType;
  final MealTime mealTime;
  final Occasion occasion;

  // Privacy & Social (ready for Phase 2)
  final ReviewPrivacy privacy;
  final List<String> visibleTo; // For granular permissions if needed

  // Engagement
  final int helpfulCount;
  final List<String> likedByUsers;
  final List<String> reportedByUsers; // For moderation

  // Metadata
  final DateTime reviewDate;
  final DateTime lastUpdated;

  // Search optimization
  final List<String> searchTerms;

  RestaurantReview({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantCoordinates,
    required this.userName,
    this.userDisplayName,
    required this.ratings,
    required this.dishReviews,
    required this.writtenReview,
    this.photoUrls = const [],
    required this.visitDate,
    required this.visitType,
    required this.mealTime,
    required this.occasion,
    this.privacy = ReviewPrivacy.public,
    this.visibleTo = const [],
    this.helpfulCount = 0,
    this.likedByUsers = const [],
    this.reportedByUsers = const [],
    required this.reviewDate,
    required this.lastUpdated,
    this.searchTerms = const [],
  });

  // Create from Firestore document
  factory RestaurantReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RestaurantReview(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantAddress: data['restaurantAddress'] ?? '',
      restaurantCoordinates: data['restaurantCoordinates'] ?? const GeoPoint(0, 0),
      userName: data['userName'] ?? '',
      userDisplayName: data['userDisplayName'],
      ratings: ReviewRatings.fromMap(data['ratings'] ?? {}),
      dishReviews: (data['dishReviews'] as List<dynamic>?)
              ?.map((dishData) => DishReview.fromMap(dishData as Map<String, dynamic>))
              .toList() ??
          [],
      writtenReview: data['writtenReview'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      visitDate: (data['visitDate'] as Timestamp).toDate(),
      visitType: ReviewEnumUtils.visitTypeFromString(data['visitType']) ?? VisitType.casual,
      mealTime: ReviewEnumUtils.mealTimeFromString(data['mealTime']) ?? MealTime.dinner,
      occasion: ReviewEnumUtils.occasionFromString(data['occasion']) ?? Occasion.casual,
      privacy: ReviewEnumUtils.reviewPrivacyFromString(data['privacy']) ?? ReviewPrivacy.public,
      visibleTo: List<String>.from(data['visibleTo'] ?? []),
      helpfulCount: data['helpfulCount'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
      reportedByUsers: List<String>.from(data['reportedByUsers'] ?? []),
      reviewDate: (data['reviewDate'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      searchTerms: List<String>.from(data['searchTerms'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantCoordinates': restaurantCoordinates,
      'userName': userName,
      'userDisplayName': userDisplayName,
      'ratings': ratings.toMap(),
      'dishReviews': dishReviews.map((dish) => dish.toMap()).toList(),
      'writtenReview': writtenReview,
      'photoUrls': photoUrls,
      'visitDate': Timestamp.fromDate(visitDate),
      'visitType': ReviewEnumUtils.enumToString(visitType),
      'mealTime': ReviewEnumUtils.enumToString(mealTime),
      'occasion': ReviewEnumUtils.enumToString(occasion),
      'privacy': ReviewEnumUtils.enumToString(privacy),
      'visibleTo': visibleTo,
      'helpfulCount': helpfulCount,
      'likedByUsers': likedByUsers,
      'reportedByUsers': reportedByUsers,
      'reviewDate': Timestamp.fromDate(reviewDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'searchTerms': searchTerms,
    };
  }

  // Create copy with modified fields
  RestaurantReview copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    String? restaurantName,
    String? restaurantAddress,
    GeoPoint? restaurantCoordinates,
    String? userName,
    String? userDisplayName,
    ReviewRatings? ratings,
    List<DishReview>? dishReviews,
    String? writtenReview,
    List<String>? photoUrls,
    DateTime? visitDate,
    VisitType? visitType,
    MealTime? mealTime,
    Occasion? occasion,
    ReviewPrivacy? privacy,
    List<String>? visibleTo,
    int? helpfulCount,
    List<String>? likedByUsers,
    List<String>? reportedByUsers,
    DateTime? reviewDate,
    DateTime? lastUpdated,
    List<String>? searchTerms,
  }) {
    return RestaurantReview(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantCoordinates: restaurantCoordinates ?? this.restaurantCoordinates,
      userName: userName ?? this.userName,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      ratings: ratings ?? this.ratings,
      dishReviews: dishReviews ?? this.dishReviews,
      writtenReview: writtenReview ?? this.writtenReview,
      photoUrls: photoUrls ?? this.photoUrls,
      visitDate: visitDate ?? this.visitDate,
      visitType: visitType ?? this.visitType,
      mealTime: mealTime ?? this.mealTime,
      occasion: occasion ?? this.occasion,
      privacy: privacy ?? this.privacy,
      visibleTo: visibleTo ?? this.visibleTo,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      reportedByUsers: reportedByUsers ?? this.reportedByUsers,
      reviewDate: reviewDate ?? this.reviewDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchTerms: searchTerms ?? this.searchTerms,
    );
  }

  // Validation helpers
  bool get isValid {
    return restaurantId.isNotEmpty &&
        userId.isNotEmpty &&
        restaurantName.isNotEmpty &&
        ratings.isValid &&
        writtenReview.isNotEmpty;
  }

  // Display helpers
  String get visitContextDisplay {
    return '${visitType.displayName} • ${mealTime.displayName} • ${occasion.displayName}';
  }

  String get ratingDisplay {
    return ratings.overallRating.toStringAsFixed(1);
  }

  // For debugging
  @override
  String toString() {
    return 'RestaurantReview(id: $id, restaurantName: $restaurantName, userName: $userName, overallRating: ${ratings.overallRating})';
  }
}

// Separate class for ratings to keep things organized
class ReviewRatings {
  final double foodRating;
  final double serviceRating;
  final double ambienceRating;
  final double valueRating;
  final double overallRating; // calculated or manual

  ReviewRatings({
    required this.foodRating,
    required this.serviceRating,
    required this.ambienceRating,
    required this.valueRating,
    required this.overallRating,
  });

  factory ReviewRatings.fromMap(Map<String, dynamic> map) {
    return ReviewRatings(
      foodRating: (map['foodRating'] as num?)?.toDouble() ?? 0.0,
      serviceRating: (map['serviceRating'] as num?)?.toDouble() ?? 0.0,
      ambienceRating: (map['ambienceRating'] as num?)?.toDouble() ?? 0.0,
      valueRating: (map['valueRating'] as num?)?.toDouble() ?? 0.0,
      overallRating: (map['overallRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodRating': foodRating,
      'serviceRating': serviceRating,
      'ambienceRating': ambienceRating,
      'valueRating': valueRating,
      'overallRating': overallRating,
    };
  }

  // Calculate overall rating from individual ratings
  double get calculatedOverallRating {
    return (foodRating + serviceRating + ambienceRating + valueRating) / 4.0;
  }

  // Validation
  bool get isValid {
    return foodRating >= 1.0 && foodRating <= 5.0 &&
        serviceRating >= 1.0 && serviceRating <= 5.0 &&
        ambienceRating >= 1.0 && ambienceRating <= 5.0 &&
        valueRating >= 1.0 && valueRating <= 5.0 &&
        overallRating >= 1.0 && overallRating <= 5.0;
  }

  ReviewRatings copyWith({
    double? foodRating,
    double? serviceRating,
    double? ambienceRating,
    double? valueRating,
    double? overallRating,
  }) {
    return ReviewRatings(
      foodRating: foodRating ?? this.foodRating,
      serviceRating: serviceRating ?? this.serviceRating,
      ambienceRating: ambienceRating ?? this.ambienceRating,
      valueRating: valueRating ?? this.valueRating,
      overallRating: overallRating ?? this.overallRating,
    );
  }
}