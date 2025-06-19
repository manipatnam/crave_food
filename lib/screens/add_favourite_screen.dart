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
import '../widgets/add_favourite/restaurant_search_section.dart';
import '../widgets/add_favourite/selected_place_card.dart';
import '../widgets/add_favourite/food_items_section.dart';
import '../widgets/add_favourite/social_urls_section.dart';
import '../widgets/add_favourite/dietary_options_section.dart';
import '../widgets/add_favourite/timing_information_section.dart';
import '../widgets/add_favourite/tags_section.dart';
import '../widgets/add_favourite/notes_section.dart';
import '../widgets/add_favourite/save_button.dart';

class AddFavouriteScreen extends StatefulWidget {
  final PlaceModel? prefilledPlace;
  
  const AddFavouriteScreen({super.key, this.prefilledPlace});

  @override
  State<AddFavouriteScreen> createState() => _AddFavouriteScreenState();
}

class _AddFavouriteScreenState extends State<AddFavouriteScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _foodController = TextEditingController();
  final _socialController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  final _timingNotesController = TextEditingController();
  
  final GooglePlacesService _placesService = GooglePlacesService();
  
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedPlace;
  PlaceModel? _prefilledPlace;
  List<String> _foodItems = [];
  List<String> _socialUrls = [];
  List<String> _tags = [];
  bool _isSearching = false;
  bool _isAdding = false;
  
  // New fields
  bool _isVegetarianAvailable = false;
  bool _isNonVegetarianAvailable = false;
  TimeOfDay? _userOpeningTime;
  TimeOfDay? _userClosingTime;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Auto-fill data if place is provided from search screen
    if (widget.prefilledPlace != null) {
      print('🎯 Pre-filling data from search screen: ${widget.prefilledPlace!.name}');
      _prefilledPlace = widget.prefilledPlace;
      _selectedPlace = widget.prefilledPlace;
      _restaurantController.text = widget.prefilledPlace!.name;
      
      // Show success message that restaurant is pre-filled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Restaurant details loaded from search!');
      });
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _restaurantController.dispose();
    _foodController.dispose();
    _socialController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _timingNotesController.dispose();
    super.dispose();
  }

  Future<void> _searchRestaurants(String query) async {
    // If we have a prefilled place and user hasn't changed the text, don't search
    if (widget.prefilledPlace != null && query == widget.prefilledPlace!.name) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _placesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showSnackBar('Error searching: $e', isError: true);
      }
    }
  }

  void _selectPlace(PlaceModel place) {
    print('📍 Selected place: ${place.name}');
    setState(() {
      _selectedPlace = place;
      _restaurantController.text = place.name;
      _searchResults = [];
    });
  }

  void _addFoodItem() {
    if (_foodController.text.trim().isNotEmpty) {
      setState(() {
        _foodItems.add(_foodController.text.trim());
        _foodController.clear();
      });
      print('🍕 Added food item. Total: ${_foodItems.length}');
    }
  }

  void _removeFoodItem(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
  }

  void _addSocialUrl() {
    final url = _socialController.text.trim();
    if (url.isNotEmpty && _isValidUrl(url)) {
      setState(() {
        _socialUrls.add(url);
        _socialController.clear();
      });
    } else {
      _showSnackBar('Please enter a valid URL', isError: true);
    }
  }

  void _removeSocialUrl(int index) {
    setState(() {
      _socialUrls.removeAt(index);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    } else if (_tags.contains(tag)) {
      _showSnackBar('Tag already added', isError: true);
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _addSocialUrlFromClipboard(String url) {
    setState(() {
      if (!_socialUrls.contains(url)) {
        _socialUrls.add(url);
        _showSnackBar('${ClipboardService.getPlatformName(url)} link added!');
      } else {
        _showSnackBar('This link is already added');
      }
    });
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    if (_selectedPlace == null) {
      _showSnackBar('Please select a restaurant', isError: true);
      return false;
    }

    if (_foodItems.isEmpty) {
      _showSnackBar('Please add at least one food item', isError: true);
      return false;
    }

    if (!_isVegetarianAvailable && !_isNonVegetarianAvailable) {
      _showSnackBar('Please select at least one dietary option', isError: true);
      return false;
    }

    return true;
  }

  Future<void> _saveFavourite() async {
    print('💾 _saveFavourite called');
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user');
      _showSnackBar('You must be logged in to add favourites', isError: true);
      return;
    }

    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final favourite = Favourite(
        id: '',
        restaurantName: _selectedPlace!.name,
        googlePlaceId: _selectedPlace!.placeId,
        coordinates: _selectedPlace!.geoPoint,
        foodNames: _foodItems,
        socialUrls: _socialUrls,
        dateAdded: DateTime.now(),
        userId: currentUser.uid,
        userNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
        restaurantImageUrl: _selectedPlace!.photoUrl,
        rating: _selectedPlace!.rating,
        priceLevel: _selectedPlace!.priceLevel,
        cuisineType: _selectedPlace!.cuisineTypes,
        phoneNumber: _selectedPlace!.phoneNumber,
        website: _selectedPlace!.website,
        isOpen: _selectedPlace!.isOpen,
        // New fields
        isVegetarianAvailable: _isVegetarianAvailable,
        isNonVegetarianAvailable: _isNonVegetarianAvailable,
        userOpeningTime: _userOpeningTime,
        userClosingTime: _userClosingTime,
        timingNotes: _timingNotesController.text.isNotEmpty ? _timingNotesController.text : null,
        tags: _tags,
      );

      print('🔄 Calling favouritesProvider.addFavourite...');
      
      final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
      
      final success = await favouritesProvider.addFavourite(favourite)
          .timeout(const Duration(seconds: 30));
      
      if (mounted) {
        setState(() {
          _isAdding = false;
        });

        if (success) {
          print('✅ Favourite added successfully!');
          _showSnackBar('Favourite added successfully!');
          
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (mounted) {
            print('🔙 Navigating back to search screen');
            Navigator.pop(context, true);
          }
        } else {
          print('❌ Failed to add favourite');
          final errorMessage = favouritesProvider.errorMessage ?? 'Failed to add favourite. Please try again.';
          _showSnackBar(errorMessage, isError: true);
        }
      }
    } on TimeoutException catch (timeoutError) {
      print('⏰ Timeout error: $timeoutError');
      
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        
        _showSnackBar('Request timed out. The favourite may have been added successfully.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Exception in _saveFavourite: $e');
      
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
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
              child: FlexibleSpaceBar(
                title: Text(
                  widget.prefilledPlace != null ? 'Add to Favourites' : 'Add Favourite',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
              ),
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
                        // Clipboard detector (only show if not prefilled)
                        if (widget.prefilledPlace == null)
                          ClipboardDetector(
                            onSocialUrlDetected: _addSocialUrlFromClipboard,
                          ),
                        
                        // Restaurant search section (only show if not prefilled)
                        if (widget.prefilledPlace == null) ...[
                          RestaurantSearchSection(
                            controller: _restaurantController,
                            searchResults: _searchResults,
                            isSearching: _isSearching,
                            selectedPlace: _selectedPlace,
                            onSearch: _searchRestaurants,
                            onSelectPlace: _selectPlace,
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Selected place card (always show if we have a selected place)
                        if (_selectedPlace != null) ...[
                          // Only show the card if it's not prefilled, or show without clear button if prefilled
                          widget.prefilledPlace != null 
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).primaryColor.withOpacity(0.1),
                                      Theme.of(context).primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: _selectedPlace!.photoUrl != null
                                            ? Image.network(
                                                _selectedPlace!.photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.restaurant,
                                                  size: 40,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              )
                                            : Icon(
                                                Icons.restaurant,
                                                size: 40,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Theme.of(context).primaryColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'From Search',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedPlace!.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (_selectedPlace!.rating != null || _selectedPlace!.cuisineTypes.isNotEmpty)
                                            Row(
                                              children: [
                                                if (_selectedPlace!.rating != null) ...[
                                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _selectedPlace!.rating!.toStringAsFixed(1),
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                                if (_selectedPlace!.rating != null && _selectedPlace!.cuisineTypes.isNotEmpty)
                                                  const Text(' • ', style: TextStyle(fontSize: 12)),
                                                if (_selectedPlace!.cuisineTypes.isNotEmpty)
                                                  Expanded(
                                                    child: Text(
                                                      _selectedPlace!.cuisineTypes,
                                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SelectedPlaceCard(
                                selectedPlace: _selectedPlace,
                                onClear: () {
                                  setState(() {
                                    _selectedPlace = null;
                                    _restaurantController.clear();
                                  });
                                },
                              ),
                          const SizedBox(height: 24),
                        ],
                        
                        FoodItemsSection(
                          controller: _foodController,
                          foodItems: _foodItems,
                          onAddItem: _addFoodItem,
                          onRemoveItem: _removeFoodItem,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // NEW: Dietary Options Section
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
                        
                        // NEW: Timing Information Section
                        TimingInformationSection(
                          selectedPlace: _selectedPlace,
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
                        
                        // NEW: Tags Section
                        TagsSection(
                          controller: _tagController,
                          tags: _tags,
                          onAddTag: _addTag,
                          onRemoveTag: _removeTag,
                        ),
                        
                        const SizedBox(height: 24),
                        
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
                        
                        NotesSection(
                          controller: _notesController,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        SaveButton(
                          isAdding: _isAdding,
                          onSave: _saveFavourite,
                        ),
                        
                        const SizedBox(height: 20),
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
}