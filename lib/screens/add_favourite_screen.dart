// Updated Add Favourite Screen with Place Categories
// lib/screens/add_favourite_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers/favourites_provider.dart';
import '../services/google_places_services.dart';
import '../services/clipboard_service.dart';
import '../models/place_model.dart';
import '../models/favourite_model.dart';
import '../widgets/add_favourite/clipboard_detector.dart';
import '../widgets/add_favourite/place_search_section.dart';
import '../widgets/add_favourite/selected_place_card.dart';
import '../widgets/add_favourite/place_category_section.dart';
import '../widgets/add_favourite/food_place_type_section.dart';
import '../widgets/add_favourite/food_items_section.dart';
import '../widgets/add_favourite/social_urls_section.dart';
import '../widgets/add_favourite/dietary_options_section.dart';
import '../widgets/add_favourite/timing_information_section.dart';
import '../widgets/add_favourite/tags_section.dart';
import '../widgets/add_favourite/notes_section.dart';
import '../widgets/add_favourite/save_button.dart';

import '../../models/visit_status.dart';
import '../../widgets/visit_status/visit_status_selector.dart';

// Place Categories
enum PlaceCategory {
  foodDining('Food & Dining', Icons.restaurant_menu_rounded, Color(0xFFFF6B35)),
  activities('Activities', Icons.local_activity_rounded, Color(0xFF2196F3)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFF4CAF50)),
  accommodation('Accommodation', Icons.hotel_rounded, Color(0xFF9C27B0)),
  entertainment('Entertainment', Icons.theater_comedy_rounded, Color(0xFFE91E63)),
  other('Other', Icons.place_rounded, Color(0xFF607D8B));

  const PlaceCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// Food Place Types (sub-categories for Food & Dining)
enum FoodPlaceType {
  restaurant('Restaurant', Icons.restaurant_rounded, '🍽️'),
  cafe('Cafe', Icons.local_cafe_rounded, '☕'),
  pubBar('Pub/Bar', Icons.local_bar_rounded, '🍺'),
  fastFood('Fast Food', Icons.fastfood_rounded, '🍕'),
  dessert('Dessert/Sweets', Icons.cake_rounded, '🍦'),
  streetFood('Street Food', Icons.food_bank_rounded, '🥘'),
  specialty('Specialty', Icons.restaurant_menu_rounded, '🍱'),
  other('Other Food Place', Icons.more_horiz_rounded, '❓');

  const FoodPlaceType(this.label, this.icon, this.emoji);
  final String label;
  final IconData icon;
  final String emoji;
}

class AddFavouriteScreen extends StatefulWidget {
  final PlaceModel? prefilledPlace;
  
  const AddFavouriteScreen({super.key, this.prefilledPlace});

  @override
  State<AddFavouriteScreen> createState() => _AddFavouriteScreenState();
}

class _AddFavouriteScreenState extends State<AddFavouriteScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController(); // Changed from _restaurantController
  final _foodController = TextEditingController();
  final _socialController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  final _timingNotesController = TextEditingController();
  
  final GooglePlacesService _placesService = GooglePlacesService();
  
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedPlace;
  PlaceModel? _prefilledPlace;
  
  // Category and Type Selection
  PlaceCategory? _selectedCategory;
  FoodPlaceType? _selectedFoodPlaceType;
  
  List<String> _foodItems = [];
  List<String> _socialUrls = [];
  List<String> _tags = [];
  bool _isSearching = false;
  bool _isAdding = false;
  
  // Form fields
  bool _isVegetarianAvailable = false;
  bool _isNonVegetarianAvailable = false;
  TimeOfDay? _userOpeningTime;
  TimeOfDay? _userClosingTime;

  VisitStatus _selectedVisitStatus = VisitStatus.notVisited;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;


  Widget _buildVisitStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: VisitStatusSelector(
        selectedStatus: _selectedVisitStatus,
        onStatusChanged: (status) {
          setState(() {
            _selectedVisitStatus = status;
          });
        },
        isCompact: false,
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Auto-fill data if place is provided from search screen
    if (widget.prefilledPlace != null) {
      print('🎯 Pre-filling data from search screen: ${widget.prefilledPlace!.name}');
      _prefilledPlace = widget.prefilledPlace;
      _selectedPlace = widget.prefilledPlace;
      _placeController.text = widget.prefilledPlace!.name;
      
      // Show success message that place is pre-filled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Place details loaded from search!');
      });
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _placeController.dispose();
    _foodController.dispose();
    _socialController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _timingNotesController.dispose();
    super.dispose();
  }

  // Search for places (updated from restaurant search)
  Future<void> _searchPlaces(String query) async {
    // Don't search if query is empty or too short
    if (query.trim().isEmpty || query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Don't search if this is the selected place name
    if (_selectedPlace != null && query.trim() == _selectedPlace!.name) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = []; // Clear previous results
    });

    try {
      print('🔍 Searching for places: $query');
      final results = await _placesService.searchPlaces(query.trim());
      
      // Only update if we're still searching for the same query
      if (mounted && _placeController.text.trim() == query.trim()) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        print('✅ Found ${results.length} places');
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        _showSnackBar('Error searching places: $e', isError: true);
      }
    }
  }

  void _selectPlace(PlaceModel place) {
    setState(() {
      _selectedPlace = place;
      _placeController.text = place.name;
      _searchResults = []; // Clear search results immediately
    });
    
    print('✅ Selected place: ${place.name}');
    _showSnackBar('Place selected: ${place.name}');
  }

  // Category selection
  void _selectCategory(PlaceCategory category) {
    setState(() {
      _selectedCategory = category;
      // Reset food place type if changing away from food & dining
      if (category != PlaceCategory.foodDining) {
        _selectedFoodPlaceType = null;
        // Clear food-related data
        _foodItems.clear();
        _isVegetarianAvailable = false;
        _isNonVegetarianAvailable = false;
      }
    });
    
    print('📂 Selected category: ${category.label}');
  }

  void _selectFoodPlaceType(FoodPlaceType type) {
    setState(() {
      _selectedFoodPlaceType = type;
    });
    
    print('🍽️ Selected food place type: ${type.label}');
  }

  // Food items management
  void _addFoodItem() {
    final item = _foodController.text.trim();
    if (item.isNotEmpty && !_foodItems.contains(item)) {
      setState(() {
        _foodItems.add(item);
        _foodController.clear();
      });
      print('➕ Added food item: $item');
    }
  }

  void _removeFoodItem(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
    print('➖ Removed food item at index: $index');
  }

  // Social URLs management
  void _addSocialUrl() {
    final url = _socialController.text.trim();
    if (url.isNotEmpty && !_socialUrls.contains(url)) {
      setState(() {
        _socialUrls.add(url);
        _socialController.clear();
      });
      print('🔗 Added social URL: $url');
    }
  }

  void _addSocialUrlFromClipboard(String url) {
    if (!_socialUrls.contains(url)) {
      setState(() {
        _socialUrls.add(url);
      });
      _showSnackBar('Social media link added from clipboard!');
      print('📋 Added social URL from clipboard: $url');
    } else {
      _showSnackBar('This link is already added', isError: true);
    }
  }

  void _removeSocialUrl(int index) {
    setState(() {
      _socialUrls.removeAt(index);
    });
    print('🗑️ Removed social URL at index: $index');
  }

  // Tags management
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      print('🏷️ Added tag: $tag');
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
    print('🗑️ Removed tag at index: $index');
  }

  // Save favourite
  Future<void> _saveFavourite() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_selectedPlace == null) {
      _showSnackBar('Please select a place', isError: true);
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('Please select a place category', isError: true);
      return;
    }

    // If food & dining category, food place type is required
    if (_selectedCategory == PlaceCategory.foodDining && _selectedFoodPlaceType == null) {
      _showSnackBar('Please select a food place type', isError: true);
      return;
    }

    // REMOVED: Dietary options validation - now optional
    // REMOVED: Food items validation - now optional

    setState(() {
      _isAdding = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Create favourite with new fields
      final favourite = Favourite(
        id: '', // Will be set by Firestore
        restaurantName: _selectedPlace!.name, // Keep this field name for compatibility
        googlePlaceId: _selectedPlace!.placeId,
        coordinates: _selectedPlace!.geoPoint,
        foodNames: _foodItems, // Will be empty for non-food places
        socialUrls: _socialUrls,
        dateAdded: DateTime.now(),
        userId: currentUser.uid,
        userNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        restaurantImageUrl: _selectedPlace!.photoUrl,
        rating: _selectedPlace!.rating,
        priceLevel: _selectedPlace!.priceLevel,
        cuisineType: _selectedPlace!.types?.join(', '),
        phoneNumber: _selectedPlace!.phoneNumber,
        website: _selectedPlace!.website,
        isOpen: _selectedPlace!.isOpen,
        // New category fields
        isVegetarianAvailable: _isVegetarianAvailable,
        isNonVegetarianAvailable: _isNonVegetarianAvailable,
        userOpeningTime: _userOpeningTime,
        userClosingTime: _userClosingTime,
        timingNotes: _timingNotesController.text.trim().isEmpty ? null : _timingNotesController.text.trim(),
        tags: [
          ..._tags,
          _selectedCategory!.label, // Add category as a tag
          if (_selectedFoodPlaceType != null) _selectedFoodPlaceType!.label, // Add food type as tag
        ],
        visitStatus: _selectedVisitStatus,
      );

      final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
      final success = await favouritesProvider.addFavourite(favourite);

      if (success) {
        _showSnackBar('Place added to favourites successfully!');
        Navigator.pop(context, true);
      } else {
        throw 'Failed to add favourite';
      }
    } catch (e) {
      print('❌ Error saving favourite: $e');
      _showSnackBar('Error saving favourite: $e', isError: true);
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(_selectedVisitStatus.emoji),
            const SizedBox(width: 8),
            Text(
              _selectedVisitStatus == VisitStatus.visited
                  ? 'Great choice! Added to visited places 🎉'
                  : _selectedVisitStatus == VisitStatus.planned
                      ? 'Added to your planning list! 📅'
                      : 'Added to your favorites! ❤️',
            ),
          ],
        ),
        backgroundColor: _selectedVisitStatus.color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Check if we should show food-related sections
  bool get _shouldShowFoodSections {
    return _selectedCategory == PlaceCategory.foodDining;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _selectedPlace != null 
                  ? 'Add to Favourites'
                  : 'Search Places',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Always show clipboard detector and search section at the top
                        if (widget.prefilledPlace == null) ...[
                          ClipboardDetector(
                            onSocialUrlDetected: _addSocialUrlFromClipboard,
                          ),
                          
                          PlaceSearchSection(
                            controller: _placeController,
                            searchResults: _searchResults,
                            isSearching: _isSearching,
                            selectedPlace: _selectedPlace,
                            onSearch: _searchPlaces,
                            onSelectPlace: _selectPlace,
                          ),
                        ],
                        
                        // Show all other sections ONLY after a place is selected (like in Add Review)
                        if (_selectedPlace != null) ...[
                          const SizedBox(height: 24),
                          
                          // Selected place card
                          SelectedPlaceCard(
                            selectedPlace: _selectedPlace!,
                            onClear: () {
                              setState(() {
                                _selectedPlace = null;
                                _placeController.clear();
                                _selectedCategory = null;
                                _selectedFoodPlaceType = null;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Place Category Selection
                          PlaceCategorySection(
                            selectedCategory: _selectedCategory,
                            onCategorySelected: _selectCategory,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Food Place Type Selection (show if Food & Dining is selected)
                          if (_selectedCategory == PlaceCategory.foodDining) ...[
                            FoodPlaceTypeSection(
                              selectedType: _selectedFoodPlaceType,
                              onTypeSelected: _selectFoodPlaceType,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Food Items Section (only for food & dining places)
                          if (_shouldShowFoodSections && _selectedFoodPlaceType != null) ...[
                            FoodItemsSection(
                              controller: _foodController,
                              foodItems: _foodItems,
                              onAddItem: _addFoodItem,
                              onRemoveItem: _removeFoodItem,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Dietary Options Section (only for food & dining places)
                          if (_shouldShowFoodSections && _selectedFoodPlaceType != null) ...[
                            DietaryOptionsSection(
                              isVegetarianAvailable: _isVegetarianAvailable,
                              isNonVegetarianAvailable: _isNonVegetarianAvailable,
                              onVegetarianChanged: (value) {
                                setState(() {
                                  _isVegetarianAvailable = value ?? false;
                                });
                              },
                              onNonVegetarianChanged: (value) {
                                setState(() {
                                  _isNonVegetarianAvailable = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Timing Information Section
                          TimingInformationSection(
                            selectedPlace: _selectedPlace!,
                            userOpeningTime: _userOpeningTime,
                            userClosingTime: _userClosingTime,
                            timingNotesController: _timingNotesController,
                            onOpeningTimeChanged: (time) {
                              setState(() {
                                _userOpeningTime = time;
                              });
                            },
                            onClosingTimeChanged: (time) {
                              setState(() {
                                _userClosingTime = time;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Tags Section
                          TagsSection(
                            controller: _tagController,
                            tags: _tags,
                            onAddTag: _addTag,
                            onRemoveTag: _removeTag,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Visit Status Section
                          _buildVisitStatusSection(),
                          
                          // Social URLs Section
                          SocialUrlsSection(
                            controller: _socialController,
                            socialUrls: _socialUrls,
                            onAddUrl: _addSocialUrl,
                            onRemoveUrl: _removeSocialUrl,
                            onClipboardCheck: () async {
                              final socialUrl = await ClipboardService.getSocialMediaLinkFromClipboard();
                              if (socialUrl != null) {
                                _addSocialUrlFromClipboard(socialUrl);
                              } else {
                                _showSnackBar('No social media links found in clipboard', isError: true);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Notes Section
                          NotesSection(
                            controller: _notesController,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Save Button
                          SaveButton(
                            isAdding: _isAdding,
                            onSave: _saveFavourite,
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFoodItemsPlaceholder() {
    if (_selectedFoodPlaceType == null) return 'Food items (optional)';
    
    switch (_selectedFoodPlaceType!) {
      case FoodPlaceType.restaurant:
        return 'Dishes you tried or want to try (optional)';
      case FoodPlaceType.cafe:
        return 'Drinks, pastries, or food items (optional)';
      case FoodPlaceType.pubBar:
        return 'Drinks, appetizers, or food (optional)';
      case FoodPlaceType.fastFood:
        return 'Menu items you ordered (optional)';
      case FoodPlaceType.dessert:
        return 'Desserts or sweets (optional)';
      case FoodPlaceType.streetFood:
        return 'Street food items (optional)';
      case FoodPlaceType.specialty:
        return 'Specialty items (optional)';
      case FoodPlaceType.other:
        return 'Food items (optional)';
    }
  }
}