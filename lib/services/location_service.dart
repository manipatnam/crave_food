// FILE: lib/services/location_service.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static const LatLng _defaultLocation = LatLng(17.3850, 78.4867); // Hyderabad, India

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

  // Get current location
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

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
      
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Get default location (Hyderabad)
  static LatLng getDefaultLocation() {
    print('📍 Using default location: Hyderabad');
    return _defaultLocation;
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
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Check if location is valid
  static bool isValidLocation(LatLng location) {
    return location.latitude.abs() <= 90 && location.longitude.abs() <= 180;
  }

  // Get location with fallback
  static Future<LatLng> getLocationWithFallback() async {
    try {
      // Try to get current location
      final currentLocation = await getCurrentLocation();
      if (currentLocation != null && isValidLocation(currentLocation)) {
        return currentLocation;
      }
    } catch (e) {
      print('❌ Failed to get current location: $e');
    }

    // Fallback to default location
    return getDefaultLocation();
  }

  // Start location streaming (for real-time updates)
  static Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  // Check if user is near a location (within radius)
  static bool isNearLocation(LatLng userLocation, LatLng targetLocation, double radiusInMeters) {
    final distance = calculateDistance(userLocation, targetLocation);
    return distance <= radiusInMeters;
  }
}