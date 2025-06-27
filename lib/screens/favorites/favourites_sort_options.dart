// Sort and Filter Options for Enhanced Favorites
// lib/screens/favorites/favourites_sort_options.dart

enum SortOption {
  dateAdded('Date Added'),
  restaurantName('Name A-Z'),
  rating('Highest Rating'),
  category('Category'),
  distance('Distance');

  const SortOption(this.label);
  final String label;
}

class FilterCriteria {
  final String searchQuery;
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final double minRating;
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;

  const FilterCriteria({
    required this.searchQuery,
    required this.selectedCategories,
    required this.selectedTags,
    required this.minRating,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedTags.isNotEmpty ||
      minRating > 0.0 ||
      showOpenOnly ||
      showVegOnly ||
      showNonVegOnly;
}

class SortCriteria {
  final SortOption sortOption;
  final dynamic currentLocation;

  const SortCriteria({
    required this.sortOption,
    this.currentLocation,
  });
}