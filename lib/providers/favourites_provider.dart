import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      print('📱 FavouritesProvider: Starting to load favourites...');
      
      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ FavouritesProvider: No authenticated user found');
        _setError('Please sign in to view your favourites');
        return;
      }
      
      print('✅ FavouritesProvider: User authenticated: ${currentUser.email}');
      
      _setLoading(true);
      clearError();
      
      // Listen to favourites stream
      _favouritesService.getFavourites(sortBy: _currentSort).listen(
        (favourites) {
          print('✅ FavouritesProvider: Received ${favourites.length} favourites from stream');
          _favourites = favourites;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          print('❌ FavouritesProvider: Stream error: $error');
          _setError('Failed to load favourites: $error');
        },
      );
    } catch (e) {
      print('❌ FavouritesProvider: Error setting up favourites listener: $e');
      print('Stack trace: ${StackTrace.current}');
      _setError('Failed to load favourites: $e');
    }
  }

  // Add new favourite
  Future<bool> addFavourite(Favourite favourite) async {
    print('➕ FavouritesProvider: Starting to add favourite...');
    
    // Check authentication
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
        print('❌ FavouritesProvider: No authenticated user for adding favourite');
        return false;
    }
    
    print('✅ FavouritesProvider: User authenticated: ${currentUser.email}');
    
    try {
        print('🔄 FavouritesProvider: Calling favourites service...');
        print('📍 Restaurant: ${favourite.restaurantName}');
        print('🍕 Food items: ${favourite.foodNames}');
        
        await _favouritesService.addFavourite(favourite);
        
        print('✅ FavouritesProvider: Service call completed successfully');
        print('🎯 FavouritesProvider: Returning true');
        
        return true;
        
    } catch (e) {
        print('❌ FavouritesProvider: Error adding favourite: $e');
        return false;
    }
    }

  // Update existing favourite
  Future<bool> updateFavourite(Favourite favourite) async {
    try {
      _setLoading(true);
      clearError();
      
      print('📝 FavouritesProvider: Updating favourite: ${favourite.restaurantName}');
      
      await _favouritesService.updateFavourite(favourite);
      
      print('✅ FavouritesProvider: Favourite updated successfully');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ FavouritesProvider: Error updating favourite: $e');
      _setError('Failed to update favourite: $e');
      return false;
    }
  }

  // Delete favourite
  Future<bool> deleteFavourite(String favouriteId) async {
    try {
      _setLoading(true);
      clearError();
      
      print('🗑️ FavouritesProvider: Deleting favourite: $favouriteId');
      
      await _favouritesService.deleteFavourite(favouriteId);
      
      print('✅ FavouritesProvider: Favourite deleted successfully');
      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ FavouritesProvider: Error deleting favourite: $e');
      _setError('Failed to delete favourite: $e');
      return false;
    }
  }

  // Sort favourites
  void sortFavourites(SortType sortType) {
    _currentSort = sortType;
    print('🔄 FavouritesProvider: Sorting favourites by: $sortType');
    
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
      print('❌ FavouritesProvider: Error checking if restaurant is favourited: $e');
      return false;
    }
  }

  // Get favourites stats
  Future<Map<String, int>> getStats() async {
    try {
      return await _favouritesService.getFavouritesStats();
    } catch (e) {
      print('❌ FavouritesProvider: Error getting favourites stats: $e');
      return {};
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    print('🔄 FavouritesProvider: Setting loading state to: $loading');
    _isLoading = loading;
    
    try {
      notifyListeners();
      print('✅ FavouritesProvider: notifyListeners completed for loading: $loading');
    } catch (e) {
      print('❌ FavouritesProvider: Error in notifyListeners for loading: $e');
    }
  }

  void _setError(String error) {
    print('❌ FavouritesProvider: Setting error: $error');
    _errorMessage = error;
    _isLoading = false;
    
    try {
      notifyListeners();
      print('✅ FavouritesProvider: notifyListeners completed for error');
    } catch (e) {
      print('❌ FavouritesProvider: Error in notifyListeners for error: $e');
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      print('🧹 FavouritesProvider: Clearing error message');
    }
    _errorMessage = null;
    
    try {
      notifyListeners();
      print('✅ FavouritesProvider: notifyListeners completed for clearError');
    } catch (e) {
      print('❌ FavouritesProvider: Error in notifyListeners for clearError: $e');
    }
  }
}