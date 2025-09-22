// Recent Search Model
// lib/models/search/recent_search_model.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../place_model.dart';

class RecentSearch {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final DateTime searchedAt;
  final String? status; // "Open", "Closed", "Open 24 hours", etc.
  final String? photoUrl;
  final double? rating;
  final String? priceLevel;

  RecentSearch({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    required this.searchedAt,
    this.status,
    this.photoUrl,
    this.rating,
    this.priceLevel,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'searchedAt': searchedAt.toIso8601String(),
      'status': status,
      'photoUrl': photoUrl,
      'rating': rating,
      'priceLevel': priceLevel,
    };
  }

  // Create from JSON
  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      placeId: json['placeId'],
      searchedAt: DateTime.parse(json['searchedAt']),
      status: json['status'],
      photoUrl: json['photoUrl'],
      rating: json['rating'],
      priceLevel: json['priceLevel'],
    );
  }

  // Create from PlaceModel
  factory RecentSearch.fromPlace(PlaceModel place) {
    return RecentSearch(
      id: place.placeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: place.name,
      address: place.displayAddress,
      latitude: place.geoPoint.latitude,
      longitude: place.geoPoint.longitude,
      placeId: place.placeId,
      searchedAt: DateTime.now(),
      status: place.isOpen ? "Open" : "Closed",
      photoUrl: place.photoUrl,
      rating: place.rating,
      priceLevel: place.priceLevel,
    );
  }

  // Calculate distance from current location
  double? getDistanceFrom(double? currentLat, double? currentLng) {
    if (currentLat == null || currentLng == null) {
      return null;
    }
    
    // Using Haversine formula
    const double earthRadius = 6371; // km
    double latDiff = _degreesToRadians(latitude - currentLat);
    double lngDiff = _degreesToRadians(longitude - currentLng);
    
    double a = math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(_degreesToRadians(currentLat)) * math.cos(_degreesToRadians(latitude)) *
        math.sin(lngDiff / 2) * math.sin(lngDiff / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Format distance for display
  String getFormattedDistance(double? currentLat, double? currentLng) {
    final distance = getDistanceFrom(currentLat, currentLng);
    if (distance == null) return '';
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  // Convert back to PlaceModel
  PlaceModel toPlaceModel() {
    return PlaceModel(
      placeId: placeId ?? id,
      name: name,
      displayAddress: address,
      geoPoint: GeoPoint(latitude, longitude),
      rating: rating,
      priceLevel: priceLevel,
      photoUrl: photoUrl,
      isOpen: status?.toLowerCase().contains('open') ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentSearch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}