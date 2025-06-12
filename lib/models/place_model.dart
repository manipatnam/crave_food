import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String placeId;
  final String name;
  final String displayAddress;
  final double? rating;
  final int? userRatingsTotal;
  final String? priceLevel;
  final List<String> types;
  final GeoPoint geoPoint;
  final String? photoReference;
  final String? photoUrl;
  final bool isOpen;
  final String? phoneNumber;
  final String? website;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.displayAddress,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.types = const [],
    required this.geoPoint,
    this.photoReference,
    this.photoUrl,
    this.isOpen = false,
    this.phoneNumber,
    this.website,
  });

  factory PlaceModel.fromGooglePlaces(Map<String, dynamic> json) {
    // Extract photo reference for getting images
    String? photoReference;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoReference = json['photos'][0]['photo_reference'];
    }

    // Extract location
    final location = json['geometry']['location'];
    final geoPoint = GeoPoint(
      location['lat'].toDouble(),
      location['lng'].toDouble(),
    );

    // Extract types and clean them up
    final types = (json['types'] as List<dynamic>?)
        ?.map((type) => type.toString())
        .where((type) => !['establishment', 'point_of_interest'].contains(type))
        .take(3)
        .toList() ?? [];

    // Format price level
    String? priceLevel;
    if (json['price_level'] != null) {
      final level = json['price_level'] as int;
      priceLevel = '\$' * level;
    }

    return PlaceModel(
      placeId: json['place_id'],
      name: json['name'],
      displayAddress: json['formatted_address'] ?? json['vicinity'] ?? '',
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      priceLevel: priceLevel,
      types: types,
      geoPoint: geoPoint,
      photoReference: photoReference,
      isOpen: json['opening_hours']?['open_now'] ?? false,
      phoneNumber: json['formatted_phone_number'],
      website: json['website'],
    );
  }

  // Generate photo URL from photo reference
  String? getPhotoUrl(String apiKey, {int maxWidth = 400}) {
    if (photoReference == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$apiKey';
  }

  // Get cuisine types as a readable string
  String get cuisineTypes {
    if (types.isEmpty) return '';
    return types
        .map((type) => type.replaceAll('_', ' ').split(' ').map((word) => 
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' '))
        .join(' • ');
  }

  // Get price level display
  String get priceLevelDisplay {
    if (priceLevel == null) return '';
    return priceLevel!;
  }

  // Get rating display with stars
  String get ratingDisplay {
    if (rating == null) return '';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'displayAddress': displayAddress,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel,
      'types': types,
      'latitude': geoPoint.latitude,
      'longitude': geoPoint.longitude,
      'photoReference': photoReference,
      'photoUrl': photoUrl,
      'isOpen': isOpen,
      'phoneNumber': phoneNumber,
      'website': website,
    };
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['placeId'],
      name: json['name'],
      displayAddress: json['displayAddress'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['userRatingsTotal'],
      priceLevel: json['priceLevel'],
      types: List<String>.from(json['types'] ?? []),
      geoPoint: GeoPoint(json['latitude'], json['longitude']),
      photoReference: json['photoReference'],
      photoUrl: json['photoUrl'],
      isOpen: json['isOpen'] ?? false,
      phoneNumber: json['phoneNumber'],
      website: json['website'],
    );
  }
}