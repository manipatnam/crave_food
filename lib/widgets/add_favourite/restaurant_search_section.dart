import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../widgets/custom_text_field.dart';

class RestaurantSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final List<PlaceModel> searchResults;
  final bool isSearching;
  final PlaceModel? selectedPlace;
  final Function(String) onSearch;
  final Function(PlaceModel) onSelectPlace;

  const RestaurantSearchSection({
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search Restaurant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: controller,
            hintText: 'Search for a restaurant...',
            prefixIcon: Icons.search,
            onChanged: onSearch,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a restaurant';
              }
              if (selectedPlace == null) {
                return 'Please select a restaurant from the search results';
              }
              return null;
            },
          ),
          
          // Search Results
          if (isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Searching restaurants...'),
                  ],
                ),
              ),
            )
          else if (searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: searchResults.map((place) => _buildSearchResultTile(context, place)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(BuildContext context, PlaceModel place) {
    return SearchResultTileAdapter(
      place: place,
      isLast: false,
      currentLocation: null, // Pass current location
      onTap: () => onPlaceSelected(place),
    );
  }
}