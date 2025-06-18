import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Favourite {
  final String id;
  final String restaurantName;
  final String googlePlaceId;
  final GeoPoint coordinates;
  final List<String> foodNames;
  final List<String> socialUrls;
  final DateTime dateAdded;
  final String userId;
  final String? userNotes;
  final String? restaurantImageUrl;
  final double? rating;
  final String? priceLevel;
  final String? cuisineType;
  final String? phoneNumber;
  final String? website;
  final bool? isOpen;

  // New fields for Phase 1
  final bool isVegetarianAvailable;
  final bool isNonVegetarianAvailable;
  final TimeOfDay? userOpeningTime;
  final TimeOfDay? userClosingTime;
  final String? timingNotes;
  final List<String> tags;

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
    // New fields with defaults
    this.isVegetarianAvailable = false,
    this.isNonVegetarianAvailable = false,
    this.userOpeningTime,
    this.userClosingTime,
    this.timingNotes,
    this.tags = const [],
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
      // New fields
      isVegetarianAvailable: data['isVegetarianAvailable'] ?? false,
      isNonVegetarianAvailable: data['isNonVegetarianAvailable'] ?? false,
      userOpeningTime: _timeFromMinutes(data['userOpeningTime']),
      userClosingTime: _timeFromMinutes(data['userClosingTime']),
      timingNotes: data['timingNotes'],
      tags: List<String>.from(data['tags'] ?? []),
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
      // New fields
      'isVegetarianAvailable': isVegetarianAvailable,
      'isNonVegetarianAvailable': isNonVegetarianAvailable,
      'userOpeningTime': _timeToMinutes(userOpeningTime),
      'userClosingTime': _timeToMinutes(userClosingTime),
      'timingNotes': timingNotes,
      'tags': tags,
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

  // New helper methods for dietary options
  String get dietaryOptionsDisplay {
    if (isVegetarianAvailable && isNonVegetarianAvailable) {
      return '🥬🍖 Veg & Non-Veg';
    } else if (isVegetarianAvailable) {
      return '🥬 Vegetarian';
    } else if (isNonVegetarianAvailable) {
      return '🍖 Non-Vegetarian';
    }
    return '';
  }

  // Get user timing display
  String get userTimingDisplay {
    if (userOpeningTime == null || userClosingTime == null) return '';
    
    final formatter = DateFormat('h:mm a');
    final opening = DateTime(2000, 1, 1, userOpeningTime!.hour, userOpeningTime!.minute);
    final closing = DateTime(2000, 1, 1, userClosingTime!.hour, userClosingTime!.minute);
    
    return '${formatter.format(opening)} - ${formatter.format(closing)}';
  }

  // Check if currently in user's preferred timing
  bool get isInUserTiming {
    if (userOpeningTime == null || userClosingTime == null) return false;
    
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = userOpeningTime!.hour * 60 + userOpeningTime!.minute;
    final closeMinutes = userClosingTime!.hour * 60 + userClosingTime!.minute;
    
    if (closeMinutes > openMinutes) {
      // Same day (e.g., 9 AM - 10 PM)
      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } else {
      // Crosses midnight (e.g., 10 PM - 2 AM)
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }
  }

  // Get tags display (first 3 tags)
  String get tagsPreview {
    if (tags.isEmpty) return '';
    if (tags.length <= 3) {
      return tags.join(' • ');
    }
    return '${tags.take(3).join(' • ')} +${tags.length - 3}';
  }
}