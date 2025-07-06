import 'package:flutter/material.dart';
import '../../enums/search/search_sort_option.dart';
import 'filter_content.dart';

class AnimatedFilterPanel extends StatelessWidget {
  final Animation<double> filterAnimation;
  final bool showFilters;
  final bool hasActiveFilters;
  
  // All filter state
  final SearchSortOption currentSort;
  final double minRating;
  final double maxDistance;
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;
  final bool showFavoritesOnly;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  
  // All callbacks
  final Function(SearchSortOption) onSortChanged;
  final Function(double) onRatingChanged;
  final Function(double) onDistanceChanged;
  final Function({
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    bool? showFavoritesOnly,
  }) onQuickFiltersChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function(List<String>) onTagsChanged;
  final VoidCallback onClearAll;

  const AnimatedFilterPanel({
    super.key,
    required this.filterAnimation,
    required this.showFilters,
    required this.hasActiveFilters,
    required this.currentSort,
    required this.minRating,
    required this.maxDistance,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.showFavoritesOnly,
    required this.selectedCategories,
    required this.selectedTags,
    required this.onSortChanged,
    required this.onRatingChanged,
    required this.onDistanceChanged,
    required this.onQuickFiltersChanged,
    required this.onCategoriesChanged,
    required this.onTagsChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filterAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 90 + 
               (hasActiveFilters ? 50 : 0),
          left: 16,
          right: 16,
          child: Container(
            height: filterAnimation.value * 400, // Max height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: showFilters
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: showFilters 
                ? FilterContent(
                    currentSort: currentSort,
                    minRating: minRating,
                    maxDistance: maxDistance,
                    showOpenOnly: showOpenOnly,
                    showVegOnly: showVegOnly,
                    showNonVegOnly: showNonVegOnly,
                    showFavoritesOnly: showFavoritesOnly,
                    selectedCategories: selectedCategories,
                    selectedTags: selectedTags,
                    onSortChanged: onSortChanged,
                    onRatingChanged: onRatingChanged,
                    onDistanceChanged: onDistanceChanged,
                    onQuickFiltersChanged: onQuickFiltersChanged,
                    onCategoriesChanged: onCategoriesChanged,
                    onTagsChanged: onTagsChanged,
                    onClearAll: onClearAll,
                  )
                : null,
          ),
        );
      },
    );
  }
}