// Recent Search Service
// lib/services/search/recent_search_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/search/recent_search_model.dart';
import '../../models/place_model.dart';

class RecentSearchService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;
  
  static RecentSearchService? _instance;
  static RecentSearchService get instance => _instance ??= RecentSearchService._();
  RecentSearchService._();

  // Get recent searches sorted by recency
  Future<List<RecentSearch>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getStringList(_recentSearchesKey) ?? [];
      
      return searchesJson
          .map((jsonString) => RecentSearch.fromJson(json.decode(jsonString)))
          .toList()
        ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt)); // Most recent first
    } catch (e) {
      print('Error loading recent searches: $e');
      return [];
    }
  }

  // Get recent searches sorted by distance from current location
  Future<List<RecentSearch>> getRecentSearchesByDistance(
    double? currentLat, 
    double? currentLng
  ) async {
    final recentSearches = await getRecentSearches();
    
    if (currentLat == null || currentLng == null) {
      return recentSearches;
    }
    
    // Sort by distance
    recentSearches.sort((a, b) {
      final distanceA = a.getDistanceFrom(currentLat, currentLng);
      final distanceB = b.getDistanceFrom(currentLat, currentLng);
      
      // Handle null distances (put them at the end)
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;
      
      return distanceA.compareTo(distanceB);
    });
    
    return recentSearches;
  }

  // Add or update recent search
  Future<void> addRecentSearch(PlaceModel place) async {
    try {
      final recentSearch = RecentSearch.fromPlace(place);
      final recentSearches = await getRecentSearches();
      
      // Remove if already exists (to avoid duplicates)
      recentSearches.removeWhere((search) => 
          search.placeId == recentSearch.placeId || 
          (search.name.toLowerCase() == recentSearch.name.toLowerCase() &&
           search.address.toLowerCase() == recentSearch.address.toLowerCase()));
      
      // Add to beginning
      recentSearches.insert(0, recentSearch);
      
      // Keep only max number of searches
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
      }
      
      await _saveRecentSearches(recentSearches);
    } catch (e) {
      print('Error adding recent search: $e');
    }
  }

  // Save recent searches to storage
  Future<void> _saveRecentSearches(List<RecentSearch> searches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = searches
          .map((search) => json.encode(search.toJson()))
          .toList();
      
      await prefs.setStringList(_recentSearchesKey, searchesJson);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }

  // Clear all recent searches
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  // Remove specific recent search
  Future<void> removeRecentSearch(String searchId) async {
    try {
      final recentSearches = await getRecentSearches();
      recentSearches.removeWhere((search) => search.id == searchId);
      await _saveRecentSearches(recentSearches);
    } catch (e) {
      print('Error removing recent search: $e');
    }
  }

  // Check if a place is in recent searches
  Future<bool> isInRecentSearches(String placeId) async {
    final recentSearches = await getRecentSearches();
    return recentSearches.any((search) => search.placeId == placeId);
  }

  // Get recent searches count
  Future<int> getRecentSearchesCount() async {
    final recentSearches = await getRecentSearches();
    return recentSearches.length;
  }
}