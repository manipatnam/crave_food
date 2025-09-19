// Enhanced Location Provider - Fetch once at app start, update only on user request
// lib/providers/enhanced_location_provider.dart

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class EnhancedLocationProvider extends ChangeNotifier {
  // Private fields
  LatLng? _currentLocation;
  String _locationName = 'Hyderabad'; // Default
  bool _isUsingUserLocation = false;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _isInitialized = false;

  // Public getters
  LatLng? get currentLocation => _currentLocation;
  String get locationName => _locationName;
  bool get isUsingUserLocation => _isUsingUserLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isInitialized => _isInitialized;
  bool get isFirstTimeUser => !_isUsingUserLocation;

  // 🚀 ONE-TIME INITIALIZATION AT APP START
  Future<void> initializeLocationOnce() async {
    if (_isInitialized) {
      print('🏠 Location already initialized, skipping...');
      return;
    }

    try {
      _setLoading(true);
      print('🏠 Initializing location for the first time...');
      
      // Step 1: Try to get cached user location first
      final cachedLocation = await LocationService.getCachedLocation();
      final hasUserLocation = await LocationService.hasUserLocation();
      
      if (cachedLocation != null && hasUserLocation) {
        // User has previously used their GPS location
        _currentLocation = cachedLocation;
        _locationName = LocationService.getLocationDisplayName(cachedLocation);
        _isUsingUserLocation = true;
        print('🏠 ✅ Using cached user location: $_locationName');
      } else {
        // First time user or no cached location - use default
        _currentLocation = const LatLng(17.3850, 78.4867); // Hyderabad
        _locationName = 'Hyderabad';
        _isUsingUserLocation = false;
        print('🏠 ✅ Using default location: $_locationName');
      }
      
      // Check if location permission can be requested
      _hasLocationPermission = await LocationService.canRequestLocation();
      _isInitialized = true;
      
      print('🏠 📍 Location initialized: $_locationName (GPS: $_isUsingUserLocation)');
      
    } catch (e) {
      print('❌ Error initializing location: $e');
      // Fallback to Hyderabad on any error
      _currentLocation = const LatLng(17.3850, 78.4867);
      _locationName = 'Hyderabad';
      _isUsingUserLocation = false;
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  // 📍 MANUAL LOCATION UPDATE (only when user taps "Use Current Location")
  Future<bool> requestCurrentLocationManually(context) async {
    try {
      _setLoading(true);
      print('📍 User manually requested current location...');
      
      final userLocation = await LocationService.getCurrentLocationWithPermission(context);
      
      if (userLocation != null) {
        // Successfully got user's location
        _currentLocation = userLocation;
        _locationName = LocationService.getLocationDisplayName(userLocation);
        _isUsingUserLocation = true;
        _hasLocationPermission = true;
        
        // Cache this location for future app launches
        await LocationService.cacheUserLocation(userLocation, _locationName);
        
        print('📍 ✅ User location updated and cached: $_locationName');
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to get user location');
        return false;
      }
      
    } catch (e) {
      print('❌ Error requesting current location: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🏠 SWITCH BACK TO DEFAULT LOCATION
  void useDefaultLocation() {
    _currentLocation = const LatLng(17.3850, 78.4867);
    _locationName = 'Hyderabad';
    _isUsingUserLocation = false;
    
    // Clear cached location so app starts with default next time
    LocationService.clearLocationCache();
    
    notifyListeners();
    print('🏠 Switched to default location: Hyderabad');
  }

  // 🎯 CONVENIENT METHODS FOR SCREENS
  
  // Get location as LatLng (most common usage)
  LatLng getCurrentLatLng() {
    return _currentLocation ?? const LatLng(17.3850, 78.4867);
  }
  
  // Get location as Position (for compatibility with existing code)
  Position? getCurrentPosition() {
    if (_currentLocation == null) return null;
    
    return Position(
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  // Private helper to manage loading state
  void _setLoading(bool loading) {
    if (_isLoadingLocation != loading) {
      _isLoadingLocation = loading;
      notifyListeners();
    }
  }

  // Get display text for current location status
  String get locationStatusText {
    if (_isLoadingLocation) {
      return 'Getting location...';
    } else if (_isUsingUserLocation) {
      return 'Your Location';
    } else {
      return 'Default Location';
    }
  }

  // Check if we can show "Use Current Location" option
  bool get canRequestLocation => _hasLocationPermission && !_isUsingUserLocation;
}

// Enhanced Location Service with public cache methods
// lib/services/enhanced_location_service.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedLocationService {
  // Default location: Hyderabad
  static const LatLng _defaultLocation = LatLng(17.3850, 78.4867);
  static const String _defaultLocationName = 'Hyderabad';
  
  // Cache keys for SharedPreferences
  static const String _cacheKeyLat = 'cached_user_lat';
  static const String _cacheKeyLng = 'cached_user_lng';
  static const String _cacheKeyName = 'cached_location_name';
  static const String _cacheKeyTimestamp = 'cached_location_timestamp';
  
  // Cache validity (7 days - longer since we only update manually)
  static const Duration _cacheValidDuration = Duration(days: 7);

  // 🔓 PUBLIC: Get cached location (used by provider)
  static Future<LatLng?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lat = prefs.getDouble(_cacheKeyLat);
      final lng = prefs.getDouble(_cacheKeyLng);
      final timestamp = prefs.getInt(_cacheKeyTimestamp);
      
      if (lat != null && lng != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid (7 days)
        if (now.difference(cacheTime) < _cacheValidDuration) {
          print('✅ Found valid cached location: $lat, $lng');
          return LatLng(lat, lng);
        } else {
          print('⏰ Cached location expired, will use default');
          await clearLocationCache();
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error reading cached location: $e');
      return null;
    }
  }

  // 🔓 PUBLIC: Cache user's location
  static Future<void> cacheUserLocation(LatLng location, String locationName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(_cacheKeyLat, location.latitude);
      await prefs.setDouble(_cacheKeyLng, location.longitude);
      await prefs.setString(_cacheKeyName, locationName);
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Location cached: $locationName');
    } catch (e) {
      print('❌ Error caching location: $e');
    }
  }

  // 🔓 PUBLIC: Clear cached location
  static Future<void> clearLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyLat);
      await prefs.remove(_cacheKeyLng);
      await prefs.remove(_cacheKeyName);
      await prefs.remove(_cacheKeyTimestamp);
      print('🗑️ Location cache cleared');
    } catch (e) {
      print('❌ Error clearing location cache: $e');
    }
  }

  // Check if user has cached location
  static Future<bool> hasUserLocation() async {
    final cachedLocation = await getCachedLocation();
    return cachedLocation != null;
  }

  // Get current GPS location (only when user requests it manually)
  static Future<LatLng?> getCurrentLocationWithPermission(BuildContext context) async {
    try {
      print('📍 User manually requested current location...');
      
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServicesDialog(context);
        return null;
      }

      // Step 2: Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
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

      // Step 3: Get GPS location
      print('🛰️ Getting GPS location...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      print('✅ GPS location obtained: ${position.latitude}, ${position.longitude}');
      return userLocation;
      
    } catch (e) {
      print('❌ Error getting GPS location: $e');
      return null;
    }
  }

  // Get display name for location
  static String getLocationDisplayName(LatLng location) {
    // For now, return coordinates as display name
    // You can enhance this with reverse geocoding later
    if (location.latitude == _defaultLocation.latitude && 
        location.longitude == _defaultLocation.longitude) {
      return _defaultLocationName;
    }
    return 'Your Location';
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

  // Check if user can request location
  static Future<bool> canRequestLocation() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.deniedForever;
  }

  // Permission dialogs (same as your existing ones)
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
                          Icons.location_on,
                          color: Colors.blue,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location Access',
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
                    'We need location access to show restaurants near you and calculate distances. This helps you find the closest places to visit.',
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
                          'Cancel',
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
                          'Allow',
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
                          'Location Services Disabled',
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
                crossAxisAlignment: CrossAxisAlignment.Start,
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
}