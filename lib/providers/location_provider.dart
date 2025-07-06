// NEW lib/providers/location_provider.dart
// Smart Location State Management with Caching

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  String _locationName = 'Hyderabad'; // Default
  bool _isUsingUserLocation = false;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  String get locationName => _locationName;
  bool get isUsingUserLocation => _isUsingUserLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isFirstTimeUser => !_isUsingUserLocation;

  // Initialize location on app start
  Future<void> initializeLocation() async {
    try {
      _setLoading(true);
      
      // Get initial location (cached or Hyderabad default)
      final location = await LocationService.getInitialLocation();
      
      // Check if user has previously set their location
      final hasUserLocation = await LocationService.hasUserLocation();
      
      _currentLocation = location;
      _isUsingUserLocation = hasUserLocation;
      _locationName = LocationService.getLocationDisplayName(location);
      
      // Check if location permission can be requested
      _hasLocationPermission = await LocationService.canRequestLocation();
      
      print('🏠 Location initialized: $_locationName (User location: $_isUsingUserLocation)');
      
    } catch (e) {
      print('❌ Error initializing location: $e');
      // Fallback to Hyderabad
      _currentLocation = const LatLng(17.3850, 78.4867);
      _locationName = 'Hyderabad';
      _isUsingUserLocation = false;
    } finally {
      _setLoading(false);
    }
  }

  // Request user's current location (when they tap "Use Current Location")
  Future<bool> requestCurrentLocation(context) async {
    try {
      _setLoading(true);
      
      final userLocation = await LocationService.getCurrentLocationWithPermission(context);
      
      if (userLocation != null) {
        _currentLocation = userLocation;
        _locationName = LocationService.getLocationDisplayName(userLocation);
        _isUsingUserLocation = true;
        _hasLocationPermission = true;
        
        print('📍 User location updated: $_locationName');
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

  // Switch back to default location
  void useDefaultLocation() {
    _currentLocation = const LatLng(17.3850, 78.4867);
    _locationName = 'Hyderabad';
    _isUsingUserLocation = false;
    notifyListeners();
    print('🏠 Switched to default location: Hyderabad');
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