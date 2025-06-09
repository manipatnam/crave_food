import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? photoReference;
  final double? rating;
  final List<String> types;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoReference,
    this.rating,
    this.types = const [],
  });

  // Create from Google Places API response
  factory PlaceModel.fromGooglePlaces(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry['location'];
    
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      photoReference: json['photos']?.isNotEmpty == true 
          ? json['photos'][0]['photo_reference'] 
          : null,
      rating: json['rating']?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
    );
  }

  // Convert to GeoPoint for Firestore
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  // Check if place is a restaurant/food place
  bool get isRestaurant {
    const restaurantTypes = [
      'restaurant',
      'food',
      'meal_takeaway',
      'meal_delivery',
      'cafe',
      'bakery',
      'bar',
    ];
    return types.any((type) => restaurantTypes.contains(type));
  }

  // Get a clean display address (remove country if too long)
  String get displayAddress {
    if (address.length <= 50) return address;
    
    final parts = address.split(', ');
    if (parts.length > 2) {
      // Remove the last part (usually country) if address is long
      return parts.take(parts.length - 1).join(', ');
    }
    return address;
  }
}