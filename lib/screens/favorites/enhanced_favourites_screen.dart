// lib/screens/favorites/enhanced_favourites_screen.dart
// FIXED VERSION - All compilation errors resolved

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/favourites_provider.dart';
import '../../models/favourite_model.dart';
import '../../models/visit_status.dart';
import '../../services/favourites_service.dart';
import '../add_favourite_screen.dart';
import '../../widgets/favourites/enhanced_favourite_card.dart';
import '../../widgets/favourites/favorites_filter_panel.dart';
import '../../widgets/favourites/favorites_sort_modal.dart';
import '../../widgets/favourites/favorites_empty_states.dart';
import '../../widgets/favourites/visit_status_filter_section.dart';
import '../../services/favourites/favourites_filter_service.dart';
import '../../services/favourites/favourites_sort_service.dart';
import '../../animations/favourites/favorites_screen_animations.dart';
import 'favourites_sort_options.dart';
import 'favourites_screen_state.dart';
import '../../widgets/common/universal_restaurant_tile.dart';
import '../../widgets/adapters/screen_tile_adapters.dart';
import '../../widgets/favourites/comprehensive_favourite_card.dart';


class EnhancedFavouritesScreen extends StatefulWidget {
  const EnhancedFavouritesScreen({super.key});

  @override
  State<EnhancedFavouritesScreen> createState() => _EnhancedFavouritesScreenState();
}

class _EnhancedFavouritesScreenState extends State<EnhancedFavouritesScreen>
    with TickerProviderStateMixin, FavouritesScreenState {
  final FavouritesFilterService _filterService = FavouritesFilterService();
  final FavouritesSortService _sortService = FavouritesSortService();
  
  // Current filter criteria with visit status
  FilterCriteria currentFilterCriteria = const FilterCriteria(
    searchQuery: '',
    selectedCategories: [],
    selectedTags: [],
    minRating: 0.0,
    showOpenOnly: false,
    showVegOnly: false,
    showNonVegOnly: false,
    selectedVisitStatus: [],
  );

  // Method to update visit status
  Future<void> _updateVisitStatus(Favourite favourite) async {
    try {
      await Provider.of<FavouritesProvider>(context, listen: false)
          .updateFavourite(favourite);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(favourite.visitStatus.emoji),
                const SizedBox(width: 8),
                Text('Updated to ${favourite.visitStatus.label}'),
              ],
            ),
            backgroundColor: favourite.visitStatus.color,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build quick filter chips
  Widget _buildQuickFilters() {
    return Consumer<FavouritesProvider>(
      builder: (context, provider, _) {
        final counts = _filterService.getVisitStatusCounts(provider.favourites);
        
        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // All filter
              _buildQuickFilterChip(
                label: 'All',
                count: provider.favourites.length,
                isSelected: selectedCategories.isEmpty && 
                           selectedTags.isEmpty &&
                           currentFilterCriteria.selectedVisitStatus.isEmpty,
                onTap: () => _clearAllFilters(),
                color: Colors.grey[600]!,
                icon: Icons.view_list,
              ),
              const SizedBox(width: 8),
              
              // Visit status quick filters
              ...VisitStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildQuickFilterChip(
                  label: status.label,
                  count: counts[status] ?? 0,
                  isSelected: currentFilterCriteria.selectedVisitStatus.contains(status),
                  onTap: () => _toggleVisitStatusFilter(status),
                  color: status.color,
                  emoji: status.emoji,
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
    String? emoji,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 14))
          else if (icon != null)
            Icon(icon, size: 16),
          if (emoji != null || icon != null) const SizedBox(width: 4),
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white,
              ),
            ),
          ),
        ],
      ),
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? color : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  void _toggleVisitStatusFilter(VisitStatus status) {
    setState(() {
      final currentStatuses = List<VisitStatus>.from(
        currentFilterCriteria.selectedVisitStatus
      );
      
      if (currentStatuses.contains(status)) {
        currentStatuses.remove(status);
      } else {
        currentStatuses.clear(); // Only one status at a time for simplicity
        currentStatuses.add(status);
      }
      
      currentFilterCriteria = currentFilterCriteria.copyWith(
        selectedVisitStatus: currentStatuses,
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategories.clear();
      selectedTags.clear();
      currentFilterCriteria = const FilterCriteria(
        searchQuery: '',
        selectedCategories: [],
        selectedTags: [],
        minRating: 0.0,
        showOpenOnly: false,
        showVegOnly: false,
        showNonVegOnly: false,
        selectedVisitStatus: [],
      );
      searchQuery = '';
      minRating = 0.0;
      showOpenOnly = false;
      showVegOnly = false;
      showNonVegOnly = false;
    });
  }

  List<Favourite> _getFilteredAndSortedFavourites(List<Favourite> favourites) {

    final updatedCriteria = currentFilterCriteria.copyWith(
      searchQuery: searchQuery,
      selectedCategories: selectedCategories,
      selectedTags: selectedTags,
      minRating: minRating,
      showOpenOnly: showOpenOnly,
      showVegOnly: showVegOnly,
      showNonVegOnly: showNonVegOnly,
    );
    // Apply filters
    final filtered = _filterService.applyFilters(favourites, currentFilterCriteria);
    
    // Apply sorting
    final sortCriteria = SortCriteria(
      sortOption: currentSort,
      currentLocation: currentLocation,
    );
    
    return _sortService.sortFavourites(filtered, sortCriteria);
    // return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          
          // Quick filters section
          SliverToBoxAdapter(child: _buildQuickFilters()),
          
          if (showFilters) 
            SliverToBoxAdapter(
              child: Column(
                children: [
                  FavoritesFilterPanel(
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
                  // Add visit status filter section here
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: VisitStatusFilterSection(
                      selectedStatuses: currentFilterCriteria.selectedVisitStatus,
                      onStatusesChanged: (statuses) {
                        setState(() {
                          currentFilterCriteria = currentFilterCriteria.copyWith(
                            selectedVisitStatus: statuses,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          SliverToBoxAdapter(
            child: Consumer<FavouritesProvider>(
              builder: (context, favouritesProvider, child) {
                if (favouritesProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (favouritesProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading favourites',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            favouritesProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              favouritesProvider.clearError();
                              favouritesProvider.loadFavourites();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (favouritesProvider.favourites.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredAndSorted = _getFilteredAndSortedFavourites(
                  favouritesProvider.favourites
                );

                if (filteredAndSorted.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildFavoritesList(filteredAndSorted);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFavourite(),
        child: const Icon(Icons.add),
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
          onPressed: () => _showSortModal(context),
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
        return ComprehensiveFavouriteCard( // ✅ NEW: Shows ALL details
          favourite: favourite,
          currentLocation: currentLatLng, // Use your existing location getter
          onEdit: () => _showSnackBar('Edit functionality coming soon!'),
          onDelete: () => _showDeleteConfirmation(favourite),
          onLaunchUrl: (url) => launchUrl(url),
          onStatusChanged: _updateVisitStatus,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    // Show different empty states based on active filters
    if (currentFilterCriteria.selectedVisitStatus.isNotEmpty) {
      final status = currentFilterCriteria.selectedVisitStatus.first;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                status.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${status.label} Places',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                status == VisitStatus.visited
                    ? 'Start exploring and mark places as visited!'
                    : status == VisitStatus.planned  
                        ? 'Add some places to your planning list'
                        : 'All your favorites have been visited or planned!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToAddFavourite,
                child: const Text('Add New Place'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Default empty state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              '🍽️',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your collection of favorite places!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToAddFavourite,
              child: const Text('Add First Favorite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortModal(BuildContext context) {
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

  void _showDeleteConfirmation(Favourite favourite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favorite'),
        content: Text('Are you sure you want to delete "${favourite.restaurantName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFavourite(favourite.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteFavourite(String favouriteId) async {
    try {
      await Provider.of<FavouritesProvider>(context, listen: false)
          .deleteFavourite(favouriteId);
      _showSnackBar('Favorite deleted successfully');
    } catch (e) {
      _showSnackBar('Failed to delete favorite: $e');
    }
  }

  void _navigateToAddFavourite() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFavouriteScreen(),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}