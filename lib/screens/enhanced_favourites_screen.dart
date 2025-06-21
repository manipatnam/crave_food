// Enhanced Favorites Screen with Expandable Cards
// lib/screens/enhanced_favourites_screen.dart

// USAGE: Replace the import in your enhanced_home_screen.dart:
// Change: import 'favourites_screen.dart';
// To: import 'enhanced_favourites_screen.dart';
// 
// And change: const FavouritesScreen(),
// To: const EnhancedFavouritesScreen(),

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/favourites_provider.dart';
import '../models/favourite_model.dart';
import '../services/favourites_service.dart';
import 'add_favourite_screen.dart';

// Sort and Filter Options
enum SortOption {
  dateAdded('Date Added'),
  restaurantName('Name A-Z'),
  rating('Highest Rating'),
  category('Category'),
  distance('Distance');

  const SortOption(this.label);
  final String label;
}

class EnhancedFavouritesScreen extends StatefulWidget {
  const EnhancedFavouritesScreen({super.key});

  @override
  State<EnhancedFavouritesScreen> createState() => _EnhancedFavouritesScreenState();
}

class _EnhancedFavouritesScreenState extends State<EnhancedFavouritesScreen>
    with TickerProviderStateMixin {
  // Sorting and Filtering State
  bool _sortByName = false;
  SortOption _currentSort = SortOption.dateAdded;
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];
  double _minRating = 0.0;
  bool _showOpenOnly = false;
  bool _showVegOnly = false;
  bool _showNonVegOnly = false;
  String _searchQuery = '';
  
  // Location State
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  
  // UI State
  bool _showFilters = false;
  late AnimationController _fabController;
  late AnimationController _filterController;
  late Animation<double> _fabAnimation;
  late Animation<double> _filterAnimation;
  
  // Text Controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
      _fabController.forward();
    });
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _filterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get current location for distance sorting
  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied', isError: true);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      _showSnackBar('Failed to get current location: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Sort and Filter Functions
  void _updateSort(SortOption sortOption) {
    // Check if distance sorting is available
    if (sortOption == SortOption.distance && _currentLocation == null) {
      _showSnackBar('Getting location for distance sorting...', isError: false);
      _getCurrentLocation().then((_) {
        if (_currentLocation != null) {
          setState(() {
            _currentSort = sortOption;
            _sortByName = sortOption == SortOption.restaurantName;
          });
        }
      });
      return;
    }

    setState(() {
      _currentSort = sortOption;
      _sortByName = sortOption == SortOption.restaurantName;
    });
    
    final provider = Provider.of<FavouritesProvider>(context, listen: false);
    
    switch (sortOption) {
      case SortOption.dateAdded:
        provider.sortFavourites(SortType.dateAdded);
        break;
      case SortOption.restaurantName:
        provider.sortFavourites(SortType.restaurantName);
        break;
      case SortOption.rating:
      case SortOption.category:
      case SortOption.distance:
        // These are handled in _getFilteredAndSortedFavourites
        break;
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedTags.clear();
      _minRating = 0.0;
      _showOpenOnly = false;
      _showVegOnly = false;
      _showNonVegOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Favourite> _getFilteredAndSortedFavourites(List<Favourite> favourites) {
    List<Favourite> filtered = favourites.where((favourite) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesName = favourite.restaurantName.toLowerCase().contains(_searchQuery);
        final matchesFoodItems = favourite.foodNames.any(
          (food) => food.toLowerCase().contains(_searchQuery),
        );
        final matchesTags = favourite.tags.any(
          (tag) => tag.toLowerCase().contains(_searchQuery),
        );
        if (!matchesName && !matchesFoodItems && !matchesTags) return false;
      }

      // Category filter
      if (_selectedCategories.isNotEmpty) {
        if (favourite.placeCategory == null || 
            !_selectedCategories.contains(favourite.placeCategory)) {
          return false;
        }
      }

      // Tags filter
      if (_selectedTags.isNotEmpty) {
        final hasMatchingTag = _selectedTags.any(
          (tag) => favourite.tags.contains(tag),
        );
        if (!hasMatchingTag) return false;
      }

      // Rating filter
      if (favourite.rating != null && favourite.rating! < _minRating) {
        return false;
      }

      // Open/Closed filter
      if (_showOpenOnly && (favourite.isOpen == null || !favourite.isOpen!)) {
        return false;
      }

      // Dietary filters
      if (_showVegOnly && !favourite.isVegetarianAvailable) return false;
      if (_showNonVegOnly && !favourite.isNonVegetarianAvailable) return false;

      return true;
    }).toList();

    // Custom sorting for rating, category, and distance
    switch (_currentSort) {
      case SortOption.rating:
        filtered.sort((a, b) {
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return b.rating!.compareTo(a.rating!);
        });
        break;
      case SortOption.category:
        filtered.sort((a, b) {
          final categoryA = a.placeCategory ?? 'zzz';
          final categoryB = b.placeCategory ?? 'zzz';
          return categoryA.compareTo(categoryB);
        });
        break;
      case SortOption.distance:
        if (_currentLocation != null) {
          filtered.sort((a, b) {
            final distanceA = _calculateDistance(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              a.coordinates.latitude,
              a.coordinates.longitude,
            );
            final distanceB = _calculateDistance(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              b.coordinates.latitude,
              b.coordinates.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
      case SortOption.dateAdded:
      case SortOption.restaurantName:
        // These are handled by the provider
        break;
    }

    return filtered;
  }

  List<String> _getAllCategories(List<Favourite> favourites) {
    return favourites
        .map((f) => f.placeCategory)
        .where((category) => category != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getAllTags(List<Favourite> favourites) {
    final allTags = <String>{};
    for (final favourite in favourites) {
      allTags.addAll(favourite.tags);
    }
    return allTags.toList()..sort();
  }

  void _toggleSort() {
    final nextSort = _currentSort == SortOption.dateAdded 
        ? SortOption.restaurantName 
        : SortOption.dateAdded;
    _updateSort(nextSort);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showSnackBar('Could not launch $url', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error opening link: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDeleteConfirmation(Favourite favourite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Favourite'),
        content: Text('Are you sure you want to remove "${favourite.restaurantName}" from your favourites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<FavouritesProvider>(context, listen: false)
                  .deleteFavourite(favourite.id);
              _showSnackBar('Favourite removed successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddFavourite() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFavouriteScreen()),
    );
    
    if (result == true && mounted) {
      Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildSearchAndFilters(),
          _buildFilterChips(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: Consumer<FavouritesProvider>(
              builder: (context, favouritesProvider, child) {
                if (favouritesProvider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (favouritesProvider.errorMessage != null) {
                  return SliverFillRemaining(
                    child: _buildErrorState(favouritesProvider.errorMessage!, () {
                      favouritesProvider.clearError();
                      favouritesProvider.loadFavourites();
                    }),
                  );
                }

                if (favouritesProvider.favourites.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                final filteredFavourites = _getFilteredAndSortedFavourites(
                  favouritesProvider.favourites,
                );

                if (filteredFavourites.isEmpty) {
                  return SliverFillRemaining(child: _buildNoResultsState());
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favourite = filteredFavourites[index];
                      return EnhancedFavouriteCard(
                        favourite: favourite,
                        onLaunchUrl: _launchUrl,
                        onEdit: () => _showSnackBar('Edit functionality coming soon!'),
                        onDelete: () => _showDeleteConfirmation(favourite),
                        currentLocation: _currentLocation,
                        showDistance: _currentSort == SortOption.distance,
                      );
                    },
                    childCount: filteredFavourites.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddFavourite,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Favourite'),
          elevation: 8,
          highlightElevation: 12,
        ),
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
          onPressed: _showSortOptions,
          icon: const Icon(Icons.sort_rounded),
          tooltip: 'Sort options',
        ),
        IconButton(
          onPressed: _toggleFilters,
          icon: AnimatedRotation(
            turns: _showFilters ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.tune_rounded),
          ),
          tooltip: _showFilters ? 'Hide filters' : 'Show filters',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search favourites...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear_rounded),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            // Filter Panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: _showFilters ? null : 0,
              curve: Curves.easeInOut,
              child: _showFilters ? _buildFilterPanel() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Consumer<FavouritesProvider>(
      builder: (context, provider, child) {
        final categories = _getAllCategories(provider.favourites);
        final tags = _getAllTags(provider.favourites);
        
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Header
              Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rating Filter
              Text('Minimum Rating', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _minRating == 0.0 ? 'Any' : _minRating.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _minRating = value),
                    ),
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      _minRating == 0.0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Categories Filter
              if (categories.isNotEmpty) ...[
                Text('Categories', 
                     style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Status Filters
              Text('Status', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Open Now'),
                    selected: _showOpenOnly,
                    onSelected: (selected) => setState(() => _showOpenOnly = selected),
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ),
                  FilterChip(
                    label: const Text('Vegetarian'),
                    selected: _showVegOnly,
                    onSelected: (selected) => setState(() => _showVegOnly = selected),
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ),
                  FilterChip(
                    label: const Text('Non-Vegetarian'),
                    selected: _showNonVegOnly,
                    onSelected: (selected) => setState(() => _showNonVegOnly = selected),
                    selectedColor: Colors.red.withOpacity(0.2),
                    checkmarkColor: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tags Filter
              if (tags.isNotEmpty) ...[
                Text('Tags', 
                     style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.take(10).map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text('#$tag'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final activeFilters = <Widget>[];
    
    if (_searchQuery.isNotEmpty) {
      activeFilters.add(_buildActiveFilterChip('Search: $_searchQuery', () {
        _searchController.clear();
        _onSearchChanged('');
      }));
    }
    
    if (_minRating > 0.0) {
      activeFilters.add(_buildActiveFilterChip('Rating: ${_minRating.toStringAsFixed(1)}+', () {
        setState(() => _minRating = 0.0);
      }));
    }
    
    if (_showOpenOnly) {
      activeFilters.add(_buildActiveFilterChip('Open Now', () {
        setState(() => _showOpenOnly = false);
      }));
    }
    
    if (_showVegOnly) {
      activeFilters.add(_buildActiveFilterChip('Vegetarian', () {
        setState(() => _showVegOnly = false);
      }));
    }
    
    if (_showNonVegOnly) {
      activeFilters.add(_buildActiveFilterChip('Non-Vegetarian', () {
        setState(() => _showNonVegOnly = false);
      }));
    }
    
    for (final category in _selectedCategories) {
      activeFilters.add(_buildActiveFilterChip(category, () {
        setState(() => _selectedCategories.remove(category));
      }));
    }
    
    for (final tag in _selectedTags) {
      activeFilters.add(_buildActiveFilterChip('#$tag', () {
        setState(() => _selectedTags.remove(tag));
      }));
    }
    
    if (activeFilters.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active Filters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...SortOption.values.map((option) => 
                    ListTile(
                      leading: Icon(
                        _getSortIcon(option),
                        color: _currentSort == option 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[600],
                      ),
                      title: Text(option.label),
                      subtitle: option == SortOption.distance && _currentLocation == null
                          ? Text(
                              _isLoadingLocation ? 'Getting location...' : 'Location required',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: _currentSort == option 
                          ? Icon(Icons.check_rounded, color: Theme.of(context).primaryColor)
                          : null,
                      enabled: option != SortOption.distance || _currentLocation != null,
                      onTap: option == SortOption.distance && _currentLocation == null
                          ? null
                          : () {
                              _updateSort(option);
                              Navigator.pop(context);
                            },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.dateAdded:
        return Icons.access_time_rounded;
      case SortOption.restaurantName:
        return Icons.sort_by_alpha_rounded;
      case SortOption.rating:
        return Icons.star_rounded;
      case SortOption.category:
        return Icons.category_rounded;
      case SortOption.distance:
        return Icons.near_me_rounded;
    }
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Something went wrong', 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(errorMessage, 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.favorite_border_rounded, 
                  size: 64, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text('No favourites yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Start adding your favorite places to see them here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddFavourite,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Favourite'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.search_off_rounded, 
                  size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('No results found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Try adjusting your filters or search terms',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Favourite Card with Expandable Details
class EnhancedFavouriteCard extends StatefulWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Position? currentLocation;
  final bool showDistance;

  const EnhancedFavouriteCard({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
    this.currentLocation,
    this.showDistance = false,
  });

  @override
  State<EnhancedFavouriteCard> createState() => _EnhancedFavouriteCardState();
}

class _EnhancedFavouriteCardState extends State<EnhancedFavouriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: _buildExpandedContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Place image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.favourite.placeCategoryColor.withOpacity(0.1),
                ),
                child: widget.favourite.restaurantImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.favourite.restaurantImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            widget.favourite.placeCategoryIcon,
                            size: 30,
                            color: widget.favourite.placeCategoryColor,
                          ),
                        ),
                      )
                    : Icon(
                        widget.favourite.placeCategoryIcon,
                        size: 30,
                        color: widget.favourite.placeCategoryColor,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.favourite.restaurantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.favourite.placeCategory != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.favourite.placeCategoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.favourite.placeCategoryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.favourite.placeCategory!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: widget.favourite.placeCategoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick info row
          Row(
            children: [
              if (widget.favourite.rating != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.favourite.rating!.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.favourite.priceLevel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.favourite.priceLevel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.favourite.isOpen != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.favourite.isOpen! 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.favourite.isOpen! ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.favourite.isOpen! ? 'Open' : 'Closed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.favourite.isOpen! ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Distance chip (when sorting by distance)
              if (widget.showDistance && widget.currentLocation != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDistance(
                          Geolocator.distanceBetween(
                            widget.currentLocation!.latitude,
                            widget.currentLocation!.longitude,
                            widget.favourite.coordinates.latitude,
                            widget.favourite.coordinates.longitude,
                          ),
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food items (if food place)
                if (widget.favourite.isFoodPlace && widget.favourite.foodNames.isNotEmpty) ...[
                  _buildDetailSection(
                    'Food Items',
                    Icons.restaurant_menu_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.favourite.foodNames.map((food) => 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            food,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact info
                if (widget.favourite.phoneNumber != null || widget.favourite.website != null) ...[
                  _buildDetailSection(
                    'Contact',
                    Icons.contact_phone_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.favourite.phoneNumber != null)
                          _buildContactItem(
                            Icons.phone_rounded,
                            widget.favourite.phoneNumber!,
                            () => widget.onLaunchUrl('tel:${widget.favourite.phoneNumber}'),
                          ),
                        if (widget.favourite.website != null)
                          _buildContactItem(
                            Icons.language_rounded,
                            'Visit Website',
                            () => widget.onLaunchUrl(widget.favourite.website!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timing information
                if (widget.favourite.userOpeningTime != null || 
                    widget.favourite.userClosingTime != null ||
                    widget.favourite.timingNotes != null) ...[
                  _buildDetailSection(
                    'Timing',
                    Icons.access_time_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.favourite.userTimingDisplay.isNotEmpty)
                          Text(
                            widget.favourite.userTimingDisplay,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (widget.favourite.timingNotes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.favourite.timingNotes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (widget.favourite.tags.isNotEmpty) ...[
                  _buildDetailSection(
                    'Tags',
                    Icons.tag_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.favourite.tags.map((tag) => 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (widget.favourite.userNotes != null && widget.favourite.userNotes!.isNotEmpty) ...[
                  _buildDetailSection(
                    'Notes',
                    Icons.note_rounded,
                    child: Text(
                      widget.favourite.userNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Social URLs
                if (widget.favourite.socialUrls.isNotEmpty) ...[
                  _buildDetailSection(
                    'Social Links',
                    Icons.share_rounded,
                    child: Column(
                      children: widget.favourite.socialUrls.map((url) => 
                        _buildContactItem(
                          Icons.link_rounded,
                          'Open Link',
                          () => widget.onLaunchUrl(url),
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Date added
                _buildDetailSection(
                  'Added',
                  Icons.calendar_today_rounded,
                  child: Text(
                    widget.favourite.formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: child,
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}