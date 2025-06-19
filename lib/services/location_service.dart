// FILE: lib/services/location_service.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  // Major Indian cities as fallback options based on IP geolocation
  static const Map<String, LatLng> _majorCities = {
    'mumbai': LatLng(19.0760, 72.8777),
    'delhi': LatLng(28.7041, 77.1025),
    'bangalore': LatLng(12.9716, 77.5946),
    'hyderabad': LatLng(17.3850, 78.4867),
    'chennai': LatLng(13.0827, 80.2707),
    'kolkata': LatLng(22.5726, 88.3639),
    'pune': LatLng(18.5204, 73.8567),
    'ahmedabad': LatLng(23.0225, 72.5714),
    'jaipur': LatLng(26.9124, 75.7873),
    'surat': LatLng(21.1702, 72.8311),
    'lucknow': LatLng(26.8467, 80.9462),
    'kanpur': LatLng(26.4499, 80.3319),
    'nagpur': LatLng(21.1458, 79.0882),
    'visakhapatnam': LatLng(17.6868, 83.2185),
    'indore': LatLng(22.7196, 75.8577),
    'thane': LatLng(19.2183, 72.9781),
    'bhopal': LatLng(23.2599, 77.4126),
    'vijaywada': LatLng(16.5062, 80.6480),
    'patna': LatLng(25.5941, 85.1376),
    'vadodara': LatLng(22.3072, 73.1812),
  };

  // India's geographic center as ultimate fallback
  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  // Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request location permissions
  static Future<bool> requestLocationPermission() async {
    print('📍 Requesting location permission...');
    
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      print('✅ Location permission granted');
      return true;
    } else if (status.isDenied) {
      print('❌ Location permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('🚫 Location permission permanently denied');
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  // Get current location with improved fallback strategy
  static Future<LatLng?> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('🚫 Location permissions are permanently denied');
        return null;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
      
    } catch (e) {
      print('❌ Error getting GPS location: $e');
      return null;
    }
  }

  // Get location using IP geolocation as fallback
  static Future<LatLng?> getLocationFromIP() async {
    try {
      print('🌐 Attempting IP-based location detection...');
      
      // Try multiple IP geolocation services
      final services = [
        'http://ip-api.com/json',
        'https://ipapi.co/json',
        'https://ipinfo.io/json',
      ];

      for (String service in services) {
        try {
          final response = await http.get(
            Uri.parse(service),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            double? lat, lng;
            String? city, region;

            // Parse different API response formats
            if (service.contains('ip-api.com')) {
              lat = data['lat']?.toDouble();
              lng = data['lon']?.toDouble();
              city = data['city']?.toString().toLowerCase();
              region = data['regionName']?.toString().toLowerCase();
            } else if (service.contains('ipapi.co')) {
              lat = double.tryParse(data['latitude']?.toString() ?? '');
              lng = double.tryParse(data['longitude']?.toString() ?? '');
              city = data['city']?.toString().toLowerCase();
              region = data['region']?.toString().toLowerCase();
            } else if (service.contains('ipinfo.io')) {
              final loc = data['loc']?.toString().split(',');
              if (loc != null && loc.length == 2) {
                lat = double.tryParse(loc[0]);
                lng = double.tryParse(loc[1]);
              }
              city = data['city']?.toString().toLowerCase();
              region = data['region']?.toString().toLowerCase();
            }

            if (lat != null && lng != null) {
              print('✅ IP location found: $lat, $lng (City: $city, Region: $region)');
              
              // Validate if coordinates are within India (roughly)
              if (_isLocationInIndia(lat, lng)) {
                return LatLng(lat, lng);
              } else {
                print('⚠️ IP location outside India, trying city-based fallback...');
                // Try to match city to known Indian cities
                if (city != null) {
                  final cityLocation = _getCityLocation(city);
                  if (cityLocation != null) {
                    print('✅ Found city match: $city');
                    return cityLocation;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('❌ Failed to get location from $service: $e');
          continue;
        }
      }
      
      print('❌ All IP geolocation services failed');
      return null;
    } catch (e) {
      print('❌ Error in IP geolocation: $e');
      return null;
    }
  }

  // Check if coordinates are roughly within India
  static bool _isLocationInIndia(double lat, double lng) {
    // India's approximate bounding box
    return lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.0;
  }

  // Get location for a known city
  static LatLng? _getCityLocation(String cityName) {
    final city = cityName.toLowerCase().trim();
    
    // Direct match
    if (_majorCities.containsKey(city)) {
      return _majorCities[city];
    }
    
    // Partial match
    for (String knownCity in _majorCities.keys) {
      if (knownCity.contains(city) || city.contains(knownCity)) {
        return _majorCities[knownCity];
      }
    }
    
    return null;
  }

  // Main method to get location with comprehensive fallback strategy
  static Future<LatLng> getLocationWithFallback() async {
    print('🎯 Starting location detection with fallback strategy...');
    
    // Step 1: Try GPS location
    final gpsLocation = await getCurrentLocation();
    if (gpsLocation != null) {
      print('✅ Using GPS location');
      return gpsLocation;
    }
    
    // Step 2: Try IP-based location
    final ipLocation = await getLocationFromIP();
    if (ipLocation != null) {
      print('✅ Using IP-based location');
      return ipLocation;
    }
    
    // Step 3: Ultimate fallback to India's center
    print('⚠️ Using India geographic center as final fallback');
    return _indiaCenter;
  }

  // Show location permission dialog
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.red),
              SizedBox(width: 8),
              Text('Location Access'),
            ],
          ),
          content: const Text(
            'We need your location to show nearby restaurants. Without location access, we\'ll show restaurants from a default area which might not be relevant to you.\n\nWould you like to enable location access?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable Location'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show location services disabled dialog
  static Future<void> showLocationServicesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Services Disabled'),
            ],
          ),
          content: const Text(
            'Location services are turned off on your device. Please enable them in your device settings to get accurate restaurant suggestions based on your location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Get user-friendly location name
  static String getLocationDisplayName(LatLng location) {
    // Find the closest major city
    String closestCity = 'Unknown Location';
    double minDistance = double.infinity;
    
    for (String cityName in _majorCities.keys) {
      final cityLocation = _majorCities[cityName]!;
      final distance = calculateDistance(location, cityLocation);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = cityName.toUpperCase();
      }
    }
    
    // If very close to a known city, show the city name
    if (minDistance < 50000) { // Within 50km
      return 'Near $closestCity';
    } else {
      return 'India';
    }
  }
}