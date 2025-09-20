// OPTIMIZED lib/services/location_service.dart
// Performance Fix - Problem #1: Smart Location Caching with Hyderabad Fallback

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Default location: Hyderabad (your city)
  static const LatLng _defaultLocation = LatLng(17.3850, 78.4867);
  static const String _defaultLocationName = 'Hyderabad';
  
  // Cache keys for SharedPreferences
  static const String _cacheKeyLat = 'cached_user_lat';
  static const String _cacheKeyLng = 'cached_user_lng';
  static const String _cacheKeyName = 'cached_location_name';
  static const String _cacheKeyTimestamp = 'cached_location_timestamp';
  
  // Cache validity (24 hours)
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // OPTIMIZED: Get initial location (first time = Hyderabad, then cached/current)
  static Future<LatLng> getInitialLocation() async {
    try {
      // Step 1: Check for cached user location
      final cachedLocation = await _getCachedLocation();
      if (cachedLocation != null) {
        print('✅ Using cached user location: ${cachedLocation.latitude}, ${cachedLocation.longitude}');
        return cachedLocation;
      }
      
      // Step 2: No cache found, default to Hyderabad
      print('📍 First time user - defaulting to Hyderabad');
      return _defaultLocation;
      
    } catch (e) {
      print('❌ Error getting initial location: $e');
      return _defaultLocation;
    }
  }

  // OPTIMIZED: Get current GPS location (only when user requests it)
  static Future<LatLng?> getCurrentLocationWithPermission(BuildContext context) async {
    try {
      print('📍 User requested current location...');
      
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServicesDialog(context);
        return null;
      }

      // Step 2: Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Show dialog explaining why we need permission
        bool shouldRequest = await _showLocationPermissionDialog(context);
        if (!shouldRequest) return null;
        
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationPermanentlyDeniedDialog(context);
        return null;
      }

      // Step 3: Get GPS location with optimized settings
      print('🛰️ Getting GPS location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // OPTIMIZED: medium instead of high
        timeLimit: const Duration(seconds: 10),   // OPTIMIZED: 10s instead of 15s
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      
      // Step 4: Cache the location for next time
      await _cacheLocation(userLocation, 'Current Location');
      
      print('✅ GPS location obtained and cached: ${position.latitude}, ${position.longitude}');
      return userLocation;
      
    } catch (e) {
      print('❌ Error getting GPS location: $e');
      return null;
    }
  }

  // OPTIMIZED: Check if user has cached location (not first time)
  static Future<bool> hasUserLocation() async {
    final cachedLocation = await _getCachedLocation();
    return cachedLocation != null;
  }

  // OPTIMIZED: Get cached location if valid
  static Future<LatLng?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lat = prefs.getDouble(_cacheKeyLat);
      final lng = prefs.getDouble(_cacheKeyLng);
      final timestamp = prefs.getInt(_cacheKeyTimestamp);
      
      if (lat != null && lng != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid (24 hours)
        if (now.difference(cacheTime) < _cacheValidDuration) {
          return LatLng(lat, lng);
        } else {
          print('⏰ Cached location expired, will get fresh location');
          await _clearLocationCache();
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error reading cached location: $e');
      return null;
    }
  }

  // OPTIMIZED: Cache user's location
  static Future<void> _cacheLocation(LatLng location, String locationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(_cacheKeyLat, location.latitude);
      await prefs.setDouble(_cacheKeyLng, location.longitude);
      await prefs.setString(_cacheKeyName, locationName);
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      print('💾 Location cached successfully');
    } catch (e) {
      print('❌ Error caching location: $e');
    }
  }

  // OPTIMIZED: Clear expired or invalid cache
  static Future<void> _clearLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyLat);
      await prefs.remove(_cacheKeyLng);
      await prefs.remove(_cacheKeyName);
      await prefs.remove(_cacheKeyTimestamp);
    } catch (e) {
      print('❌ Error clearing location cache: $e');
    }
  }

  // OPTIMIZED: Get display name for location
  static String getLocationDisplayName(LatLng location) {
    // Check if it's the default Hyderabad location
    if (_isNearLocation(location, _defaultLocation, 10000)) { // Within 10km
      return _defaultLocationName;
    }
    
    return 'Current Location';
  }

  // OPTIMIZED: Permission dialog with clear explanation
  static Future<bool> _showLocationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width - 32 : 400,
              maxHeight: screenSize.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use Your Location?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Content text
                  Text(
                    'To show restaurants near you, we need access to your location. This will help us provide better recommendations.\n\nYour location is only used to find nearby places and is not shared with anyone.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 14 : 16,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Use Hyderabad',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Allow Location',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ) ?? false;
  }

  // OPTIMIZED: Location services disabled dialog
  static Future<void> _showLocationServicesDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width - 32 : 400,
              maxHeight: screenSize.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_off,
                          color: Colors.orange,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location Services Off',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Content text
                  Text(
                    'Location services are disabled on your device. Please enable them in your device settings to use your current location.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 14 : 16,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Geolocator.openLocationSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Open Settings',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // OPTIMIZED: Permanently denied dialog
  static Future<void> _showLocationPermanentlyDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width - 32 : 400,
              maxHeight: screenSize.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_disabled,
                          color: Colors.red,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location Access Denied',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Content text
                  Text(
                    'Location access has been permanently denied. To use your current location, please enable it in your device settings under App Permissions.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: isSmallScreen ? 14 : 16,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Geolocator.openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Open Settings',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Utility: Check if two locations are near each other
  static bool _isNearLocation(LatLng location1, LatLng location2, double radiusInMeters) {
    final distance = Geolocator.distanceBetween(
      location1.latitude,
      location1.longitude,
      location2.latitude,
      location2.longitude,
    );
    return distance <= radiusInMeters;
  }

  // Utility: Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Utility: Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // OPTIMIZED: Check if user can request location (don't auto-request)
  static Future<bool> canRequestLocation() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.deniedForever;
  }

  // Check current location permission status without requesting
  static Future<LocationPermission> getCurrentPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  // Check if location services are currently enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check if we can currently access GPS (services enabled + permission granted)
  static Future<bool> canCurrentlyAccessGPS() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    
    return serviceEnabled && 
           (permission == LocationPermission.always || 
            permission == LocationPermission.whileInUse);
  }
}