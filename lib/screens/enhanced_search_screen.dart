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

// Sort and Filter Options for Search
enum SearchSortOption {
  relevance('Relevance'),
  distance('Distance'),
  rating('Highest Rating'),
  name('Name A-Z'),
  popularity('Popularity');

  const SearchSortOption(this.label);
  final String label;
}

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
  String _locationDisplayName = 'Detecting location...';
  bool _isLocationFromGPS = false;
  bool _isLocationFromIP = false;
  bool _isLoadingLocation = true;
  
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
    // _loadFavourites();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _filterAnimationController.dispose();
    _searchDebouncer?.cancel();
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
    print('🗺️ Initializing enhanced search map...');
    
    try {
      final hasPermission = await LocationService.hasLocationPermission();
      
      if (!hasPermission && mounted) {
        final shouldRequestPermission = await LocationService.showLocationPermissionDialog(context);
        if (shouldRequestPermission) {
          await LocationService.requestLocationPermission();
        }
      }
      
      final location = await LocationService.getLocationWithFallback();
      
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
          _locationDisplayName = LocationService.getLocationDisplayName(location);
        });
        
        final gpsLocation = await LocationService.getCurrentLocation();
        if (gpsLocation != null) {
          _isLocationFromGPS = true;
          print('✅ Enhanced search map initialized with GPS location');
        } else {
          _isLocationFromIP = true;
          print('✅ Enhanced search map initialized with fallback location');
          _showLocationFallbackInfo();
        }
      }
    } catch (e) {
      print('❌ Error initializing enhanced search map: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationDisplayName = 'Location unavailable';
        });
        _showSnackBar('Error detecting location. Please enable location services.');
      }
    }
  }

  void _loadFavourites() {
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    _addFavouriteMarkers(favouritesProvider.favourites);
  }

  void _addFavouriteMarkers(List<Favourite> favourites) {
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
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('fav_'));
      _markers.addAll(favouriteMarkers);
    });
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
      final sortedResults = _sortSearchResults(filteredResults);
      
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

  List<PlaceModel> _sortSearchResults(List<PlaceModel> results) {
    switch (_currentSort) {
      case SearchSortOption.distance:
        if (_currentLocation != null) {
          results.sort((a, b) {
            final distanceA = LocationService.calculateDistance(
              _currentLocation!,
              LatLng(a.geoPoint.latitude, a.geoPoint.longitude),
            );
            final distanceB = LocationService.calculateDistance(
              _currentLocation!,
              LatLng(b.geoPoint.latitude, b.geoPoint.longitude),
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case SearchSortOption.rating:
        results.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case SearchSortOption.name:
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SearchSortOption.popularity:
        // Sort by rating * review count as a proxy for popularity
        results.sort((a, b) {
          final popularityA = (a.rating ?? 0.0) * (a.userRatingsTotal ?? 0);
          final popularityB = (b.rating ?? 0.0) * (b.userRatingsTotal ?? 0);
          return popularityB.compareTo(popularityA);
        });
        break;
      case SearchSortOption.relevance:
      default:
        // Keep original order (Google's relevance)
        break;
    }
    return results;
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

  List<String> _getAllCategories() {
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    final categories = <String>{};
    for (final fav in favouritesProvider.favourites) {
      if (fav.cuisineType != null && fav.cuisineType!.isNotEmpty) {
        categories.add(fav.cuisineType!);
      }
    }
    return categories.toList()..sort();
  }

  List<String> _getAllTags() {
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    final tags = <String>{};
    for (final fav in favouritesProvider.favourites) {
      tags.addAll(fav.tags);
    }
    return tags.toList()..sort();
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
              ),

        // Hybrid Consumer 1: Only updates when favorites list changes
        Selector<FavouritesProvider, List<Favourite>>(
          selector: (context, provider) => provider.favourites,
          builder: (context, favourites, child) {
            print('🔄 Favorites changed: ${favourites.length} favorites');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _addFavouriteMarkers(favourites);
              }
            });
            return const SizedBox.shrink(); // Invisible widget
          },
        ),

        // Hybrid Consumer 2: Only updates when loading state changes
        Selector<FavouritesProvider, bool>(
          selector: (context, provider) => provider.isLoading,
          builder: (context, isLoading, child) {
            print('🔄 Loading state changed: $isLoading');
            return isLoading
                ? Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading your favorites...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),

        // Hybrid Consumer 3: Only updates when error state changes
        Selector<FavouritesProvider, String?>(
          selector: (context, provider) => provider.errorMessage,
          builder: (context, errorMessage, child) {
            print('🔄 Error state changed: $errorMessage');
            return errorMessage != null
                ? Positioned(
                    top: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Provider.of<FavouritesProvider>(context, listen: false)
                                  .clearError();
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
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
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: "location_button",
            onPressed: _goToCurrentLocation,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.my_location_rounded,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Add your existing filter panel, search results, etc.
        if (_showFilters) _buildFilterPanel(),
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
          if (_hasActiveFilters()) _buildActiveFiltersChips(),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 90 + 
               (_hasActiveFilters() ? 50 : 0),
          left: 16,
          right: 16,
          child: Container(
            height: _filterAnimation.value * 400, // Max height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _showFilters
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: _showFilters ? _buildFilterContent() : null,
          ),
        );
      },
    );
  }

  Widget _buildFilterContent() {
    final categories = _getAllCategories();
    final tags = _getAllTags();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters & Sort',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sort Options
          _buildSortSection(),
          const SizedBox(height: 16),
          
          // Rating Filter
          _buildRatingFilter(),
          const SizedBox(height: 16),
          
          // Distance Filter
          _buildDistanceFilter(),
          const SizedBox(height: 16),
          
          // Quick Filters
          _buildQuickFilters(),
          const SizedBox(height: 16),
          
          // Categories
          if (categories.isNotEmpty) _buildCategoriesFilter(categories),
          if (categories.isNotEmpty) const SizedBox(height: 16),
          
          // Tags
          if (tags.isNotEmpty) _buildTagsFilter(tags),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SearchSortOption.values.map((option) {
            final isSelected = _currentSort == option;
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _currentSort = option);
                  // Re-apply search if active
                  if (_searchQuery.isNotEmpty) {
                    _searchPlaces(_searchQuery);
                  }
                  _loadFavourites();
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _minRating,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                label: _minRating == 0.0 ? 'Any' : _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _minRating = value);
                  // _loadFavourites();
                  if (_searchQuery.isNotEmpty) {
                    _searchPlaces(_searchQuery);
                  }
                },
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                _minRating == 0.0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Distance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _maxDistance,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: _maxDistance >= 50.0 ? 'Any' : '${_maxDistance.toInt()} km',
                onChanged: (value) {
                  setState(() => _maxDistance = value);
                  // _loadFavourites();
                  if (_searchQuery.isNotEmpty) {
                    _searchPlaces(_searchQuery);
                  }
                },
              ),
            ),
            Container(
              width: 80,
              alignment: Alignment.center,
              child: Text(
                _maxDistance >= 50.0 ? 'Any distance' : '${_maxDistance.toInt()} km',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Open Now'),
              selected: _showOpenOnly,
              onSelected: (selected) {
                setState(() => _showOpenOnly = selected);
                if (_searchQuery.isNotEmpty) {
                  _searchPlaces(_searchQuery);
                }
              },
            ),
            FilterChip(
              label: const Text('Vegetarian'),
              selected: _showVegOnly,
              onSelected: (selected) {
                setState(() {
                  _showVegOnly = selected;
                  if (selected) _showNonVegOnly = false;
                });
                _loadFavourites();
              },
            ),
            FilterChip(
              label: const Text('Non-Vegetarian'),
              selected: _showNonVegOnly,
              onSelected: (selected) {
                setState(() {
                  _showNonVegOnly = selected;
                  if (selected) _showVegOnly = false;
                });
                _loadFavourites();
              },
            ),
            FilterChip(
              label: const Text('Favorites Only'),
              selected: _showFavoritesOnly,
              onSelected: (selected) {
                setState(() => _showFavoritesOnly = selected);
                // TODO: Implement favorites-only filtering
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine Types',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
                // _loadFavourites();
                if (_searchQuery.isNotEmpty) {
                  _searchPlaces(_searchQuery);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsFilter(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                _loadFavourites();
                if (_searchQuery.isNotEmpty) {
                  _searchPlaces(_searchQuery);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
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

  Widget _buildActiveFiltersChips() {
    final activeFilters = <Widget>[];
    
    if (_minRating > 0.0) {
      activeFilters.add(_buildActiveFilterChip(
        'Rating: ${_minRating.toStringAsFixed(1)}+',
        () => setState(() => _minRating = 0.0),
      ));
    }
    
    if (_maxDistance < 50.0) {
      activeFilters.add(_buildActiveFilterChip(
        'Distance: ${_maxDistance.toInt()}km',
        () => setState(() => _maxDistance = 50.0),
      ));
    }
    
    if (_showOpenOnly) {
      activeFilters.add(_buildActiveFilterChip(
        'Open Now',
        () => setState(() => _showOpenOnly = false),
      ));
    }
    
    if (_showVegOnly) {
      activeFilters.add(_buildActiveFilterChip(
        'Vegetarian',
        () => setState(() => _showVegOnly = false),
      ));
    }
    
    if (_showNonVegOnly) {
      activeFilters.add(_buildActiveFilterChip(
        'Non-Vegetarian',
        () => setState(() => _showNonVegOnly = false),
      ));
    }
    
    if (_currentSort != SearchSortOption.relevance) {
      activeFilters.add(_buildActiveFilterChip(
        'Sort: ${_currentSort.label}',
        () => setState(() => _currentSort = SearchSortOption.relevance),
      ));
    }
    
    for (final category in _selectedCategories) {
      activeFilters.add(_buildActiveFilterChip(
        category,
        () => setState(() => _selectedCategories.remove(category)),
      ));
    }
    
    for (final tag in _selectedTags) {
      activeFilters.add(_buildActiveFilterChip(
        '#$tag',
        () => setState(() => _selectedTags.remove(tag)),
      ));
    }
    
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...activeFilters.map((chip) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: chip,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: () {
        onRemove();
        _loadFavourites();
        if (_searchQuery.isNotEmpty) {
          _searchPlaces(_searchQuery);
        }
      },
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
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
                  return _buildSearchResultTile(place, index == _searchResults.length - 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(PlaceModel place, bool isLast) {
    final distance = _currentLocation != null 
        ? LocationService.calculateDistance(
            _currentLocation!,
            LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
          )
        : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => _showAddFavouriteDialog(place),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.displayAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                place.displayAddress,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (place.rating != null && place.rating! > 0) ...[
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_currentLocation != null) ...[
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showAddFavouriteDialog(place),
          icon: Icon(
            Icons.add_circle_rounded,
            color: Theme.of(context).primaryColor,
          ),
          tooltip: 'Add to Favorites',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tip: Use filters to narrow down results and find exactly what you\'re looking for!',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(color: Theme.of(context).primaryColor),
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