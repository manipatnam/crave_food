// Search Results Screen
// lib/screens/search/search_results_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/place_model.dart';
import '../../models/search/recent_search_model.dart';
import '../../services/search/recent_search_service.dart';
import '../../services/google_places_services.dart';
import '../../widgets/search/search_result_tiles.dart';

class SearchResultsScreen extends StatefulWidget {
  final double? currentLatitude;
  final double? currentLongitude;

  const SearchResultsScreen({
    super.key,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecentSearchService _recentSearchService = RecentSearchService.instance;
  final GooglePlacesService _placesService = GooglePlacesService();
  
  List<RecentSearch> _recentSearches = [];
  List<PlaceModel> _liveSearchResults = [];
  bool _isSearching = false;
  bool _showLiveResults = false;
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _showLiveResults = false;
        _liveSearchResults.clear();
        _isSearching = false;
      });
      return;
    }

    // Cancel previous search
    _searchDebouncer?.cancel();
    
    setState(() {
      _isSearching = true;
    });

    // Debounce search (500ms delay)
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      _performLiveSearch(query);
    });
  }

  Future<void> _loadRecentSearches() async {
    try {
      List<RecentSearch> searches;
      
      if (widget.currentLatitude != null && widget.currentLongitude != null) {
        // Load recent searches sorted by distance
        searches = await _recentSearchService.getRecentSearchesByDistance(
          widget.currentLatitude,
          widget.currentLongitude,
        );
      } else {
        // Load recent searches sorted by recency
        searches = await _recentSearchService.getRecentSearches();
      }
      
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _performLiveSearch(String query) async {
    try {
      final results = await _placesService.searchPlaces(query);

      // Sort results by distance if location is available
      if (widget.currentLatitude != null && widget.currentLongitude != null) {
        results.sort((a, b) {
          final distanceA = _calculateDistance(
            widget.currentLatitude!,
            widget.currentLongitude!,
            a.geoPoint.latitude,
            a.geoPoint.longitude,
          );
          final distanceB = _calculateDistance(
            widget.currentLatitude!,
            widget.currentLongitude!,
            b.geoPoint.latitude,
            b.geoPoint.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      setState(() {
        _liveSearchResults = results;
        _showLiveResults = true;
        _isSearching = false;
      });
    } catch (e) {
      print('Error performing live search: $e');
      setState(() {
        _showLiveResults = true;
        _isSearching = false;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double latDiff = _degreesToRadians(lat2 - lat1);
    double lonDiff = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(lonDiff / 2) * math.sin(lonDiff / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  Future<void> _onPlaceSelected(PlaceModel place) async {
    // Add to recent searches
    await _recentSearchService.addRecentSearch(place);
    
    // Return to map screen with selected place
    Navigator.pop(context, place);
  }

  Future<void> _onRecentSearchSelected(RecentSearch recentSearch) async {
    // Convert to PlaceModel and select
    final place = recentSearch.toPlaceModel();
    await _onPlaceSelected(place);
  }

  Future<void> _clearAllRecentSearches() async {
    await _recentSearchService.clearRecentSearches();
    setState(() {
      _recentSearches.clear();
    });
  }

  Future<void> _removeRecentSearch(String searchId) async {
    await _recentSearchService.removeRecentSearch(searchId);
    setState(() {
      _recentSearches.removeWhere((search) => search.id == searchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for restaurants...',
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
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showLiveResults = false;
                          _liveSearchResults.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_showLiveResults) {
      return _buildLiveSearchResults();
    } else {
      return _buildRecentSearches();
    }
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const SearchEmptyState(
        message: 'No recent searches',
        subtitle: 'Start searching for restaurants to see your history here',
        icon: Icons.history,
      );
    }

    return Column(
      children: [
        // Header
        SearchSectionHeader(
          title: 'Recent',
          onClearAll: _clearAllRecentSearches,
        ),
        
        // Recent searches list
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final recentSearch = _recentSearches[index];
              final distanceText = widget.currentLatitude != null && widget.currentLongitude != null
                  ? recentSearch.getFormattedDistance(widget.currentLatitude, widget.currentLongitude)
                  : null;
              
              return RecentSearchTile(
                recentSearch: recentSearch,
                distanceText: distanceText,
                onTap: () => _onRecentSearchSelected(recentSearch),
                onRemove: () => _removeRecentSearch(recentSearch.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSearchResults() {
    if (_liveSearchResults.isEmpty) {
      return SearchEmptyState(
        message: 'No places found for "${_searchController.text}"',
        subtitle: 'Try searching with different keywords',
        icon: Icons.search_off,
      );
    }

    return Column(
      children: [
        // Header
        SearchSectionHeader(
          title: 'Places',
          subtitle: '${_liveSearchResults.length} results found',
        ),
        
        // Live search results list
        Expanded(
          child: ListView.builder(
            itemCount: _liveSearchResults.length,
            itemBuilder: (context, index) {
              final place = _liveSearchResults[index];
              String? distanceText;
              
              if (widget.currentLatitude != null && widget.currentLongitude != null) {
                final distance = _calculateDistance(
                  widget.currentLatitude!,
                  widget.currentLongitude!,
                  place.geoPoint.latitude,
                  place.geoPoint.longitude,
                );
                distanceText = _formatDistance(distance);
              }
              
              return LiveSearchTile(
                place: place,
                distanceText: distanceText,
                onTap: () => _onPlaceSelected(place),
              );
            },
          ),
        ),
      ],
    );
  }
}