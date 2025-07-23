// Updated Favourite Model with Place Categories
// lib/models/favourite_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'visit_status.dart';


class Favourite {
  final String id;
  final String restaurantName; // Keep this name for compatibility, but it now represents any place
  final String googlePlaceId;
  final GeoPoint coordinates;
  final List<String> foodNames; // Will be empty for non-food places
  final List<String> socialUrls;
  final DateTime dateAdded;
  final String userId;
  final String? userNotes;
  final String? restaurantImageUrl; // Keep name for compatibility
  final double? rating;
  final String? priceLevel;
  final String? cuisineType;
  final String? phoneNumber;
  final String? website;
  final bool? isOpen;

  // Existing fields
  final bool isVegetarianAvailable;
  final bool isNonVegetarianAvailable;
  final TimeOfDay? userOpeningTime;
  final TimeOfDay? userClosingTime;
  final String? timingNotes;
  final List<String> tags;

  // NEW FIELDS for place categories
  final String? placeCategory; // 'Food & Dining', 'Activities', etc.
  final String? foodPlaceType; // 'Restaurant', 'Cafe', etc. (only for food places)

  final VisitStatus visitStatus;

  Favourite({
    required this.id,
    required this.restaurantName,
    required this.googlePlaceId,
    required this.coordinates,
    required this.foodNames,
    required this.socialUrls,
    required this.dateAdded,
    required this.userId,
    this.userNotes,
    this.restaurantImageUrl,
    this.rating,
    this.priceLevel,
    this.cuisineType,
    this.phoneNumber,
    this.website,
    this.isOpen,
    // Existing fields with defaults
    this.isVegetarianAvailable = false,
    this.isNonVegetarianAvailable = false,
    this.userOpeningTime,
    this.userClosingTime,
    this.timingNotes,
    this.tags = const [],
    // New fields
    this.placeCategory,
    this.foodPlaceType,

    this.visitStatus = VisitStatus.notVisited,
  });

  // Create from Firestore document
  factory Favourite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Favourite(
      id: doc.id,
      restaurantName: data['restaurantName'] ?? '',
      googlePlaceId: data['googlePlaceId'] ?? '',
      coordinates: data['coordinates'] ?? const GeoPoint(0, 0),
      foodNames: List<String>.from(data['foodNames'] ?? []),
      socialUrls: List<String>.from(data['socialUrls'] ?? []),
      dateAdded: (data['dateAdded'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      userNotes: data['userNotes'],
      restaurantImageUrl: data['restaurantImageUrl'],
      rating: data['rating']?.toDouble(),
      priceLevel: data['priceLevel'],
      cuisineType: data['cuisineType'],
      phoneNumber: data['phoneNumber'],
      website: data['website'],
      isOpen: data['isOpen'],
      // Existing fields
      isVegetarianAvailable: data['isVegetarianAvailable'] ?? false,
      isNonVegetarianAvailable: data['isNonVegetarianAvailable'] ?? false,
      userOpeningTime: _timeFromMinutes(data['userOpeningTime']),
      userClosingTime: _timeFromMinutes(data['userClosingTime']),
      timingNotes: data['timingNotes'],
      tags: List<String>.from(data['tags'] ?? []),
      // New fields
      placeCategory: data['placeCategory'],
      foodPlaceType: data['foodPlaceType'],

      visitStatus: VisitStatus.fromString(data['visitStatus']),
    );
  }

  // Convert TimeOfDay from minutes since midnight
  static TimeOfDay? _timeFromMinutes(int? minutes) {
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  // Convert TimeOfDay to minutes since midnight
  static int? _timeToMinutes(TimeOfDay? time) {
    if (time == null) return null;
    return time.hour * 60 + time.minute;
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantName': restaurantName,
      'googlePlaceId': googlePlaceId,
      'coordinates': coordinates,
      'foodNames': foodNames,
      'socialUrls': socialUrls,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'userId': userId,
      'userNotes': userNotes,
      'restaurantImageUrl': restaurantImageUrl,
      'rating': rating,
      'priceLevel': priceLevel,
      'cuisineType': cuisineType,
      'phoneNumber': phoneNumber,
      'website': website,
      'isOpen': isOpen,
      // Existing fields
      'isVegetarianAvailable': isVegetarianAvailable,
      'isNonVegetarianAvailable': isNonVegetarianAvailable,
      'userOpeningTime': _timeToMinutes(userOpeningTime),
      'userClosingTime': _timeToMinutes(userClosingTime),
      'timingNotes': timingNotes,
      'tags': tags,
      // New fields
      'placeCategory': placeCategory,
      'foodPlaceType': foodPlaceType,
      // NEW: Visit status
      'visitStatus': visitStatus.toFirestoreValue(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updating
  Favourite copyWith({
    String? id,
    String? restaurantName,
    String? googlePlaceId,
    GeoPoint? coordinates,
    List<String>? foodNames,
    List<String>? socialUrls,
    DateTime? dateAdded,
    String? userId,
    String? userNotes,
    String? restaurantImageUrl,
    double? rating,
    String? priceLevel,
    String? cuisineType,
    String? phoneNumber,
    String? website,
    bool? isOpen,
    bool? isVegetarianAvailable,
    bool? isNonVegetarianAvailable,
    TimeOfDay? userOpeningTime,
    TimeOfDay? userClosingTime,
    String? timingNotes,
    List<String>? tags,
    String? placeCategory,
    String? foodPlaceType,
    VisitStatus? visitStatus, //NEW
  }) {
    return Favourite(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      coordinates: coordinates ?? this.coordinates,
      foodNames: foodNames ?? this.foodNames,
      socialUrls: socialUrls ?? this.socialUrls,
      dateAdded: dateAdded ?? this.dateAdded,
      userId: userId ?? this.userId,
      userNotes: userNotes ?? this.userNotes,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      rating: rating ?? this.rating,
      priceLevel: priceLevel ?? this.priceLevel,
      cuisineType: cuisineType ?? this.cuisineType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      isOpen: isOpen ?? this.isOpen,
      isVegetarianAvailable: isVegetarianAvailable ?? this.isVegetarianAvailable,
      isNonVegetarianAvailable: isNonVegetarianAvailable ?? this.isNonVegetarianAvailable,
      userOpeningTime: userOpeningTime ?? this.userOpeningTime,
      userClosingTime: userClosingTime ?? this.userClosingTime,
      timingNotes: timingNotes ?? this.timingNotes,
      tags: tags ?? this.tags,
      placeCategory: placeCategory ?? this.placeCategory,
      foodPlaceType: foodPlaceType ?? this.foodPlaceType,
      visitStatus: visitStatus ?? this.visitStatus, //NEW
    );
  }

  // Formatted date string
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(dateAdded);
  }

  // Food names preview (first 3 items)
  String get foodNamesPreview {
    if (foodNames.isEmpty) return 'No food items';
    if (foodNames.length <= 3) {
      return foodNames.join(', ');
    }
    return '${foodNames.take(3).join(', ')} +${foodNames.length - 3} more';
  }

  // Check if has social URLs
  bool get hasSocialUrls => socialUrls.isNotEmpty;

  // Get rating display with stars
  String get ratingDisplay {
    if (rating == null) return '';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  // Get price level display
  String get priceLevelDisplay {
    if (priceLevel == null || priceLevel!.isEmpty) return '';
    return priceLevel!;
  }

  // Get status indicator
  String get statusIndicator {
    if (isOpen == null) return '';
    return isOpen! ? '🟢 Open' : '🔴 Closed';
  }

  // Get cuisine type display
  String get cuisineTypeDisplay {
    if (cuisineType == null || cuisineType!.isEmpty) return '';
    return cuisineType!;
  }

  // NEW HELPER METHODS for place categories

  // Check if this is a food-related place
  bool get isFoodPlace {
    return placeCategory == 'Food & Dining';
  }

  // Get place category icon
  IconData get placeCategoryIcon {
    switch (placeCategory) {
      case 'Food & Dining':
        return Icons.restaurant_menu_rounded;
      case 'Activities':
        return Icons.local_activity_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Accommodation':
        return Icons.hotel_rounded;
      case 'Entertainment':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  // Get place category color
  Color get placeCategoryColor {
    switch (placeCategory) {
      case 'Food & Dining':
        return const Color(0xFFFF6B35);
      case 'Activities':
        return const Color(0xFF2196F3);
      case 'Shopping':
        return const Color(0xFF4CAF50);
      case 'Accommodation':
        return const Color(0xFF9C27B0);
      case 'Entertainment':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF607D8B);
    }
  }

  // Get food place type emoji
  String get foodPlaceTypeEmoji {
    switch (foodPlaceType) {
      case 'Restaurant':
        return '🍽️';
      case 'Cafe':
        return '☕';
      case 'Pub/Bar':
        return '🍺';
      case 'Fast Food':
        return '🍕';
      case 'Dessert/Sweets':
        return '🍦';
      case 'Street Food':
        return '🥘';
      case 'Specialty':
        return '🍱';
      default:
        return '❓';
    }
  }

  // Get place name (backward compatibility)
  String get placeName => restaurantName;

  // Get place image URL (backward compatibility)
  String? get placeImageUrl => restaurantImageUrl;

  // NEW HELPER METHODS for missing getters

  // Get dietary options display
  String get dietaryOptionsDisplay {
    final options = <String>[];
    if (isVegetarianAvailable) options.add('Vegetarian');
    if (isNonVegetarianAvailable) options.add('Non-Vegetarian');
    return options.join(', ');
  }

  // Get user timing display
  String get userTimingDisplay {
    if (userOpeningTime == null && userClosingTime == null) return '';
    
    final opening = userOpeningTime != null ? _formatTimeOfDay(userOpeningTime!) : 'Unknown';
    final closing = userClosingTime != null ? _formatTimeOfDay(userClosingTime!) : 'Unknown';
    
    return '$opening - $closing';
  }

  // Helper method to format TimeOfDay
  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}