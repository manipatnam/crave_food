// FILE: lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../providers/favourites_provider.dart';
import '../models/favourite_model.dart';
import '../services/location_service.dart';
import '../services/google_places_services.dart';
import '../models/place_model.dart';
import '../widgets/search/map_search_bar.dart';
import '../widgets/search/map_filters.dart';
import '../widgets/search/restaurant_info_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  
  LatLng _currentLocation = const LatLng(17.3850, 78.4867); // Default: Hyderabad
  Set<Marker> _markers = {};
  List<PlaceModel> _searchResults = [];
  Favourite? _selectedFavourite;
  
  bool _isLoadingLocation = true;
  bool _isSearching = false;
  bool _showVegOnly = false;
  bool _showNonVegOnly = false;
  List<String> _selectedTags = [];
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
    _loadFavourites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    print('🗺️ Initializing map...');
    
    try {
      // Get current location with fallback
      final location = await LocationService.getLocationWithFallback();
      
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
        
        // Add current location marker
        _addCurrentLocationMarker();
        
        print('✅ Map initialized with location: $_currentLocation');
      }
    } catch (e) {
      print('❌ Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _loadFavourites() {
    print('📱 Loading favourites for map...');
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    
    // Load favourites if not already loaded
    if (favouritesProvider.favourites.isEmpty) {
      favouritesProvider.loadFavourites();
    } else {
      // If already loaded, add markers immediately
      _addFavouriteMarkers(favouritesProvider.favourites);
    }
  }

  void _addCurrentLocationMarker() {
    final marker = Marker(
      markerId: const MarkerId('current_location'),
      position: _currentLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'You are here',
      ),
    );
    
    setState(() {
      _markers.add(marker);
    });
  }

  void _addFavouriteMarkers(List<Favourite> favourites) {
    print('📍 Adding ${favourites.length} favourite markers to map...');
    
    // Filter favourites based on current filters
    final filteredFavourites = _filterFavourites(favourites);
    
    final favouriteMarkers = filteredFavourites.map((favourite) {
      return Marker(
        markerId: MarkerId('favourite_${favourite.id}'),
        position: LatLng(
          favourite.coordinates.latitude,
          favourite.coordinates.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(favourite),
        ),
        infoWindow: InfoWindow(
          title: favourite.restaurantName,
          snippet: favourite.foodNamesPreview,
          onTap: () => _showFavouriteDetails(favourite),
        ),
        onTap: () => _showFavouriteDetails(favourite),
      );
    }).toSet();
    
    setState(() {
      // Remove old favourite markers but keep current location
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('favourite_'));
      _markers.addAll(favouriteMarkers);
    });
    
    print('✅ Added ${favouriteMarkers.length} markers to map');
  }

  List<Favourite> _filterFavourites(List<Favourite> favourites) {
    return favourites.where((favourite) {
      // Dietary filter
      if (_showVegOnly && !favourite.isVegetarianAvailable) return false;
      if (_showNonVegOnly && !favourite.isNonVegetarianAvailable) return false;
      
      // Tags filter
      if (_selectedTags.isNotEmpty) {
        final hasMatchingTag = _selectedTags.any(
          (tag) => favourite.tags.contains(tag.toLowerCase()),
        );
        if (!hasMatchingTag) return false;
      }
      
      return true;
    }).toList();
  }

  double _getMarkerColor(Favourite favourite) {
    // Different colors based on dietary options
    if (favourite.isVegetarianAvailable && favourite.isNonVegetarianAvailable) {
      return BitmapDescriptor.hueOrange; // Mixed
    } else if (favourite.isVegetarianAvailable) {
      return BitmapDescriptor.hueGreen; // Veg only
    } else if (favourite.isNonVegetarianAvailable) {
      return BitmapDescriptor.hueRed; // Non-veg only
    }
    return BitmapDescriptor.hueViolet; // Default
  }

  void _showFavouriteDetails(Favourite favourite) {
    setState(() {
      _selectedFavourite = favourite;
    });
    
    // Show bottom sheet with restaurant details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantInfoSheet(
        favourite: favourite,
        currentLocation: _currentLocation,
        onNavigate: () => _navigateToRestaurant(favourite),
        onClose: () {
          setState(() {
            _selectedFavourite = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _navigateToRestaurant(Favourite favourite) {
    // TODO: Implement navigation to restaurant
    _showSnackBar('Navigation feature coming soon!');
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _placesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        // Add search result markers
        _addSearchResultMarkers(results);
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showSnackBar('Error searching: $e');
      }
    }
  }

  void _addSearchResultMarkers(List<PlaceModel> results) {
    final searchMarkers = results.map((place) {
      return Marker(
        markerId: MarkerId('search_${place.placeId}'),
        position: LatLng(
          place.geoPoint.latitude,
          place.geoPoint.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.displayAddress,
        ),
      );
    }).toSet();
    
    setState(() {
      // Remove old search markers
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('search_'));
      _markers.addAll(searchMarkers);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print('✅ Google Map created and ready');
  }

  void _goToCurrentLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
        
        setState(() {
          _currentLocation = location;
        });
        
        _addCurrentLocationMarker();
      }
    } catch (e) {
      _showSnackBar('Error getting current location: $e');
    }
  }

  void _onFilterChanged({
    bool? showVegOnly,
    bool? showNonVegOnly,
    List<String>? selectedTags,
  }) {
    setState(() {
      if (showVegOnly != null) _showVegOnly = showVegOnly;
      if (showNonVegOnly != null) _showNonVegOnly = showNonVegOnly;
      if (selectedTags != null) _selectedTags = selectedTags;
    });
    
    // Refresh markers with new filters
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    _addFavouriteMarkers(favouritesProvider.favourites);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps View
          _isLoadingLocation
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading map...'),
                    ],
                  ),
                )
              : Consumer<FavouritesProvider>(
                  builder: (context, favouritesProvider, child) {
                    return GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _onMapCreated(controller);
                        // Add markers only once when map is created
                        if (favouritesProvider.favourites.isNotEmpty) {
                          _addFavouriteMarkers(favouritesProvider.favourites);
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation,
                        zoom: 13.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      trafficEnabled: false,
                      buildingsEnabled: true,
                      onTap: (LatLng position) {
                        // Hide any open info sheets when map is tapped
                        if (_selectedFavourite != null) {
                          setState(() {
                            _selectedFavourite = null;
                          });
                        }
                      },
                    );
                  },
                ),
          
          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: MapSearchBar(
              controller: _searchController,
              isSearching: _isSearching,
              onSearch: _searchPlaces,
              onCurrentLocation: _goToCurrentLocation,
            ),
          ),
          
          // Filter Options
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: MapFilters(
              showVegOnly: _showVegOnly,
              showNonVegOnly: _showNonVegOnly,
              selectedTags: _selectedTags,
              onFilterChanged: _onFilterChanged,
            ),
          ),
          
          // Floating Action Button for Current Location
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}