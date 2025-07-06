import '../../models/place_model.dart';
import '../../models/favourite_model.dart';
import '../../enums/search/search_sort_option.dart';
import '../../services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class SearchFilterUtils { 
    static List<PlaceModel> sortSearchResults(
        List<PlaceModel> results,
        SearchSortOption sortOption,
        LatLng? currentLocation) {
        switch (sortOption) {
        case SearchSortOption.distance:
            if (currentLocation != null) {
            results.sort((a, b) {
                final distanceA = LocationService.calculateDistance(
                currentLocation!,
                LatLng(a.geoPoint.latitude, a.geoPoint.longitude),
                );
                final distanceB = LocationService.calculateDistance(
                currentLocation!,
                LatLng(b.geoPoint.latitude, b.geoPoint.longitude),
                );
                return distanceA.compareTo(distanceB);
            });
            }
            break;
        case SearchSortOption.rating:
            results.sort((a, b) {
            final ratingA = a.rating ?? 0.0;
            final ratingB = b.rating ?? 0.0;
            return ratingB.compareTo(ratingA);
            });
            break;
        case SearchSortOption.name:
            results.sort((a, b) => a.name.compareTo(b.name));
            break;
        case SearchSortOption.popularity:
            // Sort by rating * review count as a proxy for popularity
            results.sort((a, b) {
            final popularityA = (a.rating ?? 0.0) * (a.userRatingsTotal ?? 0);
            final popularityB = (b.rating ?? 0.0) * (b.userRatingsTotal ?? 0);
            return popularityB.compareTo(popularityA);
            });
            break;
        case SearchSortOption.relevance:
        default:
            // Keep original order (Google's relevance)
            break;
        }
        return results;
    }

    static List<String> getAllCategories(List<Favourite> favourites) {
        final categories = <String>{};
        for (final fav in favourites) {
            if (fav.cuisineType != null && fav.cuisineType!.isNotEmpty) {
            categories.add(fav.cuisineType!);
            }
        }
        return categories.toList();
    }

    static List<String> getAllTags(List<Favourite> favourites) {
        final tags = <String>{};
        for (final fav in favourites) {
            tags.addAll(fav.tags);
        }
        return tags.toList()..sort();
    }
}

