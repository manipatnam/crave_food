import 'package:flutter/foundation.dart';
import '../models/favourite_model.dart';
import '../services/favourites_service.dart';

class FavouritesProvider extends ChangeNotifier {
  final FavouritesService _favouritesService = FavouritesService();

  List<Favourite> _favourites = [];
  bool _isLoading = false;
  String? _errorMessage;
  SortType _currentSort = SortType.dateAdded;

  // Getters
  List<Favourite> get favourites => _favourites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SortType get currentSort => _currentSort;

  // Load favourites from Firestore
  Future<void> loadFavourites() async {
    try {
      _setLoading(true);
      clearError();
      
      print('📱 Loading favourites...');
      
      // Listen to favourites stream
      _favouritesService.getFavourites(sortBy: _currentSort).listen(
        (favourites) {
          _favourites = favourites;
          _setLoading(false);
          print('✅ Loaded ${favourites.length} favourites');
          notifyListeners();
        },
        onError: (error) {
          print('❌ Error loading favourites: $error');
          _setError('Failed to load favourites: $error');
        },
      );
    } catch (e) {
      print('❌ Error setting up favourites listener: $e');
      _setError('Failed to load favourites: $e');
    }
  }

  // Add new favourite
  Future<bool> addFavourite(Favourite favourite) async {
    try {
      _setLoading(true);
      clearError();
      
      print('➕ Adding favourite: ${favourite.restaurantName}');
      
      await _favouritesService.addFavourite(favourite);
      
      print('✅ Favourite added successfully');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Error adding favourite: $e');
      _setError('Failed to add favourite: $e');
      return false;
    }
  }

  // Update existing favourite
  Future<bool> updateFavourite(Favourite favourite) async {
    try {
      _setLoading(true);
      clearError();
      
      print('📝 Updating favourite: ${favourite.restaurantName}');
      
      await _favouritesService.updateFavourite(favourite);
      
      print('✅ Favourite updated successfully');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Error updating favourite: $e');
      _setError('Failed to update favourite: $e');
      return false;
    }
  }

  // Delete favourite
  Future<bool> deleteFavourite(String favouriteId) async {
    try {
      _setLoading(true);
      clearError();
      
      print('🗑️ Deleting favourite: $favouriteId');
      
      await _favouritesService.deleteFavourite(favouriteId);
      
      print('✅ Favourite deleted successfully');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Error deleting favourite: $e');
      _setError('Failed to delete favourite: $e');
      return false;
    }
  }

  // Sort favourites
  void sortFavourites(SortType sortType) {
    _currentSort = sortType;
    print('🔄 Sorting favourites by: $sortType');
    
    switch (sortType) {
      case SortType.dateAdded:
        _favourites.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortType.restaurantName:
        _favourites.sort((a, b) => a.restaurantName.compareTo(b.restaurantName));
        break;
    }
    
    notifyListeners();
  }

  // Search favourites
  List<Favourite> searchFavourites(String query) {
    if (query.isEmpty) return _favourites;
    
    final queryLower = query.toLowerCase();
    return _favourites.where((favourite) {
      return favourite.restaurantName.toLowerCase().contains(queryLower) ||
             favourite.foodNames.any((food) => food.toLowerCase().contains(queryLower));
    }).toList();
  }

  // Check if restaurant is already favourited
  Future<bool> isRestaurantFavourited(String googlePlaceId) async {
    try {
      return await _favouritesService.isRestaurantFavourited(googlePlaceId);
    } catch (e) {
      print('❌ Error checking if restaurant is favourited: $e');
      return false;
    }
  }

  // Get favourites stats
  Future<Map<String, int>> getStats() async {
    try {
      return await _favouritesService.getFavouritesStats();
    } catch (e) {
      print('❌ Error getting favourites stats: $e');
      return {};
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}