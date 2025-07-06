import 'package:flutter/material.dart';
import '../../enums/search/search_sort_option.dart';
import 'active_filter_chip.dart';

class ActiveFiltersRow extends StatelessWidget {
  final double minRating;
  final double maxDistance;
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;
  final SearchSortOption currentSort;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final Function({
    double? minRating,
    double? maxDistance,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    SearchSortOption? currentSort,
    String? removeCategory,
    String? removeTag,
  }) onFilterRemoved;
  final VoidCallback onUpdate;

  const ActiveFiltersRow({
    super.key,
    required this.minRating,
    required this.maxDistance,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.currentSort,
    required this.selectedCategories,
    required this.selectedTags,
    required this.onFilterRemoved,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final activeFilters = <Widget>[];
    
    if (minRating > 0.0) {
      activeFilters.add(ActiveFilterChip(
        label: 'Rating: ${minRating.toStringAsFixed(1)}+',
        onRemove: () => onFilterRemoved(minRating: 0.0),
        onUpdate: onUpdate,
      ));
    }
    
    if (maxDistance < 50.0) {
      activeFilters.add(ActiveFilterChip(
        label: 'Distance: ${maxDistance.toInt()}km',
        onRemove: () => onFilterRemoved(maxDistance: 50.0),
        onUpdate: onUpdate,
      ));
    }
    
    if (showOpenOnly) {
      activeFilters.add(ActiveFilterChip(
        label: 'Open Now',
        onRemove: () => onFilterRemoved(showOpenOnly: false),
        onUpdate: onUpdate,
      ));
    }
    
    if (showVegOnly) {
      activeFilters.add(ActiveFilterChip(
        label: 'Vegetarian',
        onRemove: () => onFilterRemoved(showVegOnly: false),
        onUpdate: onUpdate,
      ));
    }
    
    if (showNonVegOnly) {
      activeFilters.add(ActiveFilterChip(
        label: 'Non-Vegetarian',
        onRemove: () => onFilterRemoved(showNonVegOnly: false),
        onUpdate: onUpdate,
      ));
    }
    
    if (currentSort != SearchSortOption.relevance) {
      activeFilters.add(ActiveFilterChip(
        label: 'Sort: ${currentSort.label}',
        onRemove: () => onFilterRemoved(currentSort: SearchSortOption.relevance),
        onUpdate: onUpdate,
      ));
    }
    
    for (final category in selectedCategories) {
      activeFilters.add(ActiveFilterChip(
        label: category,
        onRemove: () => onFilterRemoved(removeCategory: category),
        onUpdate: onUpdate,
      ));
    }
    
    for (final tag in selectedTags) {
      activeFilters.add(ActiveFilterChip(
        label: '#$tag',
        onRemove: () => onFilterRemoved(removeTag: tag),
        onUpdate: onUpdate,
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
}