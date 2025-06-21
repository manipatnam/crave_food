// Place Search Section Widget (updated from Restaurant Search)
// lib/widgets/add_favourite/place_search_section.dart

import 'package:flutter/material.dart';
import '../../models/place_model.dart';

class PlaceSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final List<PlaceModel> searchResults;
  final bool isSearching;
  final PlaceModel? selectedPlace;
  final Function(String) onSearch;
  final Function(PlaceModel) onSelectPlace;

  const PlaceSearchSection({
    super.key,
    required this.controller,
    required this.searchResults,
    required this.isSearching,
    required this.selectedPlace,
    required this.onSearch,
    required this.onSelectPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Search for a Place',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Find restaurants, cafes, museums, parks, or any place you want to save',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        // Search field
        TextFormField(
          controller: controller,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search for places...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          validator: (value) {
            if (selectedPlace == null) {
              return 'Please select a place from search results';
            }
            return null;
          },
        ),
        
        // Search results
        if (searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Search Results (${searchResults.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final place = searchResults[index];
                      return _buildPlaceResultItem(context, place);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Search helper text
        if (controller.text.isNotEmpty && searchResults.isEmpty && !isSearching && selectedPlace == null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No places found. Try a different search term.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceResultItem(BuildContext context, PlaceModel place) {
    return InkWell(
      onTap: () => onSelectPlace(place),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Place icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPlaceIcon(place.types),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Place details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.displayAddress.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      place.displayAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (place.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber[600],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (place.userRatingsTotal != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${place.userRatingsTotal})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Select indicator
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlaceIcon(List<String>? types) {
    if (types == null || types.isEmpty) return Icons.place_rounded;
    
    // Check for food-related types
    if (types.any((type) => [
      'restaurant', 'food', 'meal_takeaway', 'meal_delivery',
      'cafe', 'bakery', 'bar', 'night_club'
    ].contains(type))) {
      return Icons.restaurant_rounded;
    }
    
    // Check for accommodation
    if (types.any((type) => ['lodging', 'hotel'].contains(type))) {
      return Icons.hotel_rounded;
    }
    
    // Check for shopping
    if (types.any((type) => [
      'store', 'shopping_mall', 'clothing_store', 'grocery_or_supermarket'
    ].contains(type))) {
      return Icons.shopping_bag_rounded;
    }
    
    // Check for entertainment
    if (types.any((type) => [
      'amusement_park', 'movie_theater', 'casino', 'bowling_alley'
    ].contains(type))) {
      return Icons.theater_comedy_rounded;
    }
    
    // Check for activities
    if (types.any((type) => [
      'tourist_attraction', 'museum', 'park', 'zoo', 'aquarium'
    ].contains(type))) {
      return Icons.local_activity_rounded;
    }
    
    return Icons.place_rounded;
  }
}