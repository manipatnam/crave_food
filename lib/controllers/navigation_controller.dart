// Smart Navigation Controller - Advanced Gesture Management
// lib/controllers/navigation_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NavigationController extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _isMapInteractionActive = false;
  bool _isSearchActive = false;
  
  // Navigation state
  int get selectedIndex => _selectedIndex;
  bool get isMapInteractionActive => _isMapInteractionActive;
  bool get isSearchActive => _isSearchActive;
  bool get isSearchScreen => _selectedIndex == 1;
  
  // Navigation methods
  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      _resetInteractionStates();
      notifyListeners();
    }
  }
  
  void setMapInteraction(bool active) {
    if (_isMapInteractionActive != active) {
      _isMapInteractionActive = active;
      notifyListeners();
    }
  }
  
  void setSearchActive(bool active) {
    if (_isSearchActive != active) {
      _isSearchActive = active;
      notifyListeners();
    }
  }
  
  void _resetInteractionStates() {
    _isMapInteractionActive = false;
    _isSearchActive = false;
  }
  
  // Navigation helpers
  void navigateToSearch() => setSelectedIndex(1);
  void navigateToFavourites() => setSelectedIndex(2);
  void navigateToHome() => setSelectedIndex(0);
  void navigateToProfile() => setSelectedIndex(3);
  
  // Gesture control
  bool get shouldBlockSwipeNavigation {
    return isSearchScreen && (_isMapInteractionActive || _isSearchActive);
  }
  
  // Screen transitions
  String get currentScreenName {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Favourites';
      case 3:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }
}

// Enhanced Navigation Provider
class NavigationProvider extends ChangeNotifier {
  final NavigationController _controller = NavigationController();
  
  NavigationController get controller => _controller;
  
  int get selectedIndex => _controller.selectedIndex;
  bool get isMapInteractionActive => _controller.isMapInteractionActive;
  bool get isSearchActive => _controller.isSearchActive;
  bool get isSearchScreen => _controller.isSearchScreen;
  bool get shouldBlockSwipeNavigation => _controller.shouldBlockSwipeNavigation;
  
  void setSelectedIndex(int index) {
    _controller.setSelectedIndex(index);
    notifyListeners();
  }
  
  void setMapInteraction(bool active) {
    _controller.setMapInteraction(active);
    notifyListeners();
  }
  
  void setSearchActive(bool active) {
    _controller.setSearchActive(active);
    notifyListeners();
  }
  
  // Quick navigation methods
  void navigateToSearch() {
    _controller.navigateToSearch();
    notifyListeners();
  }
  
  void navigateToFavourites() {
    _controller.navigateToFavourites();
    notifyListeners();
  }
  
  void navigateToHome() {
    _controller.navigateToHome();
    notifyListeners();
  }
  
  void navigateToProfile() {
    _controller.navigateToProfile();
    notifyListeners();
  }
}

// Gesture-Aware Search Screen Wrapper
class GestureAwareSearchScreen extends StatefulWidget {
  final Widget child;
  
  const GestureAwareSearchScreen({
    super.key,
    required this.child,
  });

  @override
  State<GestureAwareSearchScreen> createState() => _GestureAwareSearchScreenState();
}

class _GestureAwareSearchScreenState extends State<GestureAwareSearchScreen> {
  bool _isMapInteracting = false;
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Detect when user is interacting with scrollable content
        if (notification is ScrollStartNotification) {
          _setMapInteraction(true);
        } else if (notification is ScrollEndNotification) {
          _setMapInteraction(false);
        }
        return false;
      },
      child: GestureDetector(
        onPanStart: (details) => _setMapInteraction(true),
        onPanEnd: (details) => _setMapInteraction(false),
        onTapDown: (details) => _setMapInteraction(true),
        onTapUp: (details) => _setMapInteraction(false),
        child: widget.child,
      ),
    );
  }
  
  void _setMapInteraction(bool active) {
    if (_isMapInteracting != active) {
      setState(() {
        _isMapInteracting = active;
      });
      
      // Notify the navigation controller
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setMapInteraction(active);
    }
  }
}

// Smart Navigation Stack - Enhanced IndexedStack
class SmartNavigationStack extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> children;
  final Duration transitionDuration;
  
  const SmartNavigationStack({
    super.key,
    required this.selectedIndex,
    required this.children,
    this.transitionDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SmartNavigationStack> createState() => _SmartNavigationStackState();
}

class _SmartNavigationStackState extends State<SmartNavigationStack>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _previousIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.value = 1.0;
  }
  
  @override
  void didUpdateWidget(SmartNavigationStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Previous screen (fading out)
            if (_controller.isAnimating)
              Opacity(
                opacity: 1.0 - _fadeAnimation.value,
                child: IgnorePointer(
                  child: IndexedStack(
                    index: _previousIndex,
                    children: widget.children,
                  ),
                ),
              ),
            // Current screen (fading in)
            Opacity(
              opacity: _fadeAnimation.value,
              child: IndexedStack(
                index: widget.selectedIndex,
                children: widget.children,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Enhanced Map Gesture Handler
class MapGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onMapInteractionStart;
  final VoidCallback? onMapInteractionEnd;
  
  const MapGestureHandler({
    super.key,
    required this.child,
    this.onMapInteractionStart,
    this.onMapInteractionEnd,
  });

  @override
  State<MapGestureHandler> createState() => _MapGestureHandlerState();
}

class _MapGestureHandlerState extends State<MapGestureHandler> {
  bool _isInteracting = false;
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _handleInteractionStart(),
      onPointerUp: (event) => _handleInteractionEnd(),
      onPointerCancel: (event) => _handleInteractionEnd(),
      child: GestureDetector(
        onPanStart: (details) => _handleInteractionStart(),
        onPanEnd: (details) => _handleInteractionEnd(),
        onScaleStart: (details) => _handleInteractionStart(),
        onScaleEnd: (details) => _handleInteractionEnd(),
        child: widget.child,
      ),
    );
  }
  
  void _handleInteractionStart() {
    if (!_isInteracting) {
      _isInteracting = true;
      widget.onMapInteractionStart?.call();
      
      // Notify navigation provider
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setMapInteraction(true);
    }
  }
  
  void _handleInteractionEnd() {
    if (_isInteracting) {
      _isInteracting = false;
      widget.onMapInteractionEnd?.call();
      
      // Delay clearing the interaction to prevent premature swipe detection
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          navProvider.setMapInteraction(false);
        }
      });
    }
  }
}

// Navigation Analytics Helper
class NavigationAnalytics {
  static final Map<String, int> _screenVisits = {};
  static final Map<String, Duration> _screenTime = {};
  static final Map<String, DateTime> _sessionStart = {};
  
  static void trackScreenView(String screenName) {
    _screenVisits[screenName] = (_screenVisits[screenName] ?? 0) + 1;
    _sessionStart[screenName] = DateTime.now();
  }
  
  static void trackScreenExit(String screenName) {
    final startTime = _sessionStart[screenName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _screenTime[screenName] = (_screenTime[screenName] ?? Duration.zero) + duration;
      _sessionStart.remove(screenName);
    }
  }
  
  static Map<String, dynamic> getAnalytics() {
    return {
      'screenVisits': Map.from(_screenVisits),
      'screenTime': _screenTime.map((key, value) => MapEntry(key, value.inSeconds)),
    };
  }
  
  static void clearAnalytics() {
    _screenVisits.clear();
    _screenTime.clear();
    _sessionStart.clear();
  }
}

// Responsive Navigation Helper
class ResponsiveNavigation {
  static bool shouldUseBottomNavigation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600; // Use bottom nav for mobile, side nav for tablets
  }
  
  static bool shouldShowLabels(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 400; // Show labels on larger screens
  }
  
  static double getBottomNavHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 400 ? 60.0 : 80.0;
  }
}

// Navigation State Persistence
class NavigationStatePersistence {
  static const String _keySelectedIndex = 'nav_selected_index';
  static const String _keyLastVisited = 'nav_last_visited';
  
  static Future<void> saveNavigationState(int selectedIndex) async {
    // In a real app, you'd use SharedPreferences or similar
    // For now, we'll just store in memory
    _persistedIndex = selectedIndex;
    _persistedTimestamp = DateTime.now();
  }
  
  static int? getPersistedIndex() {
    // Check if the persisted state is recent (within 1 hour)
    if (_persistedTimestamp != null && 
        DateTime.now().difference(_persistedTimestamp!).inHours < 1) {
      return _persistedIndex;
    }
    return null;
  }
  
  static int? _persistedIndex;
  static DateTime? _persistedTimestamp;
}

// Navigation Shortcuts
class NavigationShortcuts extends StatelessWidget {
  final Widget child;
  
  const NavigationShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.digit1): const NavigateToHomeIntent(),
        LogicalKeySet(LogicalKeyboardKey.digit2): const NavigateToSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.digit3): const NavigateToFavouritesIntent(),
        LogicalKeySet(LogicalKeyboardKey.digit4): const NavigateToProfileIntent(),
      },
      child: Actions(
        actions: {
          NavigateToHomeIntent: CallbackAction<NavigateToHomeIntent>(
            onInvoke: (intent) {
              Provider.of<NavigationProvider>(context, listen: false).navigateToHome();
              return null;
            },
          ),
          NavigateToSearchIntent: CallbackAction<NavigateToSearchIntent>(
            onInvoke: (intent) {
              Provider.of<NavigationProvider>(context, listen: false).navigateToSearch();
              return null;
            },
          ),
          NavigateToFavouritesIntent: CallbackAction<NavigateToFavouritesIntent>(
            onInvoke: (intent) {
              Provider.of<NavigationProvider>(context, listen: false).navigateToFavourites();
              return null;
            },
          ),
          NavigateToProfileIntent: CallbackAction<NavigateToProfileIntent>(
            onInvoke: (intent) {
              Provider.of<NavigationProvider>(context, listen: false).navigateToProfile();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

// Intent classes for shortcuts
class NavigateToHomeIntent extends Intent {
  const NavigateToHomeIntent();
}

class NavigateToSearchIntent extends Intent {
  const NavigateToSearchIntent();
}

class NavigateToFavouritesIntent extends Intent {
  const NavigateToFavouritesIntent();
}

class NavigateToProfileIntent extends Intent {
  const NavigateToProfileIntent();
}