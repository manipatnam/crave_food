// State Management for Enhanced Favorites Screen (Fixed URL Launcher)
// lib/screens/favorites/favourites_screen_state.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/favourites_provider.dart';
import '../../models/favourite_model.dart';
import '../add_favourite_screen.dart';
import 'favourites_sort_options.dart';

mixin FavouritesScreenState<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  // Animation Controllers
  late AnimationController fabController;
  late AnimationController filterController;
  late Animation<double> fabAnimation;
  late Animation<double> filterAnimation;

  // State Variables
  bool sortByName = false;
  SortOption currentSort = SortOption.dateAdded;
  List<String> selectedCategories = [];
  List<String> selectedTags = [];
  double minRating = 0.0;
  bool showOpenOnly = false;
  bool showVegOnly = false;
  bool showNonVegOnly = false;
  String searchQuery = '';
  bool showFilters = false;

  // Location State
  Position? currentLocation;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    initializeLocation();
    loadFavourites();
  }

  void initializeAnimations() {
    fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    fabAnimation = CurvedAnimation(
      parent: fabController,
      curve: Curves.elasticOut,
    );
    
    filterAnimation = CurvedAnimation(
      parent: filterController,
      curve: Curves.easeInOut,
    );

    fabController.forward();
  }

  void initializeLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        return;
      }

      currentLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  void loadFavourites() {
    Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
  }

  void toggleFilters() {
    setState(() => showFilters = !showFilters);
    if (showFilters) {
      filterController.forward();
    } else {
      filterController.reverse();
    }
  }

  void updateFilters({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    double? minRating,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
  }) {
    setState(() {
      if (searchQuery != null) this.searchQuery = searchQuery;
      if (selectedCategories != null) this.selectedCategories = selectedCategories;
      if (selectedTags != null) this.selectedTags = selectedTags;
      if (minRating != null) this.minRating = minRating;
      if (showOpenOnly != null) this.showOpenOnly = showOpenOnly;
      if (showVegOnly != null) this.showVegOnly = showVegOnly;
      if (showNonVegOnly != null) this.showNonVegOnly = showNonVegOnly;
    });
  }

  void updateSort(SortOption sortOption) {
    setState(() => currentSort = sortOption);
  }

  void clearAllFilters() {
    setState(() {
      searchQuery = '';
      selectedCategories.clear();
      selectedTags.clear();
      minRating = 0.0;
      showOpenOnly = false;
      showVegOnly = false;
      showNonVegOnly = false;
    });
  }

  void navigateToAddFavourite() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFavouriteScreen()),
    );
  }

  // Fixed method to launch URLs
  void launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        showSnackBar('Could not open $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      showSnackBar('Error opening link');
    }
  }

  void showDeleteConfirmation(Favourite favourite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favourite'),
        content: Text('Are you sure you want to delete "${favourite.restaurantName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<FavouritesProvider>(context, listen: false)
                  .deleteFavourite(favourite.id);
              showSnackBar('${favourite.restaurantName} removed from favourites');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    fabController.dispose();
    filterController.dispose();
    super.dispose();
  }
}