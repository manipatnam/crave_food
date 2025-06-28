// Enhanced Search Screen Wrapper - Gesture Conflict Resolution
// lib/screens/enhanced_search_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/navigation_controller.dart';
import 'enhanced_search_screen.dart';

class EnhancedSearchWrapper extends StatefulWidget {
  const EnhancedSearchWrapper({super.key});

  @override
  State<EnhancedSearchWrapper> createState() => _EnhancedSearchWrapperState();
}

class _EnhancedSearchWrapperState extends State<EnhancedSearchWrapper>
    with AutomaticKeepAliveClientMixin {
  bool _isMapInteracting = false;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return MapGestureHandler(
          onMapInteractionStart: () {
            setState(() => _isMapInteracting = true);
            navProvider.setMapInteraction(true);
          },
          onMapInteractionEnd: () {
            // Add slight delay to prevent immediate swipe detection
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() => _isMapInteracting = false);
                navProvider.setMapInteraction(false);
              }
            });
          },
          child: Stack(
            children: [
              // The actual search screen
              const EnhancedSearchScreen(),
              
              // Gesture debug overlay (only in debug mode)
              if (_shouldShowDebugOverlay())
                _buildDebugOverlay(),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowDebugOverlay() {
    // Only show in debug builds and when debugging gestures
    assert(() {
      return true; // This will only run in debug mode
    }());
    return false; // Set to true when debugging gesture conflicts
  }

  Widget _buildDebugOverlay() {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gesture Debug',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Map: ${_isMapInteracting ? "ACTIVE" : "idle"}',
              style: TextStyle(
                color: _isMapInteracting ? Colors.green : Colors.grey,
                fontSize: 10,
              ),
            ),
            Text(
              'Search: ${_isSearching ? "ACTIVE" : "idle"}',
              style: TextStyle(
                color: _isSearching ? Colors.orange : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Google Map with Gesture Management
class GestureAwareGoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onTap;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final MapType mapType;

  const GestureAwareGoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.onMapCreated,
    this.onTap,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapType = MapType.normal,
  });

  @override
  State<GestureAwareGoogleMap> createState() => _GestureAwareGoogleMapState();
}

class _GestureAwareGoogleMapState extends State<GestureAwareGoogleMap> {
  GoogleMapController? _controller;
  bool _isInteracting = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Handle map scroll events
        if (notification is ScrollStartNotification) {
          _handleInteractionStart();
        } else if (notification is ScrollEndNotification) {
          _handleInteractionEnd();
        }
        return false;
      },
      child: GestureDetector(
        onPanStart: (_) => _handleInteractionStart(),
        onPanEnd: (_) => _handleInteractionEnd(),
        onScaleStart: (_) => _handleInteractionStart(),
        onScaleEnd: (_) => _handleInteractionEnd(),
        child: GoogleMap(
          initialCameraPosition: widget.initialCameraPosition,
          markers: widget.markers,
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapCreated?.call(controller);
          },
          onTap: widget.onTap,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: widget.myLocationButtonEnabled,
          zoomControlsEnabled: widget.zoomControlsEnabled,
          mapToolbarEnabled: false,
          compassEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: false,
          mapType: widget.mapType,
          // Disable rotation and tilt to reduce gesture complexity
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          // Enable pan and zoom
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),
      ),
    );
  }

  void _handleInteractionStart() {
    if (!_isInteracting) {
      _isInteracting = true;
      
      // Notify the navigation provider about map interaction
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setMapInteraction(true);
      
      // Debug print
      debugPrint('🗺️ Map interaction started');
    }
  }

  void _handleInteractionEnd() {
    if (_isInteracting) {
      _isInteracting = false;
      
      // Add delay to prevent immediate navigation gestures
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          navProvider.setMapInteraction(false);
          
          // Debug print
          debugPrint('🗺️ Map interaction ended');
        }
      });
    }
  }
}

// Smart Search Bar with Gesture Awareness
class SmartSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onFocusChanged;
  final bool isLoading;

  const SmartSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.isLoading = false,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() => _isFocused = isFocused);
      
      // Notify navigation provider about search activity
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setSearchActive(isFocused);
      
      widget.onFocusChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    color: _isFocused 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
              icon: Icon(
                Icons.clear_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

// Gesture Conflict Prevention Mixin
mixin GestureConflictPrevention<T extends StatefulWidget> on State<T> {
  bool _isGestureActive = false;
  
  void startGestureInteraction() {
    if (!_isGestureActive) {
      _isGestureActive = true;
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.setMapInteraction(true);
    }
  }
  
  void endGestureInteraction() {
    if (_isGestureActive) {
      _isGestureActive = false;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          navProvider.setMapInteraction(false);
        }
      });
    }
  }
  
  Widget wrapWithGestureDetection(Widget child) {
    return GestureDetector(
      onPanStart: (_) => startGestureInteraction(),
      onPanEnd: (_) => endGestureInteraction(),
      onTapDown: (_) => startGestureInteraction(),
      onTapUp: (_) => endGestureInteraction(),
      onTapCancel: () => endGestureInteraction(),
      child: child,
    );
  }
}

// Performance monitoring for gesture handling
class GesturePerformanceMonitor {
  static final Map<String, List<int>> _gestureTimes = {};
  static final Map<String, int> _gestureConflicts = {};
  
  static void recordGesture(String gestureType, int durationMs) {
    _gestureTimes.putIfAbsent(gestureType, () => []).add(durationMs);
  }
  
  static void recordConflict(String conflictType) {
    _gestureConflicts[conflictType] = (_gestureConflicts[conflictType] ?? 0) + 1;
  }
  
  static Map<String, dynamic> getPerformanceData() {
    final avgTimes = <String, double>{};
    
    _gestureTimes.forEach((key, times) {
      if (times.isNotEmpty) {
        avgTimes[key] = times.reduce((a, b) => a + b) / times.length;
      }
    });
    
    return {
      'averageGestureTimes': avgTimes,
      'gestureConflicts': Map.from(_gestureConflicts),
      'totalGestures': _gestureTimes.values.fold(0, (sum, list) => sum + list.length),
    };
  }
  
  static void clearData() {
    _gestureTimes.clear();
    _gestureConflicts.clear();
  }
}