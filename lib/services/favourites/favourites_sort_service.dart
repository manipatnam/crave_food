// Favourites Sort Service (Fixed)
// lib/services/favourites/favourites_sort_service.dart

import 'package:geolocator/geolocator.dart';
import '../../models/favourite_model.dart';
import '../../screens/favorites/favourites_sort_options.dart';

class FavouritesSortService {
  List<Favourite> sortFavourites(
    List<Favourite> favourites,
    SortCriteria criteria,
  ) {
    final List<Favourite> sortedList = List.from(favourites);

    switch (criteria.sortOption) {
      case SortOption.dateAdded:
        sortedList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
        
      case SortOption.restaurantName:
        sortedList.sort((a, b) => a.restaurantName.compareTo(b.restaurantName));
        break;
        
      case SortOption.rating:
        sortedList.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
        
      case SortOption.category:
        sortedList.sort((a, b) {
          final categoryA = a.cuisineType ?? '';
          final categoryB = b.cuisineType ?? '';
          final categoryComparison = categoryA.compareTo(categoryB);
          if (categoryComparison != 0) return categoryComparison;
          return a.restaurantName.compareTo(b.restaurantName);
        });
        break;
        
      case SortOption.distance:
        if (criteria.currentLocation != null) {
          sortedList.sort((a, b) {
            final distanceA = Geolocator.distanceBetween(
              criteria.currentLocation.latitude,
              criteria.currentLocation.longitude,
              a.coordinates.latitude,
              a.coordinates.longitude,
            );
            final distanceB = Geolocator.distanceBetween(
              criteria.currentLocation.latitude,
              criteria.currentLocation.longitude,
              b.coordinates.latitude,
              b.coordinates.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }

    return sortedList;
  }

  double calculateDistance(
    Favourite favourite,
    dynamic currentLocation,
  ) {
    if (currentLocation == null) return 0.0;
    
    return Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      favourite.coordinates.latitude,
      favourite.coordinates.longitude,
    );
  }

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }
}