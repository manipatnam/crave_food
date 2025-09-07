// lib/models/dish_review.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DishReview {
  final String dishName;
  final double rating; // 1-5 stars, allows decimals
  final String? quickNote; // Brief description/comment
  final double? price; // Price in local currency (optional)
  final String? photoUrl; // Dish photo URL (Phase 2 - user uploads)

  DishReview({
    required this.dishName,
    required this.rating,
    this.quickNote,
    this.price,
    this.photoUrl,
  });

  // Create from Firestore map
  factory DishReview.fromMap(Map<String, dynamic> map) {
    return DishReview(
      dishName: map['dishName'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      quickNote: map['quickNote'],
      price: (map['price'] as num?)?.toDouble(),
      photoUrl: map['photoUrl'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'dishName': dishName,
      'rating': rating,
      'quickNote': quickNote,
      'price': price,
      'photoUrl': photoUrl,
    };
  }

  // Create copy with modified fields
  DishReview copyWith({
    String? dishName,
    double? rating,
    String? quickNote,
    double? price,
    String? photoUrl,
  }) {
    return DishReview(
      dishName: dishName ?? this.dishName,
      rating: rating ?? this.rating,
      quickNote: quickNote ?? this.quickNote,
      price: price ?? this.price,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  // Validation helpers
  bool get isValid {
    return dishName.isNotEmpty && 
           rating >= 1.0 && 
           rating <= 5.0;
  }

  // Display helpers
  String get ratingDisplay {
    return rating.toStringAsFixed(1);
  }

  String get priceDisplay {
    if (price == null) return '';
    return '₹${price!.toStringAsFixed(0)}';
  }

  // For debugging
  @override
  String toString() {
    return 'DishReview(dishName: $dishName, rating: $rating, quickNote: $quickNote, price: $price)';
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DishReview &&
        other.dishName == dishName &&
        other.rating == rating &&
        other.quickNote == quickNote &&
        other.price == price &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return dishName.hashCode ^
        rating.hashCode ^
        quickNote.hashCode ^
        price.hashCode ^
        photoUrl.hashCode;
  }
}