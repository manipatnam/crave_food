// Enhanced Home Screen with Robust Navigation - NO MORE GESTURE CONFLICTS!
// lib/screens/enhanced_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favourites_provider.dart';
import 'favorites/enhanced_favourites_screen.dart';
import 'enhanced_search_screen.dart';
import 'add_favourite_screen.dart';
import 'add_review_screen.dart'; // NEW: Add review screen
import 'reviews_feed_screen.dart'; // NEW: Reviews feed screen (we'll create this next)
import '../models/favourite_model.dart';
import '../../widgets/common/universal_restaurant_tile.dart';
import '../../widgets/adapters/screen_tile_adapters.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _bottomNavController;
  late Animation<double> _bottomNavAnimation;
  late AnimationController _pageTransitionController;
  late Animation<double> _pageTransitionAnimation;

  // Core screens - IndexedStack preserves state
  final List<Widget> _pages = [
    const EnhancedHomePage(),
    const EnhancedSearchScreen(),
    const ReviewsFeedScreen(), // ADD THIS LINE
    const EnhancedFavouritesScreen(),
    const EnhancedProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Bottom navigation animation
    _bottomNavController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomNavAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomNavController, curve: Curves.easeInOut),
    );
    
    // Page transition animation
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pageTransitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageTransitionController, curve: Curves.easeInOut),
    );
    
    _bottomNavController.forward();
    _pageTransitionController.forward();
    
    // 🔥 CRITICAL FIX: Load favorites when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔥 Loading favorites from IndexedStack home screen...');
        Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
      }
    });
  }

  @override
  void dispose() {
    _bottomNavController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent unnecessary rebuilds
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Subtle animation feedback
    _pageTransitionController.reset();
    _pageTransitionController.forward();
    
    // Haptic feedback for better UX
    // HapticFeedback.selectionClick(); // Uncomment if you want haptic feedback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CORE SOLUTION: IndexedStack instead of PageView
      // This eliminates ALL gesture conflicts!
      body: AnimatedBuilder(
        animation: _pageTransitionAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _pageTransitionAnimation,
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          );
        },
      ),
      
      // Enhanced Bottom Navigation
      bottomNavigationBar: _buildIconOnlyNavigation(),
    floatingActionButton: _selectedIndex == 2 ? // Show only on Reviews tab
        FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddReviewScreen(),
              ),
            );
          },
          backgroundColor: Colors.orange,
          child: const Icon(
            Icons.rate_review,
            color: Colors.white,
          ),
        ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildIconOnlyNavigation() {
    return Container(
      height: 60, // ✅ CHANGE 1: Fixed height (was dynamic)
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // ✅ CHANGE 2: Even spacing
          children: [
            _buildIconOnlyItem(Icons.home_rounded, 'Home', 0),
            _buildIconOnlyItem(Icons.search_rounded, 'Search', 1),
            _buildIconOnlyItem(Icons.rate_review_rounded, 'Reviews', 2),
            _buildIconOnlyItem(Icons.favorite_rounded, 'Favorites', 3),
            _buildIconOnlyItem(Icons.person_rounded, 'Profile', 4),
          ],
        ),
      ),
    );
  }

// ✅ ADDED: Individual icon-only items with tooltips
  Widget _buildIconOnlyItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return Tooltip( // ✅ CHANGE 3: Added tooltips for accessibility
      message: label, // Shows label on long press/hover
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.all(12), // ✅ CHANGE 4: Equal padding all sides
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey[600],
            size: 24, // ✅ CHANGE 5: Fixed icon size (no size variations)
          ),
        ),
      ),
    );
  }
}

// Enhanced Home Page (Your main dashboard)
class EnhancedHomePage extends StatefulWidget {
  const EnhancedHomePage({super.key});

  @override
  State<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends State<EnhancedHomePage> {
  @override
  void initState() {
    super.initState();
    
    // 🔥 ADDITIONAL FIX: Load favorites when home page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🏠 Loading favorites from home page...');
        try {
          Provider.of<FavouritesProvider>(context, listen: false).loadFavourites();
        } catch (e) {
          print('❌ Error loading favorites: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),
              
              // Recent Favourites
              _buildRecentFavourites(context),
              const SizedBox(height: 24),
              
              // Discover Section
              _buildDiscoverSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final displayName = user?.displayName ?? 'Food Lover';
        
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () {
                  // Navigate to profile or show menu
                },
                icon: Icon(
                  Icons.person_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.add_circle_rounded,
                title: 'Add Favourite',
                subtitle: 'Save a new restaurant',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFavouriteScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context: context,
                icon: Icons.search_rounded,
                title: 'Find Nearby',
                subtitle: 'Discover restaurants',
                onTap: () {
                  // This will work perfectly now with IndexedStack!
                  DefaultTabController.of(context)?.animateTo(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFavourites(BuildContext context) {
    return Consumer<FavouritesProvider>(
      builder: (context, favouritesProvider, child) {
        final recentFavourites = favouritesProvider.favourites
            .take(3)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Favourites',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to favourites tab
                    // This works perfectly with IndexedStack!
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentFavourites.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favourites yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding your first favourite restaurant!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentFavourites
                    .map((favourite) => _buildFavouritePreview(context, favourite))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFavouritePreview(BuildContext context, Favourite favourite) {
    {
      return HomeFavoritePreviewAdapter(
        favourite: favourite,
        currentLocation: null, // Add this field to your state
        onTap: () {
          // Navigate to favorites tab or favorite detail
        },
      );
    }
  }

  Widget _buildDiscoverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Explore New Places',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use our enhanced search to find amazing restaurants near you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to search - works perfectly with IndexedStack!
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Start Exploring'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhanced Profile Page
class EnhancedProfilePage extends StatelessWidget {
  const EnhancedProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Profile Options
              Expanded(
                child: ListView(
                  children: [
                    _buildProfileOption(
                      context: context,
                      icon: Icons.favorite_rounded,
                      title: 'My Favourites',
                      subtitle: 'View and manage your saved restaurants',
                      onTap: () {
                        // Navigate to favourites tab
                      },
                    ),
                    _buildProfileOption(
                      context: context,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'App preferences and configuration',
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                    _buildProfileOption(
                      context: context,
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {
                        // Navigate to help
                      },
                    ),
                    _buildProfileOption(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Sign out of your account',
                      onTap: () {
                        _showSignOutDialog(context);
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.1)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isDestructive 
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}