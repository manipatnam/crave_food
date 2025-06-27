// Favourites Filter Service (Fixed)
// lib/services/favourites/favourites_filter_service.dart

import '../../models/favourite_model.dart';
import '../../screens/favorites/favourites_sort_options.dart';
import 'favourites_sort_service.dart';

class FavouritesFilterService {
  final FavouritesSortService _sortService = FavouritesSortService();

  List<Favourite> getFilteredAndSorted(
    List<Favourite> favourites,
    FilterCriteria filterCriteria,
    SortCriteria sortCriteria,
  ) {
    // Apply filters first
    List<Favourite> filtered = _applyFilters(favourites, filterCriteria);
    
    // Then apply sorting
    return _sortService.sortFavourites(filtered, sortCriteria);
  }

  List<Favourite> _applyFilters(
    List<Favourite> favourites,
    FilterCriteria criteria,
  ) {
    return favourites.where((favourite) {
      // Search query filter
      if (criteria.searchQuery.isNotEmpty) {
        final query = criteria.searchQuery.toLowerCase();
        final matchesName = favourite.restaurantName.toLowerCase().contains(query);
        final matchesNotes = (favourite.userNotes ?? '').toLowerCase().contains(query);
        final matchesFoodNames = favourite.foodNames.any((food) => 
            food.toLowerCase().contains(query));
        final matchesTags = favourite.tags.any((tag) => 
            tag.toLowerCase().contains(query));
        
        if (!matchesName && !matchesNotes && !matchesFoodNames && !matchesTags) {
          return false;
        }
      }

      // Category filter (using cuisineType)
      if (criteria.selectedCategories.isNotEmpty) {
        final cuisineType = favourite.cuisineType ?? '';
        if (!criteria.selectedCategories.contains(cuisineType)) {
          return false;
        }
      }

      // Tags filter
      if (criteria.selectedTags.isNotEmpty) {
        final hasMatchingTag = criteria.selectedTags.any((tag) => 
            favourite.tags.contains(tag));
        if (!hasMatchingTag) {
          return false;
        }
      }

      // Rating filter
      if (criteria.minRating > 0) {
        final rating = favourite.rating ?? 0.0;
        if (rating < criteria.minRating) {
          return false;
        }
      }

      // Dietary filters
      if (criteria.showVegOnly && criteria.showNonVegOnly) {
        // If both are selected, show all
      } else if (criteria.showVegOnly) {
        if (!favourite.isVegetarianAvailable) {
          return false;
        }
      } else if (criteria.showNonVegOnly) {
        if (!favourite.isNonVegetarianAvailable) {
          return false;
        }
      }

      // Open only filter
      if (criteria.showOpenOnly) {
        if (favourite.isOpen != true) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> getAllCategories(List<Favourite> favourites) {
    return favourites
        .map((f) => f.cuisineType ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> getAllTags(List<Favourite> favourites) {
    return favourites
        .expand((f) => f.tags)
        .toSet()
        .toList()
        ..sort();
  }
}