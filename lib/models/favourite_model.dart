import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
  }

  // Convert to Firestore document
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create copy with updated values
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
    );
  }

  // Helper getters
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateAdded);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  String get foodNamesPreview {
    if (foodNames.isEmpty) return 'No food items';
    if (foodNames.length <= 2) {
      return foodNames.join(', ');
    } else {
      return '${foodNames.take(2).join(', ')}, +${foodNames.length - 2} more';
    }
  }

  bool get hasSocialUrls => socialUrls.isNotEmpty;
}