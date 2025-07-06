import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favourites_provider.dart';
import '../../utils/search/search_filter_utils.dart';
import '../../enums/search/search_sort_option.dart';
import 'sort_section.dart';
import 'rating_filter.dart';
import 'distance_filter.dart';
import 'quick_filters.dart';
import 'categories_filter.dart';
import 'tags_filter.dart';

class FilterContent extends StatelessWidget {
  // All the current filter state
  final SearchSortOption currentSort;
  final double minRating;
  final double maxDistance;
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;
  final bool showFavoritesOnly;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  
  // All the callback functions
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

  const FilterContent({
    super.key,
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
    final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
    final categories = SearchFilterUtils.getAllCategories(favouritesProvider.favourites);
    final tags = SearchFilterUtils.getAllTags(favouritesProvider.favourites);
    
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
                onPressed: onClearAll,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sort Options
          SortSection(
            currentSort: currentSort,
            onSortChanged: onSortChanged,
          ),
          const SizedBox(height: 16),
          
          // Rating Filter
          RatingFilter(
            minRating: minRating,
            onRatingChanged: onRatingChanged,
          ),
          const SizedBox(height: 16),
          
          // Distance Filter
          DistanceFilter(
            maxDistance: maxDistance,
            onDistanceChanged: onDistanceChanged,
          ),
          const SizedBox(height: 16),
          
          // Quick Filters
          QuickFilters(
            showOpenOnly: showOpenOnly,
            showVegOnly: showVegOnly,
            showNonVegOnly: showNonVegOnly,
            showFavoritesOnly: showFavoritesOnly,
            onFiltersChanged: onQuickFiltersChanged,
          ),
          const SizedBox(height: 16),
          
          // Categories
          if (categories.isNotEmpty) CategoriesFilter(
            categories: categories,
            selectedCategories: selectedCategories,
            onCategoriesChanged: onCategoriesChanged,
          ),
          if (categories.isNotEmpty) const SizedBox(height: 16),
          
          // Tags
          if (tags.isNotEmpty) TagsFilter(
            tags: tags,
            selectedTags: selectedTags,
            onTagsChanged: onTagsChanged,
          ),
        ],
      ),
    );
  }
}