import 'package:cloud_firestore/cloud_firestore.dart';
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
    );
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
}