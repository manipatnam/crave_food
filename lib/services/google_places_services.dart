import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/place_model.dart';

class GooglePlacesService {
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static String get _mapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Search for places with photos
  Future<List<PlaceModel>> searchPlaces(String query) async {
    try {
      final String url = '$_baseUrl/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&type=restaurant'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          
          // Convert to PlaceModel objects with enhanced data
          List<PlaceModel> places = [];
          
          for (var result in results.take(10)) { // Limit to 10 results
            try {
              var place = PlaceModel.fromGooglePlaces(result);
              
              // Get additional details if photo reference exists
              if (place.photoReference != null) {
                place = place.copyWith(
                  photoUrl: place.getPhotoUrl(_apiKey, maxWidth: 400),
                );
              }
              
              places.add(place);
            } catch (e) {
              print('Error parsing place: $e');
              // Continue with other places even if one fails
            }
          }
          
          return places;
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  // Get detailed place information
  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    try {
      final String url = '$_baseUrl/details/json'
          '?place_id=$placeId'
          '&fields=place_id,name,formatted_address,geometry,rating,user_ratings_total,price_level,types,photos,opening_hours,formatted_phone_number,website'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          var place = PlaceModel.fromGooglePlaces(result);
          
          // Add photo URL if available
          if (place.photoReference != null) {
            place = place.copyWith(
              photoUrl: place.getPhotoUrl(_apiKey, maxWidth: 600),
            );
          }
          
          return place;
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  // Get nearby restaurants with photos
  Future<List<PlaceModel>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      final String url = '$_baseUrl/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&radius=$radius'
          '&type=restaurant'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          
          List<PlaceModel> places = [];
          
          for (var result in results.take(20)) {
            try {
              var place = PlaceModel.fromGooglePlaces(result);
              
              if (place.photoReference != null) {
                place = place.copyWith(
                  photoUrl: place.getPhotoUrl(_apiKey, maxWidth: 400),
                );
              }
              
              places.add(place);
            } catch (e) {
              print('Error parsing nearby place: $e');
            }
          }
          
          // Sort by rating (highest first)
          places.sort((a, b) {
            if (a.rating == null && b.rating == null) return 0;
            if (a.rating == null) return 1;
            if (b.rating == null) return -1;
            return b.rating!.compareTo(a.rating!);
          });
          
          return places;
        }
      }
      return [];
    } catch (e) {
      print('Error getting nearby restaurants: $e');
      return [];
    }
  }

  // Get photo URL for a photo reference
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }
}

// Extension to add copyWith method to PlaceModel
extension PlaceModelExtension on PlaceModel {
  PlaceModel copyWith({
    String? placeId,
    String? name,
    String? displayAddress,
    double? rating,
    int? userRatingsTotal,
    String? priceLevel,
    List<String>? types,
    GeoPoint? geoPoint,
    String? photoReference,
    String? photoUrl,
    bool? isOpen,
    String? phoneNumber,
    String? website,
  }) {
    return PlaceModel(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      displayAddress: displayAddress ?? this.displayAddress,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      priceLevel: priceLevel ?? this.priceLevel,
      types: types ?? this.types,
      geoPoint: geoPoint ?? this.geoPoint,
      photoReference: photoReference ?? this.photoReference,
      photoUrl: photoUrl ?? this.photoUrl,
      isOpen: isOpen ?? this.isOpen,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
    );
  }
}