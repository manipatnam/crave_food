// Favorites Sort Modal Widget
// lib/widgets/favourites/favorites_sort_modal.dart

import 'package:flutter/material.dart';
import '../../screens/favorites/favourites_sort_options.dart';

class FavoritesSortModal extends StatelessWidget {
  final SortOption currentSort;
  final dynamic currentLocation;
  final bool isLoadingLocation;
  final Function(SortOption) onSortChanged;

  const FavoritesSortModal({
    super.key,
    required this.currentSort,
    this.currentLocation,
    required this.isLoadingLocation,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...SortOption.values.map((option) => 
                  ListTile(
                    leading: Icon(
                      _getSortIcon(option),
                      color: currentSort == option 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[600],
                    ),
                    title: Text(option.label),
                    subtitle: option == SortOption.distance && currentLocation == null
                        ? Text(
                            isLoadingLocation ? 'Getting location...' : 'Location required',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: currentSort == option 
                        ? Icon(
                            Icons.check_rounded,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                    enabled: option != SortOption.distance || currentLocation != null,
                    onTap: () {
                      onSortChanged(option);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: currentSort == option 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                  ),
                ).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.dateAdded:
        return Icons.access_time_rounded;
      case SortOption.restaurantName:
        return Icons.sort_by_alpha_rounded;
      case SortOption.rating:
        return Icons.star_rounded;
      case SortOption.category:
        return Icons.category_rounded;
      case SortOption.distance:
        return Icons.near_me_rounded;
      case SortOption.visitStatus: // ADD this case
        return Icons.checklist;
    }
  }
}