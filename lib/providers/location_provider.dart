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
  // Always fetches fresh GPS location, handles permissions, and shows appropriate dialogs
  Future<bool> requestCurrentLocation(context) async {
    try {
      _setLoading(true);
      print('📍 Button pressed - requesting fresh GPS location...');
      
      // Always get fresh GPS location - this will handle all permission checks internally
      final userLocation = await LocationService.getCurrentLocationWithPermission(context);
      
      if (userLocation != null) {
        // Successfully got fresh GPS location
        _currentLocation = userLocation;
        _locationName = LocationService.getLocationDisplayName(userLocation);
        _isUsingUserLocation = true;
        _hasLocationPermission = true;
        
        print('✅ Fresh GPS location obtained: $_locationName');
        notifyListeners();
        return true;
      } else {
        // Failed to get GPS location (permissions denied, services off, etc.)
        // The LocationService already showed appropriate error dialogs
        print('❌ Failed to get fresh GPS location');
        
        // Update permission status based on current state
        _hasLocationPermission = await LocationService.canRequestLocation();
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      print('❌ Error requesting current location: $e');
      _hasLocationPermission = await LocationService.canRequestLocation();
      notifyListeners();
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
  bool get canRequestLocation => _hasLocationPermission;
  
  // Check if the location button should show as "active" (using live GPS)
  bool get isLocationButtonActive => _isUsingUserLocation && _hasLocationPermission;
}