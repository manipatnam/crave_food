import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers/favourites_provider.dart';
import '../services/google_places_services.dart';
import '../services/clipboard_service.dart';
import '../models/place_model.dart';
import '../models/favourite_model.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AddFavouriteScreen extends StatefulWidget {
  const AddFavouriteScreen({super.key});

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
  
  final GooglePlacesService _placesService = GooglePlacesService();
  
  List<PlaceModel> _searchResults = [];
  PlaceModel? _selectedPlace;
  List<String> _foodItems = [];
  List<String> _socialUrls = [];
  bool _isSearching = false;
  bool _isAdding = false;
  bool _clipboardChecked = false;
  String? _detectedSocialUrl;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    
    // Check clipboard for Instagram/social media links
    _checkClipboardForSocialLinks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _restaurantController.dispose();
    _foodController.dispose();
    _socialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Check clipboard for social media links when screen loads
  Future<void> _checkClipboardForSocialLinks() async {
    if (_clipboardChecked) return;
    
    try {
      print('📋 Checking clipboard for social media links...');
      
      // Check for any social media URL (not just Instagram)
      final socialUrl = await ClipboardService.getSocialMediaLinkFromClipboard();
      
      if (socialUrl != null && mounted) {
        setState(() {
          _detectedSocialUrl = socialUrl;
          _clipboardChecked = true;
        });
        
        // Show dialog to ask user if they want to use the detected link
        _showClipboardDetectionDialog(socialUrl);
      } else {
        setState(() {
          _clipboardChecked = true;
        });
        print('📋 No social media links found in clipboard');
      }
    } catch (e) {
      print('❌ Error checking clipboard: $e');
      setState(() {
        _clipboardChecked = true;
      });
    }
  }

  // Show dialog when social media link is detected
  void _showClipboardDetectionDialog(String url) {
    final platformName = ClipboardService.getPlatformName(url);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForPlatform(platformName),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$platformName Link Detected!',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found a $platformName link in your clipboard. Would you like to add it to this restaurant?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _detectedSocialUrl = null;
                });
              },
              child: Text(
                'No, thanks',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _useSocialUrlFromClipboard(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, add it!'),
            ),
          ],
        );
      },
    );
  }

  // Use the social URL from clipboard
  void _useSocialUrlFromClipboard(String url) {
    setState(() {
      if (!_socialUrls.contains(url)) {
        _socialUrls.add(url);
        _showSnackBar('${ClipboardService.getPlatformName(url)} link added!');
      } else {
        _showSnackBar('This link is already added');
      }
      _detectedSocialUrl = null;
    });
  }

  // Get icon for social media platform
  IconData _getIconForPlatform(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle;
      case 'facebook':
        return Icons.facebook;
      case 'twitter/x':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_video;
      case 'linkedin':
        return Icons.business;
      case 'snapchat':
        return Icons.camera;
      default:
        return Icons.link;
    }
  }

  // Manual clipboard check (when user clicks a button)
  Future<void> _manualClipboardCheck() async {
    final socialUrl = await ClipboardService.getSocialMediaLinkFromClipboard();
    
    if (socialUrl != null) {
      _showClipboardDetectionDialog(socialUrl);
    } else {
      _showSnackBar('No social media links found in clipboard', isError: true);
    }
  }

  Future<void> _searchRestaurants(String query) async {
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

  Future<void> _saveFavourite() async {
    print('💾 _saveFavourite called');
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user');
      _showSnackBar('You must be logged in to add favourites', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    
    if (_selectedPlace == null) {
      print('❌ No place selected');
      _showSnackBar('Please select a restaurant', isError: true);
      return;
    }

    if (_foodItems.isEmpty) {
      print('⚠️ No food items added');
      _showSnackBar('Please add at least one food item', isError: true);
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
            print('🔙 Navigating back to favourites screen');
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
                  'Add Favourite',
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
                        _buildRestaurantSearchSection(),
                        const SizedBox(height: 24),
                        _buildSelectedPlaceCard(),
                        const SizedBox(height: 24),
                        _buildFoodItemsSection(),
                        const SizedBox(height: 24),
                        _buildSocialUrlsSection(),
                        const SizedBox(height: 24),
                        _buildNotesSection(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
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

  Widget _buildSocialUrlsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Social Media Links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Clipboard check button
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _manualClipboardCheck,
                  icon: const Icon(
                    Icons.content_paste,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Check clipboard for links',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share from Instagram/social media and we\'ll auto-detect the link!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _socialController,
                  hintText: 'https://instagram.com/restaurant...',
                  prefixIcon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _addSocialUrl,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Social URLs Display (rest of the implementation remains the same)
          if (_socialUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: _socialUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                
                IconData iconData = Icons.link;
                Color iconColor = Colors.blue;
                String platformName = 'Link';
                
                if (url.contains('instagram')) {
                  iconData = Icons.camera_alt;
                  iconColor = Colors.purple;
                  platformName = 'Instagram';
                } else if (url.contains('youtube')) {
                  iconData = Icons.play_circle;
                  iconColor = Colors.red;
                  platformName = 'YouTube';
                } else if (url.contains('facebook')) {
                  iconData = Icons.facebook;
                  iconColor = Colors.blue;
                  platformName = 'Facebook';
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              platformName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                            Text(
                              url,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeSocialUrl(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Complete implementation of other sections
  Widget _buildRestaurantSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search Restaurant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _restaurantController,
            hintText: 'Search for a restaurant...',
            prefixIcon: Icons.search,
            onChanged: _searchRestaurants,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a restaurant';
              }
              if (_selectedPlace == null) {
                return 'Please select a restaurant from the search results';
              }
              return null;
            },
          ),
          
          // Search Results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Searching restaurants...'),
                  ],
                ),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _searchResults.map((place) => _buildSearchResultTile(place)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(PlaceModel place) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.grey[200],
            child: place.photoUrl != null
                ? Image.network(
                    place.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.restaurant,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Icon(
                    Icons.restaurant,
                    color: Theme.of(context).primaryColor,
                  ),
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.displayAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (place.rating != null || place.cuisineTypes.isNotEmpty)
              const SizedBox(height: 4),
            Row(
              children: [
                if (place.rating != null) ...[
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
                if (place.rating != null && place.cuisineTypes.isNotEmpty)
                  const Text(' • ', style: TextStyle(fontSize: 12)),
                if (place.cuisineTypes.isNotEmpty)
                  Expanded(
                    child: Text(
                      place.cuisineTypes,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.add_circle,
          color: Theme.of(context).primaryColor,
        ),
        onTap: () => _selectPlace(place),
      ),
    );
  }

  Widget _buildSelectedPlaceCard() {
    if (_selectedPlace == null) return const SizedBox.shrink();

    return Container(
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
                      'Selected Restaurant',
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
          IconButton(
            onPressed: () {
              setState(() {
                _selectedPlace = null;
                _restaurantController.clear();
              });
            },
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fastfood,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Food Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_foodItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_foodItems.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _foodController,
                  hintText: 'Add a food item...',
                  prefixIcon: Icons.restaurant_menu,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _addFoodItem,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Food Items Display
          if (_foodItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _foodItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeFoodItem(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.note_alt,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '(Optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _notesController,
            hintText: 'Add any notes about this restaurant...',
            prefixIcon: Icons.edit_note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isAdding ? null : _saveFavourite,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAdding)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isAdding ? 'Adding to Favourites...' : 'Add to Favourites',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}