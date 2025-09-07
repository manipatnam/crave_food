// lib/widgets/add_review/selected_restaurant_card.dart

import 'package:flutter/material.dart';
import '../../models/place_model.dart';

class SelectedRestaurantCard extends StatelessWidget {
  final PlaceModel selectedPlace;
  final VoidCallback onClear;

  const SelectedRestaurantCard({
    super.key,
    required this.selectedPlace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Restaurant Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Restaurant Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Label
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selected Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Restaurant Name
                Text(
                  selectedPlace.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Restaurant Address
                if (selectedPlace.displayAddress.isNotEmpty)
                  Text(
                    selectedPlace.displayAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 6),
                
                // Restaurant Info (Rating & Cuisine)
                if (selectedPlace.rating != null || selectedPlace.cuisineTypes.isNotEmpty)
                  Row(
                    children: [
                      // Rating
                      if (selectedPlace.rating != null) ...[
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          selectedPlace.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (selectedPlace.userRatingsTotal != null)
                          Text(
                            ' (${selectedPlace.userRatingsTotal})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                      
                      // Separator
                      if (selectedPlace.rating != null && selectedPlace.cuisineTypes.isNotEmpty)
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      
                      // Cuisine Types
                      if (selectedPlace.cuisineTypes.isNotEmpty)
                        Expanded(
                          child: Text(
                            selectedPlace.cuisineTypes,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                
                // Price Level
                if (selectedPlace.priceLevel != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      selectedPlace.priceLevel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Clear Button
          IconButton(
            onPressed: onClear,
            icon: Icon(
              Icons.close,
              color: Colors.grey[600],
            ),
            tooltip: 'Remove restaurant',
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}