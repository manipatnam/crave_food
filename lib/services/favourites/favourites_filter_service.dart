// Favourites Filter Service (Fixed)
// lib/services/favourites/favourites_filter_service.dart

import '../../models/favourite_model.dart';
import '../../screens/favorites/favourites_sort_options.dart';
import 'favourites_sort_service.dart';
import '../../models/favourite_model.dart';
import '../../models/visit_status.dart';
import '../../screens/favorites/favourites_sort_options.dart';

class FavouritesFilterService {
  final FavouritesSortService _sortService = FavouritesSortService();

  List<Favourite> getFilteredAndSorted(
    List<Favourite> favourites,
    FilterCriteria filterCriteria,
    SortCriteria sortCriteria,
  ) {
    // Apply filters first
    List<Favourite> filtered = applyFilters(favourites, filterCriteria);
    
    // Then apply sorting
    return _sortService.sortFavourites(filtered, sortCriteria);
  }

  List<Favourite> applyFilters(
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

      // NEW: Visit Status filter
      if (criteria.selectedVisitStatus.isNotEmpty) {
        if (!criteria.selectedVisitStatus.contains(favourite.visitStatus)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Map<VisitStatus, int> getVisitStatusCounts(List<Favourite> favourites) {
    final counts = <VisitStatus, int>{};
    
    for (final status in VisitStatus.values) {
      counts[status] = favourites.where((f) => f.visitStatus == status).length;
    }
    
    return counts;
  }

  List<Favourite> getRecentlyVisited(List<Favourite> favourites, {int limit = 5}) {
    return favourites
        .where((f) => f.visitStatus == VisitStatus.visited)
        .toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded))
        ..take(limit);
  }

  List<Favourite> getPlannedVisits(List<Favourite> favourites) {
    return favourites
        .where((f) => f.visitStatus == VisitStatus.planned)
        .toList()
        ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded)); // Oldest planned first
  }

  // NEW: Get places to discover (not visited)
  List<Favourite> getToDiscover(List<Favourite> favourites) {
    return favourites
        .where((f) => f.visitStatus == VisitStatus.notVisited)
        .toList();
  }
  
  List<String> getAllTags(List<Favourite> favourites) {
    final allTags = <String>{};
    for (final favourite in favourites) {
      allTags.addAll(favourite.tags);
    }
    return allTags.toList()..sort();
  }

  // Helper method to get all unique categories
  List<String> getAllCategories(List<Favourite> favourites) {
    final allCategories = <String>{};
    for (final favourite in favourites) {
      if (favourite.cuisineType != null && favourite.cuisineType!.isNotEmpty) {
        allCategories.add(favourite.cuisineType!);
      }
    }
    return allCategories.toList()..sort();
  }

  // NEW: Create a quick filter for "discovery mode" - places you haven't been to
  FilterCriteria createDiscoveryFilter() {
    return const FilterCriteria(
      searchQuery: '',
      selectedCategories: [],
      selectedTags: [],
      minRating: 0.0,
      showOpenOnly: false,
      showVegOnly: false,
      showNonVegOnly: false,
      selectedVisitStatus: [VisitStatus.notVisited],
    );
  }

  // NEW: Create a quick filter for "memories" - places you've visited
  FilterCriteria createMemoriesFilter() {
    return const FilterCriteria(
      searchQuery: '',
      selectedCategories: [],
      selectedTags: [],
      minRating: 0.0,
      showOpenOnly: false,
      showVegOnly: false,
      showNonVegOnly: false,
      selectedVisitStatus: [VisitStatus.visited],
    );
  }
}

