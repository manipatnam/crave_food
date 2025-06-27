// Enhanced Favorites Screen - Main File (Fixed)
// lib/screens/favorites/enhanced_favourites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/favourites_provider.dart';
import '../../models/favourite_model.dart';
import '../../services/favourites_service.dart';
import '../add_favourite_screen.dart';
import '../../widgets/favourites/enhanced_favourite_card.dart';
import '../../widgets/favourites/favorites_filter_panel.dart';
import '../../widgets/favourites/favorites_sort_modal.dart';
import '../../widgets/favourites/favorites_empty_states.dart';
import '../../services/favourites/favourites_filter_service.dart';
import '../../services/favourites/favourites_sort_service.dart';
import '../../animations/favourites/favorites_screen_animations.dart';
import 'favourites_sort_options.dart';
import 'favourites_screen_state.dart';

class EnhancedFavouritesScreen extends StatefulWidget {
  const EnhancedFavouritesScreen({super.key});

  @override
  State<EnhancedFavouritesScreen> createState() => _EnhancedFavouritesScreenState();
}

class _EnhancedFavouritesScreenState extends State<EnhancedFavouritesScreen>
    with TickerProviderStateMixin, FavouritesScreenState {
  final FavouritesFilterService _filterService = FavouritesFilterService();
  final FavouritesSortService _sortService = FavouritesSortService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (showFilters) 
            SliverToBoxAdapter(
              child: FavoritesFilterPanel(
                selectedCategories: selectedCategories,
                selectedTags: selectedTags,
                minRating: minRating,
                showOpenOnly: showOpenOnly,
                showVegOnly: showVegOnly,
                showNonVegOnly: showNonVegOnly,
                searchQuery: searchQuery,
                onFiltersChanged: updateFilters,
                onClearFilters: clearAllFilters,
              ),
            ),
          SliverToBoxAdapter(
            child: Consumer<FavouritesProvider>(
              builder: (context, favouritesProvider, child) {
                if (favouritesProvider.isLoading) {
                  return const FavoritesLoadingState();
                }

                if (favouritesProvider.errorMessage != null) {
                  return FavoritesErrorState(
                    error: favouritesProvider.errorMessage!,
                    onRetry: () {
                      favouritesProvider.clearError();
                      favouritesProvider.loadFavourites();
                    },
                  );
                }

                if (favouritesProvider.favourites.isEmpty) {
                  return const FavoritesEmptyState();
                }

                final filteredFavourites = _filterService.getFilteredAndSorted(
                  favouritesProvider.favourites,
                  FilterCriteria(
                    searchQuery: searchQuery,
                    selectedCategories: selectedCategories,
                    selectedTags: selectedTags,
                    minRating: minRating,
                    showOpenOnly: showOpenOnly,
                    showVegOnly: showVegOnly,
                    showNonVegOnly: showNonVegOnly,
                  ),
                  SortCriteria(
                    sortOption: currentSort,
                    currentLocation: currentLocation,
                  ),
                );

                if (filteredFavourites.isEmpty) {
                  return FavoritesNoResultsState(onClearFilters: clearAllFilters);
                }

                return _buildFavoritesList(filteredFavourites);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FavoritesScreenAnimations.buildAnimatedFAB(
        fabAnimation: fabAnimation,
        onPressed: navigateToAddFavourite,
        primaryColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('My Favourites', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => showSortModal(context),
          icon: const Icon(Icons.sort_rounded),
          tooltip: 'Sort options',
        ),
        IconButton(
          onPressed: toggleFilters,
          icon: AnimatedRotation(
            turns: showFilters ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.tune_rounded),
          ),
          tooltip: 'Filter options',
        ),
      ],
    );
  }

  Widget _buildFavoritesList(List<Favourite> favourites) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: favourites.length,
      itemBuilder: (context, index) {
        final favourite = favourites[index];
        return EnhancedFavouriteCard(
          favourite: favourite,
          onLaunchUrl: launchUrl,
          onEdit: () => showSnackBar('Edit functionality coming soon!'),
          onDelete: () => showDeleteConfirmation(favourite),
          currentLocation: currentLocation,
          showDistance: currentSort == SortOption.distance,
        );
      },
    );
  }

  void showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FavoritesSortModal(
        currentSort: currentSort,
        currentLocation: currentLocation,
        isLoadingLocation: isLoadingLocation,
        onSortChanged: updateSort,
      ),
    );
  }
}