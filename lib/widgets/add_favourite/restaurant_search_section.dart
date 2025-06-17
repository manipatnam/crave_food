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
    return Container(
      margin: const EdgeInsets.all(4),
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
        onTap: () => onSelectPlace(place),
      ),
    );
  }
}