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
import '../screens/add_favourite_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  
  // Remove hardcoded location - will be set dynamically
  LatLng? _currentLocation;
  String _locationDisplayName = 'Detecting location...';
  bool _isLocationFromGPS = false;
  bool _isLocationFromIP = false;
  
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
    print('🗺️ Initializing map with improved location detection...');
    
    try {
      // First, check if we should ask for location permission
      final hasPermission = await LocationService.hasLocationPermission();
      
      if (!hasPermission && mounted) {
        // Show dialog explaining why we need location
        final shouldRequestPermission = await LocationService.showLocationPermissionDialog(context);
        
        if (shouldRequestPermission) {
          await LocationService.requestLocationPermission();
        }
      }
      
      // Get location using the improved fallback strategy
      final location = await LocationService.getLocationWithFallback();
      
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
          _locationDisplayName = LocationService.getLocationDisplayName(location);
        });
        
        // Determine location source for user feedback
        final gpsLocation = await LocationService.getCurrentLocation();
        if (gpsLocation != null) {
          _isLocationFromGPS = true;
          print('✅ Map initialized with GPS location: $location');
        } else {
          _isLocationFromIP = true;
          print('✅ Map initialized with fallback location: $location');
          _showLocationFallbackInfo();
        }
      }
    } catch (e) {
      print('❌ Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationDisplayName = 'Location unavailable';
        });
        _showSnackBar('Error detecting location. Please try enabling location services.');
      }
    }
  }

  void _showLocationFallbackInfo() {
    // Show a subtle info message that we're using fallback location
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLocationFromIP 
                    ? 'Using approximate location. Enable GPS for better results.'
                    : 'Using default location. Enable location services for personalized results.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Enable GPS',
            textColor: Colors.white,
            onPressed: _requestLocationPermission,
          ),
        ),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await LocationService.requestLocationPermission();
    if (granted) {
      // Refresh location
      _initializeMap();
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
      // Remove old favourite markers
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
        currentLocation: _currentLocation!,
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

  void _showAddFavouriteDialog(PlaceModel place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add to Favourites',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: place.photoUrl != null
                          ? Image.network(
                              place.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.restaurant,
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.restaurant,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (place.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          place.displayAddress,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to add this restaurant to your favourites? You can add food items and other details later.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _addToFavourites(place);
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Add to Favourites'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addToFavourites(PlaceModel place) {
    // Navigate to Add Favourite screen with pre-filled restaurant data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFavouriteScreen(prefilledPlace: place),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh favourites if a new one was added
        final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
        favouritesProvider.loadFavourites();
        _showSnackBar('Restaurant added to favourites!');
        
        // Clear search results and markers
        _searchController.clear();
        _removeSearchMarkers();
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Widget _buildSearchResultTile(PlaceModel place, bool isLast) {
    return Container(
      margin: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 4,
        bottom: isLast ? 4 : 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.grey[200],
            child: place.photoUrl != null
                ? Image.network(
                    place.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.restaurant,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Icon(
                    Icons.restaurant,
                    color: Theme.of(context).primaryColor,
                  ),
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.displayAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (place.rating != null || place.cuisineTypes.isNotEmpty)
              const SizedBox(height: 4),
            Row(
              children: [
                if (place.rating != null) ...[
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
                if (place.rating != null && place.cuisineTypes.isNotEmpty)
                  const Text(' • ', style: TextStyle(fontSize: 12)),
                if (place.cuisineTypes.isNotEmpty)
                  Expanded(
                    child: Text(
                      place.cuisineTypes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.add_circle,
          color: Theme.of(context).primaryColor,
        ),
        onTap: () {
          // Hide search results and show marker on map
          setState(() {
            _searchResults = [];
          });
          
          // Focus map on selected place
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
                16.0,
              ),
            );
          }
          
          // Add single marker for selected place
          _addSingleSearchMarker(place);
        },
      ),
    );
  }

  void _addSingleSearchMarker(PlaceModel place) {
    final searchMarker = Marker(
      markerId: MarkerId('search_${place.placeId}'),
      position: LatLng(
        place.geoPoint.latitude,
        place.geoPoint.longitude,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
        title: place.name,
        snippet: place.displayAddress,
        onTap: () => _showAddFavouriteDialog(place),
      ),
      onTap: () => _showAddFavouriteDialog(place),
    );
    
    setState(() {
      // Remove old search markers
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('search_'));
      _markers.add(searchMarker);
    });
  }

  // THIS IS THE KEY FIX - Use proper location-based search
  Future<void> _searchPlaces(String query) async {
    if (query.length < 2 || _currentLocation == null) {
      setState(() {
        _searchResults = [];
      });
      // Remove search markers when search is cleared
      _removeSearchMarkers();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      print('🔍 Searching for "$query" near ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      
      // Use the proper location-based search method
      final results = await _placesService.searchNearbyRestaurants(
        query: query,
        location: _currentLocation!,
        radius: 5000, // 5km radius
      );
      
      print('✅ Found ${results.length} places near current location');
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        // Add search result markers
        _addSearchResultMarkers(results);
        
        // Show user feedback
        if (results.isNotEmpty) {
          _showSnackBar('Found ${results.length} places near your location');
        } else {
          _showSnackBar('No places found near your location. Try a different search.');
        }
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

  void _removeSearchMarkers() {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('search_'));
    });
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
          onTap: () => _showAddFavouriteDialog(place),
        ),
        onTap: () => _showAddFavouriteDialog(place),
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
      // Try to get fresh GPS location
      final location = await LocationService.getCurrentLocation();
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
        
        setState(() {
          _currentLocation = location;
          _locationDisplayName = LocationService.getLocationDisplayName(location);
          _isLocationFromGPS = true;
          _isLocationFromIP = false;
        });
        
        _showSnackBar('Location updated!');
      } else {
        _showSnackBar('Unable to get current location');
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Map Legend'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem('📍🟢', 'Vegetarian Only', 'Green pins - Restaurants serving only vegetarian food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🔴', 'Non-Vegetarian Only', 'Red pins - Restaurants serving only non-vegetarian food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟠', 'Mixed Options', 'Orange pins - Restaurants serving both veg & non-veg food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟣', 'Default', 'Purple pins - Restaurants with unspecified dietary options'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟡', 'Search Results', 'Yellow pins - Restaurants from your current search'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps View
          _isLoadingLocation
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Detecting your location...'),
                      const SizedBox(height: 8),
                      Text(
                        'This helps us show nearby restaurants',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
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
                        target: _currentLocation!,
                        zoom: 13.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: _isLocationFromGPS, // Only show if GPS is available
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      trafficEnabled: false,
                      buildingsEnabled: false,
                      mapType: MapType.normal,
                      // Disable default map symbols and POIs
                      style: '''
[
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.government",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.medical",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.school",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.sports_complex",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''',
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
          
          // Search Bar with Location Status
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 72,
            child: Column(
              children: [
                // Location Status Bar
                if (!_isLoadingLocation) 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isLocationFromGPS ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _goToCurrentLocation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLocationFromGPS ? Icons.my_location : Icons.location_on,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _locationDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!_isLocationFromGPS) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.refresh,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                // Main Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants near you...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: _isSearching
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _searchPlaces('');
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                              ),
                            )
                          : IconButton(
                              onPressed: _goToCurrentLocation,
                              icon: Icon(
                                Icons.my_location,
                                color: Colors.grey[600],
                              ),
                              tooltip: 'Go to current location',
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                
                // Search Results List
                if (_searchResults.isNotEmpty && !_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return _buildSearchResultTile(place, index == _searchResults.length - 1);
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Info Icon next to Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _showLegendDialog,
                icon: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Map Legend',
              ),
            ),
          ),
          
          // Filter Options (adjust position based on location bar visibility)
          Positioned(
            top: MediaQuery.of(context).padding.top + (_isLoadingLocation ? 80 : 110),
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
              heroTag: "current_location",
              child: Icon(_isLocationFromGPS ? Icons.my_location : Icons.location_searching),
            ),
          ),
        ],
      ),
    );
  }
}