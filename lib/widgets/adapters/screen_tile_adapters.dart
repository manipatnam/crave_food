// Screen-Specific Tile Adapters using Universal Restaurant Tile
// These adapters provide consistent UI across all screens

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../common/universal_restaurant_tile.dart';
import '../../models/place_model.dart';
import '../../models/favourite_model.dart';

// Note: Extensions are defined in the model files to avoid conflicts

// 1. SEARCH SCREEN ADAPTER
class SearchResultTileAdapter extends StatelessWidget {
  final PlaceModel place;
  final bool isLast;
  final LatLng? currentLocation;
  final VoidCallback onTap;

  const SearchResultTileAdapter({
    super.key,
    required this.place,
    required this.isLast,
    required this.currentLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalRestaurantTile(
      restaurant: place.toTileData(),
      context: TileContext.search,
      currentLocation: currentLocation,
      onTap: onTap,
      showDistance: true,
      showTags: false, // Search results don't show tags
      showOpenStatus: true,
      isLast: isLast,
      trailingAction: IconButton(
        onPressed: onTap,
        icon: Icon(
          Icons.add_circle_rounded,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        tooltip: 'Add to Favorites',
      ),
    );
  }
}

// 2. FAVORITES SCREEN ADAPTER
class FavoriteTileAdapter extends StatelessWidget {
  final Favourite favourite;
  final bool isLast;
  final LatLng? currentLocation;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onLaunchUrl;

  const FavoriteTileAdapter({
    super.key,
    required this.favourite,
    required this.isLast,
    this.currentLocation,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalRestaurantTile(
      restaurant: favourite.toTileData(),
      context: TileContext.favorites,
      currentLocation: currentLocation,
      onTap: onTap,
      showDistance: true,
      showTags: true,
      showOpenStatus: false, // Favorites don't typically show open status
      isLast: isLast,
      trailingAction: _buildFavoriteActions(context),
    );
  }

  Widget _buildFavoriteActions(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call(); // ✅ This now calls the VoidCallback correctly
            break;
          case 'directions':
            // Handle directions
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'directions',
          child: Row(
            children: [
              Icon(Icons.directions_rounded, size: 18),
              SizedBox(width: 8),
              Text('Directions'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// 3. ENHANCED FAVORITE CARD REPLACEMENT
// This replaces the complex EnhancedFavouriteCard with consistent styling
class EnhancedFavoriteTileAdapter extends StatefulWidget {
  final Favourite favourite;
  final LatLng? currentLocation;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onLaunchUrl;
  final Function(Favourite)? onStatusChanged;

  const EnhancedFavoriteTileAdapter({
    super.key,
    required this.favourite,
    this.currentLocation,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLaunchUrl,
    this.onStatusChanged,
  });

  @override
  State<EnhancedFavoriteTileAdapter> createState() => 
      _EnhancedFavoriteTileAdapterState();
}

class _EnhancedFavoriteTileAdapterState extends State<EnhancedFavoriteTileAdapter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main tile
        UniversalRestaurantTile(
          restaurant: widget.favourite.toTileData(),
          context: TileContext.favorites,
          currentLocation: widget.currentLocation,
          onTap: _toggleExpansion,
          showDistance: true,
          showTags: true,
          showOpenStatus: false,
          trailingAction: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visit status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.favourite.visitStatus.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.favourite.visitStatus.color.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.favourite.visitStatus.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.favourite.visitStatus.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.favourite.visitStatus.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Expand/collapse indicator
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Expanded content
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? null : 0,
          child: _isExpanded ? _buildExpandedContent(context) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes section
          if (widget.favourite.userNotes?.isNotEmpty == true) ...[
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.favourite.userNotes!,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle directions
                  },
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Directions'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 4. HOME SCREEN PREVIEW ADAPTER
class HomeFavoritePreviewAdapter extends StatelessWidget {
  final Favourite favourite;
  final LatLng? currentLocation;
  final VoidCallback? onTap;

  const HomeFavoritePreviewAdapter({
    super.key,
    required this.favourite,
    this.currentLocation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalRestaurantTile(
      restaurant: favourite.toTileData(),
      context: TileContext.home,
      currentLocation: currentLocation,
      onTap: onTap,
      showDistance: true,
      showTags: false, // Home previews keep it simple
      showOpenStatus: false,
      trailingAction: Icon(
        Icons.favorite_rounded,
        color: Theme.of(context).primaryColor,
        size: 20,
      ),
    );
  }
}

// 5. REVIEWS SCREEN ADAPTER (for future use)
class ReviewTileAdapter extends StatelessWidget {
  final RestaurantTileData restaurant;
  final LatLng? currentLocation;
  final VoidCallback? onTap;
  final String? reviewSnippet;
  final double? userRating;

  const ReviewTileAdapter({
    super.key,
    required this.restaurant,
    this.currentLocation,
    this.onTap,
    this.reviewSnippet,
    this.userRating,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalRestaurantTile(
      restaurant: restaurant,
      context: TileContext.reviews,
      currentLocation: currentLocation,
      onTap: onTap,
      showDistance: true,
      showTags: true,
      showOpenStatus: true,
      trailingAction: userRating != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}