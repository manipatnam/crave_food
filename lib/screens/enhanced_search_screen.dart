// Enhanced Search Screen with Advanced Filters - FIXED FOR YOUR MODELS
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
import '../widgets/search/restaurant_info_sheet.dart';
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
import '../widgets/search/animated_filter_panel.dart';
import '../widgets/search/search_result_tile.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  
  // Location State
  LatLng? _currentLocation;
  
  // Map and Search State
  Set<Marker> _markers = {};
  List<PlaceModel> _searchResults = [];
  Favourite? _selectedFavourite;
  bool _isSearching = false;
  String _searchQuery = '';
  
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
  
  // Debouncer for search
  Timer? _searchDebouncer;

  String get _locationDisplayName {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    return locationProvider.locationName;
  }

  bool get _isLocationFromGPS {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    return locationProvider.isUsingUserLocation;
  }

  bool get _isLoadingLocation {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    return locationProvider.isLoadingLocation;
  }


  @override
  void initState() {
    super.initState();
    print('🗺️ EnhancedSearchScreen initState called');
    _initializeAnimations();
    _initializeMap();
    _searchController.addListener(_onSearchChanged);
    
    // ✅ ADD THIS: Listen to location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).addListener(_onLocationChanged);
    });
  }

  // ✅ ADD THIS METHOD:
  void _onLocationChanged() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    print('🗺️ Location changed! New location: ${locationProvider.currentLocation}');
    
    if (locationProvider.currentLocation != null && _currentLocation == null) {
      setState(() {
        _currentLocation = locationProvider.currentLocation;
      });
      print('🗺️ ✅ Map location updated: $_currentLocation');
    }
  }

// ✅ ADD THIS to dispose:
  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _filterAnimationController.dispose();
    _searchDebouncer?.cancel();
    
    // Remove location listener
    Provider.of<LocationProvider>(context, listen: false).removeListener(_onLocationChanged);
    
    super.dispose();
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

  void _onSearchChanged() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
        if (query.isNotEmpty) {
          _searchPlaces(query);
        } else {
          _clearSearchResults();
        }
      }
    });
  }

  Future<void> _initializeMap() async {
    print('🗺️ _initializeMap called');
    
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    print('🗺️ LocationProvider.currentLocation: ${locationProvider.currentLocation}');
    
    // If location is available, use it immediately
    if (locationProvider.currentLocation != null) {
      setState(() {
        _currentLocation = locationProvider.currentLocation;
      });
      print('🗺️ ✅ Location set immediately: $_currentLocation');
    } else {
      print('🗺️ ⏳ Location not ready yet, will listen for changes');
      // Location will be set when provider updates (see next step)
    }
  }

  void _loadFavourites() {
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    _addFavouriteMarkers(favouritesProvider.favourites);
  }

  void _addFavouriteMarkers(List<Favourite> favourites) {
    print('🗺️ _addFavouriteMarkers called with ${favourites.length} favorites');
    
    final filteredFavourites = _applyFiltersToFavourites(favourites);
    print('🗺️ After filtering: ${filteredFavourites.length} favorites');
    
    if (filteredFavourites.isEmpty) {
      print('🗺️ ❌ No favorites after filtering!');
      return;
    }
    
    final favouriteMarkers = filteredFavourites.map((favourite) {
      print('🗺️ Creating marker for: ${favourite.restaurantName}');
      return Marker(
        markerId: MarkerId('fav_${favourite.id}'),
        position: LatLng(favourite.coordinates.latitude, favourite.coordinates.longitude),
        icon: _getMarkerIcon(favourite),
        infoWindow: InfoWindow(
          title: favourite.restaurantName,
          snippet: favourite.cuisineType ?? 'Restaurant',
          onTap: () => _showFavouriteDetails(favourite),
        ),
        onTap: () => _showFavouriteDetails(favourite),
      );
    }).toSet();
    
    print('🗺️ Created ${favouriteMarkers.length} markers');
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('fav_'));
      _markers.addAll(favouriteMarkers);
    });
    
    print('🗺️ ✅ Total markers on map: ${_markers.length}');
  }

  // ADD this new method after your existing _addFavouriteMarkers method:
  void _addFavouriteMarkersOnce(List<Favourite> favourites) {
    // Check if favorites markers are already loaded
    final existingFavMarkers = _markers.where((marker) => 
      marker.markerId.value.startsWith('fav_')).length;
      
    if (existingFavMarkers >= favourites.length) {
      print('🗺️ Favorites already loaded, skipping');
      return;
    }
    
    print('🗺️ Actually adding ${favourites.length} favorites to map');
    
    final filteredFavourites = _applyFiltersToFavourites(favourites);
    
    final favouriteMarkers = filteredFavourites.map((favourite) {
      return Marker(
        markerId: MarkerId('fav_${favourite.id}'),
        position: LatLng(favourite.coordinates.latitude, favourite.coordinates.longitude),
        icon: _getMarkerIcon(favourite),
        infoWindow: InfoWindow(
          title: favourite.restaurantName,
          snippet: favourite.cuisineType ?? 'Restaurant',
          onTap: () => _showFavouriteDetails(favourite),
        ),
        onTap: () => _showFavouriteDetails(favourite),
      );
    }).toSet();
    
    // Update markers WITHOUT setState to avoid rebuild loop
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('fav_'));
    _markers.addAll(favouriteMarkers);
    
    // Force map refresh without triggering widget rebuild
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
    
    print('🗺️ ✅ Loaded ${favouriteMarkers.length} favorite markers');
  }

  List<Favourite> _applyFiltersToFavourites(List<Favourite> favourites) {
    return favourites.where((favourite) {
      // Rating filter (handle nullable rating)
      if (_minRating > 0.0 && (favourite.rating == null || favourite.rating! < _minRating)) return false;
      
      // Vegetarian filter
      if (_showVegOnly && !favourite.isVegetarianAvailable) return false;
      if (_showNonVegOnly && !favourite.isNonVegetarianAvailable) return false;
      
      // Category filter (using cuisineType instead of cuisine list)
      if (_selectedCategories.isNotEmpty && 
          (favourite.cuisineType == null || !_selectedCategories.contains(favourite.cuisineType))) {
        return false;
      }
      
      // Tag filter
      if (_selectedTags.isNotEmpty && 
          !_selectedTags.any((tag) => favourite.tags.contains(tag))) {
        return false;
      }
      
      // Distance filter (if location available)
      if (_currentLocation != null && _maxDistance < 50.0) {
        final distance = LocationService.calculateDistance(
          _currentLocation!,
          LatLng(favourite.coordinates.latitude, favourite.coordinates.longitude),
        );
        if (distance / 1000 > _maxDistance) return false;
      }
      return true;
    }).toList();
  }

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

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2 || _currentLocation == null) {
      _clearSearchResults();
      return;
    }

    setState(() => _isSearching = true);

    try {
      print('🔍 Enhanced search for "$query" near current location');
      
      final results = await _placesService.searchNearbyRestaurants(
        query: query,
        location: _currentLocation!,
        radius: (_maxDistance * 1000).toInt(), // Convert km to meters
      );
      
      final filteredResults = _applyFiltersToSearchResults(results);
      final sortedResults = SearchFilterUtils.sortSearchResults(results, _currentSort, _currentLocation);
      
      if (mounted) {
        setState(() {
          _searchResults = sortedResults;
          _isSearching = false;
        });
        
        _addSearchResultMarkers(sortedResults);
        
        if (sortedResults.isNotEmpty) {
          _showSnackBar('Found ${sortedResults.length} places');
        } else {
          _showSnackBar('No places found matching your criteria');
        }
      }
    } catch (e) {
      print('❌ Enhanced search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
        _showSnackBar('Search error: $e');
      }
    }
  }

  List<PlaceModel> _applyFiltersToSearchResults(List<PlaceModel> results) {
  return results.where((place) {
    // Rating filter (handle nullable rating)
    if (_minRating > 0.0 && (place.rating == null || place.rating! < _minRating)) return false;
    
    // Open only filter
    if (_showOpenOnly && !place.isOpen) return false;
    
    // 🔧 FIXED: Distance filter (if location available and distance filter is active)
    if (_currentLocation != null && _maxDistance < 50.0) {
      final distance = LocationService.calculateDistance(
        _currentLocation!,
        LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
      );
      // Convert meters to kilometers and compare
      if (distance / 1000 > _maxDistance) return false;
    }
    
    // TODO: Add these filters if PlaceModel supports them:
    // - Vegetarian/Non-Vegetarian filters
    // - Category filters
    // - Tag filters
    
    return true;
  }).toList();
}



  void _clearSearchResults() {
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _removeSearchMarkers();
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
        position: LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
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
      _removeSearchMarkers();
      _markers.addAll(searchMarkers);
    });
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedTags.clear();
      _minRating = 0.0;
      _maxDistance = 10.0;
      _showOpenOnly = false;
      _showVegOnly = false;
      _showNonVegOnly = false;
      _showFavoritesOnly = false;
      _selectedPriceRange = 'Any';
      _currentSort = SearchSortOption.relevance;
    });
    
    // Refresh results
    // _loadFavourites();
    if (_searchQuery.isNotEmpty) {
      _searchPlaces(_searchQuery);
    }
  }

  void _refreshResults() {
    _loadFavourites();
    if (_searchQuery.isNotEmpty) {
      _searchPlaces(_searchQuery);
    }
  }

  void _handleSortChange(SearchSortOption newSort) {
    setState(() => _currentSort = newSort);
    _refreshResults();
  }

  void _handleDistanceChange(double newDistance) {
    setState(() => _maxDistance = newDistance);
    _refreshResults();
  }

  void _handleQuickFiltersChange({
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    bool? showFavoritesOnly,
  }) {
    setState(() {
      if (showOpenOnly != null) _showOpenOnly = showOpenOnly;
      if (showVegOnly != null) _showVegOnly = showVegOnly;
      if (showNonVegOnly != null) _showNonVegOnly = showNonVegOnly;
      if (showFavoritesOnly != null) _showFavoritesOnly = showFavoritesOnly;
    });
    _refreshResults();
  }

  void _handleRatingChange(double newRating) {
    setState(() => _minRating = newRating);
    _refreshResults();
  }

  void _handleCategoriesChange(List<String> newCategories) {
    setState(() => _selectedCategories = newCategories);
    _refreshResults();
  }

  void _handleTagsChange(List<String> newTags) {
    setState(() => _selectedTags = newTags);
    _refreshResults();
  }

  void _handleActiveFilterRemove({
    double? minRating,
    double? maxDistance,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    SearchSortOption? currentSort,
    String? removeCategory,
    String? removeTag,
  }) {
    setState(() {
      if (minRating != null) _minRating = minRating;
      if (maxDistance != null) _maxDistance = maxDistance;
      if (showOpenOnly != null) _showOpenOnly = showOpenOnly;
      if (showVegOnly != null) _showVegOnly = showVegOnly;
      if (showNonVegOnly != null) _showNonVegOnly = showNonVegOnly;
      if (currentSort != null) _currentSort = currentSort;
      if (removeCategory != null) _selectedCategories.remove(removeCategory);
      if (removeTag != null) _selectedTags.remove(removeTag);
    });
    _refreshResults();
  }
  


  void _goToCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Always try to get fresh GPS location when button is pressed
    // Don't rely on cached status - check actual permissions and services
    
    _showSnackBar('Getting your current location...');
    
    // Request fresh current location (this will handle permissions internally)
    final success = await locationProvider.requestCurrentLocation(context);
    
    if (success && _mapController != null) {
      final newLocation = locationProvider.currentLocation!;
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15.0),
      );
      
      setState(() {
        _currentLocation = newLocation;
      });
      
      _showSnackBar('Location updated to your current position!');
    } else {
      // Error is already handled by the location provider with appropriate dialogs
      _showSnackBar('Unable to get current location');
    }
  }

  void _showFavouriteDetails(Favourite favourite) {
    setState(() => _selectedFavourite = favourite);
  }

  void _showAddFavouriteDialog(PlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFavouriteScreen(prefilledPlace: place),
      ),
    );
  }

  void _showLocationFallbackInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showSnackBar('Using estimated location. Tap location button for GPS.');
      }
    });
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print('✅ Enhanced search map created and ready');
    
    // ✅ ADD THIS: Load favorites when map becomes ready
    print('🗺️ Map ready, checking for favorites to load');
    final favProvider = Provider.of<FavouritesProvider>(context, listen: false);
    print('🗺️ Available favorites: ${favProvider.favourites.length}');
    
    if (favProvider.favourites.isNotEmpty) {
      print('🗺️ Loading favorites now that map is ready');
      _addFavouriteMarkers(favProvider.favourites);
    } else {
      print('🗺️ No favorites to load yet');
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Static GoogleMap (never rebuilds)
        _currentLocation == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                style: MapStyles.hideAllPois,
              ),

        // REPLACE all 3 Selectors with this single one:
        // NEW: Fixed Selector that prevents infinite loops
        Selector<FavouritesProvider, String>(
          selector: (context, provider) => 
            '${provider.favourites.length}_${_mapController != null}',  // ← Combined state
          builder: (context, state, child) {
            final parts = state.split('_');
            final favCount = int.parse(parts[0]);
            final mapReady = parts[1] == 'true';
            
            if (favCount > 0 && mapReady) {
              final existingMarkers = _markers.where((m) => m.markerId.value.startsWith('fav_')).length;
              
              if (existingMarkers == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final provider = Provider.of<FavouritesProvider>(context, listen: false);
                    _addFavouriteMarkers(provider.favourites);
                  }
                });
              }
            }
            
            return const SizedBox.shrink();
          },
        ),

        // ADD: Separate Selectors for loading and error states
        Selector<FavouritesProvider, bool>(
          selector: (context, provider) => provider.isLoading,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();
            
            return Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            );
          },
        ),

        Selector<FavouritesProvider, String?>(
          selector: (context, provider) => provider.errorMessage,
          builder: (context, error, child) {
            if (error == null) return const SizedBox.shrink();
            
            return Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Text(error, style: const TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        ),

        // All your existing static UI elements (these never rebuild)
        
        // Search Bar
        Positioned(
          top: 50,
          left: 16,
          right: 70,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _clearSearchResults();
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),

        // Filter Button
        Positioned(
          top: 50,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: "filter_button",
            onPressed: _toggleFilters,
            backgroundColor: _showFilters 
                ? Theme.of(context).primaryColor 
                : Colors.white,
            child: Icon(
              Icons.filter_list_rounded,
              color: _showFilters ? Colors.white : Colors.grey[600],
            ),
          ),
        ),

        // Location Button
        // Location Button with Status
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

        // Info/Legend Button (ADD THIS)
        Positioned(
          bottom: 40, // Position it below the location button
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

        // Add your existing filter panel, search results, etc.
        if (_showFilters) AnimatedFilterPanel(
                                              filterAnimation: _filterAnimation,
                                              showFilters: _showFilters,
                                              hasActiveFilters: _hasActiveFilters(),
                                              currentSort: _currentSort,
                                              minRating: _minRating,
                                              maxDistance: _maxDistance,
                                              showOpenOnly: _showOpenOnly,
                                              showVegOnly: _showVegOnly,
                                              showNonVegOnly: _showNonVegOnly,
                                              showFavoritesOnly: _showFavoritesOnly,
                                              selectedCategories: _selectedCategories,
                                              selectedTags: _selectedTags,
                                              onSortChanged: _handleSortChange,
                                              onRatingChanged: _handleRatingChange,
                                              onDistanceChanged: _handleDistanceChange,
                                              onQuickFiltersChanged: _handleQuickFiltersChange,
                                              onCategoriesChanged: _handleCategoriesChange,
                                              onTagsChanged: _handleTagsChange,
                                              onClearAll: _clearAllFilters,
                                            ),
        if (_searchResults.isNotEmpty) _buildSearchResultsList(),
        if (_selectedFavourite != null) 
            RestaurantInfoSheet(
              favourite: _selectedFavourite!,
              currentLocation: _currentLocation!,
              onNavigate: () {
                // Handle navigation
              },
              onClose: () {
                setState(() => _selectedFavourite = null);
              },
            ),
      ],
    ),
  );
}

  void _navigateToRestaurant(Favourite favourite) {
    // TODO: Implement navigation to restaurant
    _showSnackBar('Navigation feature coming soon!');
  }

  Widget _buildSearchBarAndFilters() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Search Bar with Filter Toggle
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants...',
                      prefixIcon: _isSearching 
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _clearSearchResults();
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Filter Toggle Button
                Container(
                  margin: const EdgeInsets.only(right: 8),
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
          
          // Active Filters Chips
          if (_hasActiveFilters()) ActiveFiltersRow(
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
        ],
      ),
    );
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

  Widget _buildSearchResultsList() {
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Results header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Search Results (${_searchResults.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _clearSearchResults,
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            
            // Results list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return SearchResultTileAdapter(
                    place: place,
                    isLast: index == _searchResults.length - 1,
                    currentLocation: _currentLocation,
                    onTap: () => _showAddFavouriteDialog(place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
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
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}