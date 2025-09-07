// lib/widgets/add_review/restaurant_search_section.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/google_places_services.dart';
import '../../models/place_model.dart';

class RestaurantSearchSection extends StatefulWidget {
  final PlaceModel? selectedPlace;
  final Function(PlaceModel?) onPlaceSelected;
  final GooglePlacesService placesService;

  const RestaurantSearchSection({
    super.key,
    required this.selectedPlace,
    required this.onPlaceSelected,
    required this.placesService,
  });

  @override
  State<RestaurantSearchSection> createState() => _RestaurantSearchSectionState();
}

class _RestaurantSearchSectionState extends State<RestaurantSearchSection> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<PlaceModel> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Select Restaurant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Search Input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _searchFocusNode.hasFocus ? Colors.orange : Colors.grey[300]!,
              width: _searchFocusNode.hasFocus ? 2 : 1,
            ),
            color: Colors.grey[50],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search for restaurants...',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _searchFocusNode.hasFocus ? Colors.orange : Colors.grey[600],
              ),
              suffixIcon: _isSearching
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        
        // Search Results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Search Results',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_searchResults.length} found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return _buildSearchResultTile(place);
                  },
                ),
              ],
            ),
          ),
        ],
        
        // Search State Messages
        if (_isSearching && _searchResults.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                const SizedBox(height: 8),
                Text(
                  'Searching restaurants...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (!_isSearching && _searchResults.isEmpty && _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: Colors.grey[500],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No restaurants found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Try searching with a different name or location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultTile(PlaceModel place) {
    return ListTile(
      onTap: () => _selectPlace(place),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant,
          color: Colors.orange,
          size: 24,
        ),
      ),
      title: Text(
        place.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.displayAddress.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              place.displayAddress,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (place.rating != null || place.cuisineTypes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (place.rating != null) ...[
                  Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
                if (place.rating != null && place.cuisineTypes.isNotEmpty)
                  const Text(' • ', style: TextStyle(fontSize: 11)),
                if (place.cuisineTypes.isNotEmpty)
                  Expanded(
                    child: Text(
                      place.cuisineTypes,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _lastQuery = query;
    });

    // Debounce search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_lastQuery == query && query.isNotEmpty) {
        _performSearch(query);
      } else if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.placesService.searchPlaces(query);
      
      // Only update if this is still the current query
      if (_lastQuery == query && mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching restaurants: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPlace(PlaceModel place) {
    setState(() {
      _searchResults.clear();
      _searchController.clear();
    });
    
    // Hide keyboard
    _searchFocusNode.unfocus();
    
    // Notify parent
    widget.onPlaceSelected(place);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _lastQuery = '';
    });
    _debounceTimer?.cancel();
  }
}