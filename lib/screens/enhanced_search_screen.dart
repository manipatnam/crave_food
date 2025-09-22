// Updated Enhanced Search Screen with Google Maps-like Search Integration
// lib/screens/enhanced_search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../providers/favourites_provider.dart';
import '../models/favourite_model.dart';
import '../services/location_service.dart';
import '../services/google_places_services.dart';
import '../models/place_model.dart';
import '../screens/add_favourite_screen.dart';
import '../enums/search/search_sort_option.dart';
import '../utils/search/search_filter_utils.dart';
import '../utils/search/map_legend_dialog.dart';
import '../constants/map_styles.dart';

import '../widgets/search/active_filter_chip.dart';
import '../widgets/search/sort_section.dart';
import '../widgets/search/distance_filter.dart';
import '../widgets/search/quick_filters.dart';
import '../widgets/search/rating_filter.dart';
import '../widgets/search/categories_filter.dart';
import '../widgets/search/tags_filter.dart';
import '../widgets/search/active_filters_row.dart';
import '../widgets/search/filter_content.dart';
import '../widgets/search/simple_animated_filter_panel.dart';
import '../widgets/search/search_result_tile.dart';

// NEW IMPORTS FOR SEARCH INTEGRATION
import '../screens/search/search_results_screen.dart';
import '../widgets/search/place_info_sheet.dart';

import '../providers/location_provider.dart';  
import '../../widgets/common/universal_restaurant_tile.dart';
import '../../widgets/adapters/screen_tile_adapters.dart';

class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen>
    with TickerProviderStateMixin {
  // Controllers and Services
  GoogleMapController? _mapController;
  final GooglePlacesService _placesService = GooglePlacesService();
  
  // Location State
  LatLng? _currentLocation;
  
  // Map and Search State
  Set<Marker> _markers = {};
  Set<Marker> _favoriteMarkers = {};
  Set<Marker> _searchMarkers = {};
  List<PlaceModel> _searchResults = [];
  Favourite? _selectedFavourite;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _favoritesInitialized = false;
  
  // Enhanced Filter State
  bool _showFilters = false;
  SearchSortOption _currentSort = SearchSortOption.relevance;
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];
  double _minRating = 0.0;
  double _maxDistance = 10.0; // in km
  bool _showOpenOnly = false;
  bool _showVegOnly = false;
  bool _showNonVegOnly = false;
  bool _showFavoritesOnly = false;
  String _selectedPriceRange = 'Any';
  
  // Animation Controllers
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await LocationService.getCurrentLocationWithPermission(context);
      if (locationData != null) {
        setState(() {
          _currentLocation = locationData;
        });
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
          );
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController!.setMapStyle(MapStyles.hideAllPois);
    
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  // NEW METHOD: Navigate to separate search screen
  Future<void> _navigateToSearch() async {
    final result = await Navigator.push<PlaceModel>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          currentLatitude: _currentLocation?.latitude,
          currentLongitude: _currentLocation?.longitude,
        ),
      ),
    );
    
    // Handle the selected place result
    if (result != null) {
      _onPlaceSelected(result);
    }
  }

  // NEW METHOD: Handle place selection from search
  void _onPlaceSelected(PlaceModel place) {
    // Add orange marker to map
    _addSearchMarker(place);
    
    // Move camera to show the selected place
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
        16.0,
      ),
    );
    
    // Show info sheet
    _showPlaceInfo(place);
  }

  // NEW METHOD: Add search marker
  void _addSearchMarker(PlaceModel place) {
    final marker = Marker(
      markerId: MarkerId('search_${place.placeId ?? place.name}'),
      position: LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
      infoWindow: InfoWindow(
        title: place.name,
        snippet: place.displayAddress,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      onTap: () => _showPlaceInfo(place),
    );
    
    _searchMarkers = {marker};
    _updateAllMarkers();
  }

  // NEW METHOD: Show place info sheet
  void _showPlaceInfo(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceInfoSheet(
        place: place,
        currentLocation: _currentLocation,
        onAddToFavourites: () => _navigateToAddFavourite(place),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  // NEW METHOD: Navigate to add favourite
  void _navigateToAddFavourite(PlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFavouriteScreen(prefilledPlace: place),
      ),
    );
  }

  void _goToCurrentLocation() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
    }
    
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
      );
    }
  }

  // UPDATED METHOD: Efficient favorite markers management with proper colors
  void _addFavouriteMarkers(List<Favourite> favourites) {
    final newFavoriteMarkers = favourites.map((favourite) {
      return Marker(
        markerId: MarkerId('fav_${favourite.id}'),
        position: LatLng(
          favourite.coordinates.latitude,
          favourite.coordinates.longitude,
        ),
        infoWindow: InfoWindow(
          title: favourite.restaurantName,
          snippet: favourite.cuisineType ?? '',
        ),
        icon: _getMarkerIcon(favourite), // FIXED: Use proper color logic
        onTap: () => _showFavouriteInfo(favourite),
      );
    }).toSet();
    
    // Only update if markers actually changed
    if (_favoriteMarkers.length != newFavoriteMarkers.length || 
        !_favoriteMarkers.every((marker) => newFavoriteMarkers.contains(marker))) {
      _favoriteMarkers = newFavoriteMarkers;
      _updateAllMarkers();
    }
  }

  // RESTORED METHOD: Get marker color based on veg/non-veg options
  BitmapDescriptor _getMarkerIcon(Favourite favourite) {
    if (favourite.isVegetarianAvailable && !favourite.isNonVegetarianAvailable) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (!favourite.isVegetarianAvailable && favourite.isNonVegetarianAvailable) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (favourite.isVegetarianAvailable && favourite.isNonVegetarianAvailable) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // NEW METHOD: Efficiently combine all markers
  void _updateAllMarkers() {
    final allMarkers = <Marker>{};
    allMarkers.addAll(_favoriteMarkers);
    allMarkers.addAll(_searchMarkers);
    
    if (_markers.length != allMarkers.length || 
        !_markers.every((marker) => allMarkers.contains(marker))) {
      setState(() {
        _markers = allMarkers;
      });
    }
  }

  void _showFavouriteInfo(Favourite favourite) {
    // Show existing favorite info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(favourite.restaurantName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favourite.cuisineType != null)
              Text('Cuisine: ${favourite.cuisineType}'),
            if (favourite.rating != null)
              Text('Rating: ${favourite.rating}/5'),
            const SizedBox(height: 8),
            Text('Visit Status: ${favourite.visitStatus.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Filter handling methods (keep existing)
  void _handleActiveFilterRemove({
    SearchSortOption? currentSort,
    double? minRating,
    double? maxDistance,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    String? removeCategory,
    String? removeTag,
  }) {
    setState(() {
      if (currentSort != null) _currentSort = SearchSortOption.relevance;
      if (minRating != null) _minRating = 0.0;
      if (maxDistance != null) _maxDistance = 50.0;
      if (showOpenOnly != null) _showOpenOnly = false;
      if (showVegOnly != null) _showVegOnly = false;
      if (showNonVegOnly != null) _showNonVegOnly = false;
      if (removeCategory != null) _selectedCategories.remove(removeCategory);
      if (removeTag != null) _selectedTags.remove(removeTag);
    });
    _refreshResults();
  }

  void _refreshResults() {
    // Refresh search results with current filters
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final results = await _placesService.searchPlaces(query);

      // Apply basic filtering
      final filteredResults = results.where((place) {
        // Rating filter
        if (_minRating > 0.0 && (place.rating == null || place.rating! < _minRating)) {
          return false;
        }
        
        // Distance filter
        if (_currentLocation != null && _maxDistance < 50.0) {
          final distance = LocationService.calculateDistance(
            _currentLocation!,
            LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
          ) / 1000; // Convert to km
          if (distance > _maxDistance) return false;
        }
        
        // Open only filter
        if (_showOpenOnly && !place.isOpen) return false;
        
        return true;
      }).toList();

      // Apply sorting using existing utility
      final sortedResults = SearchFilterUtils.sortSearchResults(
        filteredResults,
        _currentSort,
        _currentLocation,
      );

      setState(() {
        _searchResults = sortedResults;
        _isSearching = false;
      });

      // Update map markers
      _updateMapMarkers(sortedResults);

    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _updateMapMarkers(List<PlaceModel> places) {
    final newSearchMarkers = places.map((place) {
      return Marker(
        markerId: MarkerId('search_${place.placeId ?? place.name}'),
        position: LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.displayAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () => _showPlaceInfo(place),
      );
    }).toSet();
    
    _searchMarkers = newSearchMarkers;
    _updateAllMarkers();
  }

  bool _hasActiveFilters() {
    return _minRating > 0.0 ||
           _maxDistance < 50.0 ||
           _showOpenOnly ||
           _showVegOnly ||
           _showNonVegOnly ||
           _showFavoritesOnly ||
           _selectedCategories.isNotEmpty ||
           _selectedTags.isNotEmpty ||
           _currentSort != SearchSortOption.relevance;
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(17.3850, 78.4867), // Default to Hyderabad
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),

          // UPDATED: New Search Bar (navigates to search screen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToSearch, // KEY CHANGE: Navigate to search screen
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            'Search for restaurants...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Keep existing filter button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleFilters,
                    icon: AnimatedRotation(
                      turns: _showFilters ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _showFilters || _hasActiveFilters()
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                    tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                  ),
                ),
              ],
            ),
          ),

          // Active Filters (show below search)
          if (_hasActiveFilters())
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: ActiveFiltersRow(
                minRating: _minRating,
                maxDistance: _maxDistance,
                showOpenOnly: _showOpenOnly,
                showVegOnly: _showVegOnly,
                showNonVegOnly: _showNonVegOnly,
                currentSort: _currentSort,
                selectedCategories: _selectedCategories,
                selectedTags: _selectedTags,
                onFilterRemoved: _handleActiveFilterRemove,
                onUpdate: _refreshResults,
              ),
            ),

          // Filter Panel (keep existing)
          AnimatedFilterPanel(
            showFilters: _showFilters,
            child: FilterContent(
              currentSort: _currentSort,
              onSortChanged: (sort) => setState(() => _currentSort = sort),
              minRating: _minRating,
              onRatingChanged: (rating) => setState(() => _minRating = rating),
              maxDistance: _maxDistance,
              onDistanceChanged: (distance) => setState(() => _maxDistance = distance),
              showOpenOnly: _showOpenOnly,
              showVegOnly: _showVegOnly,
              showNonVegOnly: _showNonVegOnly,
              showFavoritesOnly: _showFavoritesOnly,
              onQuickFiltersChanged: ({showOpenOnly, showVegOnly, showNonVegOnly, showFavoritesOnly}) {
                setState(() {
                  if (showOpenOnly != null) _showOpenOnly = showOpenOnly;
                  if (showVegOnly != null) _showVegOnly = showVegOnly;
                  if (showNonVegOnly != null) _showNonVegOnly = showNonVegOnly;
                  if (showFavoritesOnly != null) _showFavoritesOnly = showFavoritesOnly;
                });
              },
              selectedCategories: _selectedCategories,
              onCategoriesChanged: (categories) => setState(() => _selectedCategories = categories),
              selectedTags: _selectedTags,
              onTagsChanged: (tags) => setState(() => _selectedTags = tags),
              onClearAll: () {
                setState(() {
                  _currentSort = SearchSortOption.relevance;
                  _minRating = 0.0;
                  _maxDistance = 50.0;
                  _showOpenOnly = false;
                  _showVegOnly = false;
                  _showNonVegOnly = false;
                  _selectedCategories.clear();
                  _selectedTags.clear();
                });
                _refreshResults();
              },
            ),
          ),

          // UPDATED: Efficient Favorites Integration
          Selector<FavouritesProvider, int>(
            selector: (context, provider) => provider.favourites.length,
            builder: (context, favouritesCount, child) {
              // Only update markers when favorites count changes and map is ready
              if (favouritesCount > 0 && _mapController != null && !_favoritesInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final provider = Provider.of<FavouritesProvider>(context, listen: false);
                  _addFavouriteMarkers(provider.favourites);
                  _favoritesInitialized = true;
                });
              }
              return const SizedBox.shrink();
            },
          ),

          // Location Button (keep existing)
          Positioned(
            bottom: 100,
            right: 16,
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, child) {
                return FloatingActionButton(
                  mini: true,
                  heroTag: "location_button",
                  onPressed: locationProvider.isLoadingLocation 
                    ? null 
                    : _goToCurrentLocation,
                  backgroundColor: locationProvider.isUsingUserLocation 
                    ? Theme.of(context).primaryColor 
                    : Colors.white,
                  child: locationProvider.isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        locationProvider.isUsingUserLocation 
                          ? Icons.my_location 
                          : Icons.location_searching,
                        color: locationProvider.isUsingUserLocation 
                          ? Colors.white 
                          : Colors.grey[600],
                      ),
                );
              },
            ),
          ),

          // Info/Legend Button (keep existing)
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: "info_button",
              onPressed: () => MapLegendDialog.show(context),
              backgroundColor: Colors.white,
              child: Icon(
                Icons.info_outline,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}