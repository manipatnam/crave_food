import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/place_model.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Get API key from environment variable
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // Search for places using text input
  Future<List<PlaceModel>> searchPlaces(String query) async {
    if (query.isEmpty) {
      print('❌ Search query is empty');
      return [];
    }

    if (!isApiKeyConfigured()) {
      print('❌ API key not configured, returning mock data for testing');
      return _getMockRestaurants(query);
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=$encodedQuery&type=restaurant&key=$_apiKey'
      );

      print('🔍 Searching for places: $query');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          final places = results
              .map((place) => PlaceModel.fromGooglePlaces(place))
              .where((place) => place.isRestaurant)
              .take(10)
              .toList();
          
          print('✅ Found ${places.length} restaurant results');
          return places;
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('ℹ️ No results found for: $query');
          return [];
        } else {
          print('❌ Google Places API error: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error details: ${data['error_message']}');
          }
          return _getMockRestaurants(query);
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return _getMockRestaurants(query);
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      return _getMockRestaurants(query);
    }
  }

  // Get autocomplete suggestions
  Future<List<PlaceModel>> getAutocompleteSuggestions(String input) async {
    if (input.isEmpty) return [];

    if (!isApiKeyConfigured()) {
      return _getMockRestaurants(input).take(3).toList();
    }

    try {
      final encodedInput = Uri.encodeComponent(input);
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?input=$encodedInput&types=establishment&key=$_apiKey'
      );

      print('🔍 Getting autocomplete suggestions for: $input');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          
          List<PlaceModel> places = [];
          for (var prediction in predictions.take(3)) {
            final placeDetails = await getPlaceDetails(prediction['place_id']);
            if (placeDetails != null && placeDetails.isRestaurant) {
              places.add(placeDetails);
            }
          }
          
          print('✅ Found ${places.length} autocomplete suggestions');
          return places;
        }
      }
      
      return _getMockRestaurants(input).take(3).toList();
    } catch (e) {
      print('❌ Error getting autocomplete suggestions: $e');
      return _getMockRestaurants(input).take(3).toList();
    }
  }

  // Get detailed information about a place
  Future<PlaceModel?> getPlaceDetails(String placeId) async {
    if (!isApiKeyConfigured()) return null;

    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&fields=place_id,name,formatted_address,geometry,photos,rating,types&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceModel.fromGooglePlaces(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting place details: $e');
      return null;
    }
  }

  // Mock restaurants for testing when API key is not configured
  List<PlaceModel> _getMockRestaurants(String query) {
    final mockRestaurants = [
      PlaceModel(
        placeId: 'mock_1',
        name: 'Pizza Palace',
        address: 'Main Street, City Center',
        latitude: 40.7128,
        longitude: -74.0060,
        rating: 4.5,
        types: ['restaurant', 'food'],
      ),
      PlaceModel(
        placeId: 'mock_2',
        name: 'Burger House',
        address: 'Second Avenue, Downtown',
        latitude: 40.7589,
        longitude: -73.9851,
        rating: 4.2,
        types: ['restaurant', 'meal_takeaway'],
      ),
      PlaceModel(
        placeId: 'mock_3',
        name: 'Sushi Bar',
        address: 'Third Street, Food District',
        latitude: 40.7505,
        longitude: -73.9934,
        rating: 4.8,
        types: ['restaurant', 'food'],
      ),
      PlaceModel(
        placeId: 'mock_4',
        name: 'Taco Corner',
        address: 'Fourth Street, Market Square',
        latitude: 40.7505,
        longitude: -73.9934,
        rating: 4.1,
        types: ['restaurant', 'meal_takeaway'],
      ),
      PlaceModel(
        placeId: 'mock_5',
        name: 'Coffee & Cafe',
        address: 'Fifth Avenue, Business District',
        latitude: 40.7505,
        longitude: -73.9934,
        rating: 4.3,
        types: ['cafe', 'food'],
      ),
    ];

    // Filter based on query
    final queryLower = query.toLowerCase();
    return mockRestaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(queryLower) ||
             restaurant.address.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Validate API key
  static bool isApiKeyConfigured() {
    final isConfigured = _apiKey.isNotEmpty && _apiKey.length > 20;
    
    if (!isConfigured) {
      print('⚠️ Google Places API key not configured');
      print('💡 Add GOOGLE_PLACES_API_KEY to your .env file');
      print('🧪 Using mock data for testing');
    } else {
      print('✅ Google Places API key configured (${_apiKey.substring(0, 8)}...)');
    }
    
    return isConfigured;
  }

  // Get masked API key for debugging
  static String get maskedApiKey {
    return _apiKey.isNotEmpty ? '${_apiKey.substring(0, 8)}...' : 'Not configured (using mock data)';
  }
}