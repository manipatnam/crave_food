// lib/screens/favorites/favourites_sort_options.dart
// Fixed sort options with proper enum syntax and visit status

import '../../models/visit_status.dart';

enum SortOption {
  dateAdded('Date Added'),
  restaurantName('Name A-Z'),
  rating('Highest Rating'),
  category('Category'),
  distance('Distance'),
  visitStatus('Visit Status'); // NEW

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
  final List<VisitStatus> selectedVisitStatus; // NEW

  const FilterCriteria({
    required this.searchQuery,
    required this.selectedCategories,
    required this.selectedTags,
    required this.minRating,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
    this.selectedVisitStatus = const [], // NEW
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedTags.isNotEmpty ||
      minRating > 0.0 ||
      showOpenOnly ||
      showVegOnly ||
      showNonVegOnly ||
      selectedVisitStatus.isNotEmpty; // NEW

  // NEW: Copy with method for updating filters
  FilterCriteria copyWith({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    double? minRating,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    List<VisitStatus>? selectedVisitStatus,
  }) {
    return FilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTags: selectedTags ?? this.selectedTags,
      minRating: minRating ?? this.minRating,
      showOpenOnly: showOpenOnly ?? this.showOpenOnly,
      showVegOnly: showVegOnly ?? this.showVegOnly,
      showNonVegOnly: showNonVegOnly ?? this.showNonVegOnly,
      selectedVisitStatus: selectedVisitStatus ?? this.selectedVisitStatus,
    );
  }
}

class SortCriteria {
  final SortOption sortOption;
  final dynamic currentLocation;

  const SortCriteria({
    required this.sortOption,
    this.currentLocation,
  });
}