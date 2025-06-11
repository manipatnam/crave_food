import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/favourite_model.dart';

enum SortType {
  dateAdded,
  restaurantName,
}

class FavouritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get favourites collection reference for current user
  CollectionReference get _favouritesCollection => 
      _firestore.collection('users').doc(_currentUserId).collection('favourites');

  // Get favourites stream with sorting
  Stream<List<Favourite>> getFavourites({SortType sortBy = SortType.dateAdded}) {
    if (_currentUserId == null) {
      print('❌ No authenticated user found');
      return Stream.value([]);
    }

    String orderByField = sortBy == SortType.dateAdded ? 'dateAdded' : 'restaurantName';
    bool descending = sortBy == SortType.dateAdded;

    print('📱 Getting favourites stream for user: $_currentUserId');
    print('🔄 Sorting by: $orderByField (descending: $descending)');

    return _favouritesCollection
        .orderBy(orderByField, descending: descending)
        .snapshots()
        .map((snapshot) {
          final favourites = snapshot.docs
              .map((doc) => Favourite.fromFirestore(doc))
              .toList();
          
          print('✅ Retrieved ${favourites.length} favourites');
          return favourites;
        })
        .handleError((error) {
          print('❌ Error in favourites stream: $error');
          throw 'Failed to load favourites: $error';
        });
  }

  // Add new favourite
  Future<void> addFavourite(Favourite favourite) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('➕ Adding favourite for user: $_currentUserId');
      print('📍 Restaurant: ${favourite.restaurantName}');

      // Create favourite with current user ID
      final favouriteToAdd = favourite.copyWith(userId: _currentUserId!);
      
      await _favouritesCollection.add(favouriteToAdd.toFirestore());
      
      print('✅ Favourite added successfully');
    } catch (e) {
      print('❌ Error adding favourite: $e');
      throw 'Failed to add favourite: $e';
    }
  }

  // Update existing favourite
  Future<void> updateFavourite(Favourite favourite) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('📝 Updating favourite: ${favourite.id}');
      
      await _favouritesCollection.doc(favourite.id).update({
        'restaurantName': favourite.restaurantName,
        'foodNames': favourite.foodNames,
        'socialUrls': favourite.socialUrls,
        'userNotes': favourite.userNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Favourite updated successfully');
    } catch (e) {
      print('❌ Error updating favourite: $e');
      throw 'Failed to update favourite: $e';
    }
  }

  // Delete favourite
  Future<void> deleteFavourite(String favouriteId) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      print('🗑️ Deleting favourite: $favouriteId');
      
      await _favouritesCollection.doc(favouriteId).delete();
      
      print('✅ Favourite deleted successfully');
    } catch (e) {
      print('❌ Error deleting favourite: $e');
      throw 'Failed to delete favourite: $e';
    }
  }

  // Check if restaurant is already favourited
  Future<bool> isRestaurantFavourited(String googlePlaceId) async {
    if (_currentUserId == null) {
      return false;
    }

    try {
      final querySnapshot = await _favouritesCollection
          .where('googlePlaceId', isEqualTo: googlePlaceId)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if restaurant is favourited: $e');
      return false;
    }
  }

  // Get favourites statistics
  Future<Map<String, int>> getFavouritesStats() async {
    if (_currentUserId == null) {
      return {
        'totalFavourites': 0,
        'thisMonth': 0,
        'thisWeek': 0,
      };
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Get all favourites
      final allSnapshot = await _favouritesCollection.get();
      
      // Get this month's favourites
      final monthSnapshot = await _favouritesCollection
          .where('dateAdded', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();
      
      // Get this week's favourites
      final weekSnapshot = await _favouritesCollection
          .where('dateAdded', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      return {
        'totalFavourites': allSnapshot.docs.length,
        'thisMonth': monthSnapshot.docs.length,
        'thisWeek': weekSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error getting favourites stats: $e');
      return {
        'totalFavourites': 0,
        'thisMonth': 0,
        'thisWeek': 0,
      };
    }
  }

  // Get favourite by ID
  Future<Favourite?> getFavouriteById(String favouriteId) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _favouritesCollection.doc(favouriteId).get();
      
      if (doc.exists) {
        return Favourite.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting favourite by ID: $e');
      return null;
    }
  }

  // Search favourites (client-side filtering for now)
  Future<List<Favourite>> searchFavourites(String query) async {
    if (_currentUserId == null || query.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _favouritesCollection
          .orderBy('dateAdded', descending: true)
          .get();
      
      final allFavourites = snapshot.docs
          .map((doc) => Favourite.fromFirestore(doc))
          .toList();
      
      final queryLower = query.toLowerCase();
      
      return allFavourites.where((favourite) {
        return favourite.restaurantName.toLowerCase().contains(queryLower) ||
               favourite.foodNames.any((food) => food.toLowerCase().contains(queryLower));
      }).toList();
    } catch (e) {
      print('❌ Error searching favourites: $e');
      return [];
    }
  }

  // Batch operations for future use
  Future<void> addMultipleFavourites(List<Favourite> favourites) async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      final batch = _firestore.batch();
      
      for (final favourite in favourites) {
        final docRef = _favouritesCollection.doc();
        final favouriteToAdd = favourite.copyWith(
          id: docRef.id,
          userId: _currentUserId!,
        );
        batch.set(docRef, favouriteToAdd.toFirestore());
      }
      
      await batch.commit();
      print('✅ Added ${favourites.length} favourites in batch');
    } catch (e) {
      print('❌ Error adding multiple favourites: $e');
      throw 'Failed to add multiple favourites: $e';
    }
  }

  // Delete all favourites for current user (for testing/cleanup)
  Future<void> deleteAllFavourites() async {
    if (_currentUserId == null) {
      throw 'User not authenticated';
    }

    try {
      final snapshot = await _favouritesCollection.get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Deleted all favourites for user');
    } catch (e) {
      print('❌ Error deleting all favourites: $e');
      throw 'Failed to delete all favourites: $e';
    }
  }
}