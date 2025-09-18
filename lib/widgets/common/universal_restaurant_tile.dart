// Universal Restaurant Tile Widget - Consistent design across all screens
// lib/widgets/common/universal_restaurant_tile.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';

// Universal data model for restaurant display
class RestaurantTileData {
  final String id;
  final String name;
  final String? address;
  final String? cuisineType;
  final double? rating;
  final String? priceLevel;
  final bool? isOpen;
  final LatLng coordinates;
  final String? photoUrl;
  final List<String> tags;
  final bool isVegetarian;
  final bool isNonVegetarian;
  
  const RestaurantTileData({
    required this.id,
    required this.name,
    required this.coordinates,
    this.address,
    this.cuisineType,
    this.rating,
    this.priceLevel,
    this.isOpen,
    this.photoUrl,
    this.tags = const [],
    this.isVegetarian = false,
    this.isNonVegetarian = false,
  });
}

// Enum for different tile contexts
enum TileContext { search, favorites, reviews, home }

// Main universal tile widget
class UniversalRestaurantTile extends StatelessWidget {
  final RestaurantTileData restaurant;
  final TileContext context;
  final LatLng? currentLocation;
  final VoidCallback? onTap;
  final Widget? trailingAction;
  final bool showDistance;
  final bool showTags;
  final bool showOpenStatus;
  final bool isLast;

  const UniversalRestaurantTile({
    super.key,
    required this.restaurant,
    required this.context,
    this.currentLocation,
    this.onTap,
    this.trailingAction,
    this.showDistance = true,
    this.showTags = true,
    this.showOpenStatus = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: _getBoxShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading: Restaurant icon/image
                _buildLeadingWidget(theme),
                const SizedBox(width: 16),
                
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name
                      Text(
                        restaurant.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Address (if available)
                      if (restaurant.address?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          restaurant.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      // Cuisine type and meta info row
                      _buildMetaInfoRow(theme, distance),
                      
                      // Tags (if enabled and available)
                      if (showTags && restaurant.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildTagsRow(theme),
                      ],
                    ],
                  ),
                ),
                
                // Trailing action (if provided)
                if (trailingAction != null) ...[
                  const SizedBox(width: 12),
                  trailingAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(theme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: restaurant.photoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                restaurant.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(theme),
              ),
            )
          : _buildFallbackIcon(theme),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Icon(
      _getCuisineIcon(),
      color: theme.colorScheme.primary,
      size: 28,
    );
  }

  Widget _buildMetaInfoRow(ThemeData theme, double? distance) {
    final List<Widget> items = [];
    
    // Cuisine type
    if (restaurant.cuisineType?.isNotEmpty == true) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            restaurant.cuisineType!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      );
    }
    
    // Rating
    if (restaurant.rating != null && restaurant.rating! > 0) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: Colors.amber[700],
            ),
            const SizedBox(width: 2),
            Text(
              restaurant.rating!.toStringAsFixed(1),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    // Distance
    if (showDistance && distance != null) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 2),
            Text(
              LocationService.formatDistance(distance),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    // Open status
    if (showOpenStatus && restaurant.isOpen != null) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      items.add(
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: restaurant.isOpen! ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      );
      items.add(const SizedBox(width: 4));
      items.add(
        Text(
          restaurant.isOpen! ? 'Open' : 'Closed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: restaurant.isOpen! ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      );
    }
    
    // Dietary indicators
    if (restaurant.isVegetarian || restaurant.isNonVegetarian) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 8));
      
      if (restaurant.isVegetarian) {
        items.add(
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.circle,
              size: 6,
              color: Colors.white,
            ),
          ),
        );
      }
      
      if (restaurant.isNonVegetarian) {
        if (restaurant.isVegetarian) items.add(const SizedBox(width: 4));
        items.add(
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.circle,
              size: 6,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: restaurant.tags.take(3).map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          tag,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  // Helper methods
  double? _calculateDistance() {
    if (currentLocation == null) return null;
    return LocationService.calculateDistance(currentLocation!, restaurant.coordinates);
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (context) {
      case TileContext.search:
        return theme.colorScheme.surface;
      case TileContext.favorites:
        return theme.colorScheme.surface;
      case TileContext.reviews:
        return theme.colorScheme.surface;
      case TileContext.home:
        return theme.colorScheme.surface;
    }
  }

  Color _getIconBackgroundColor(ThemeData theme) {
    return theme.colorScheme.primary.withOpacity(0.1);
  }

  List<BoxShadow> _getBoxShadow() {
    switch (context) {
      case TileContext.favorites:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ];
      default:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
    }
  }

  IconData _getCuisineIcon() {
    final cuisine = restaurant.cuisineType?.toLowerCase() ?? '';
    
    if (cuisine.contains('italian') || cuisine.contains('pizza')) {
      return Icons.local_pizza_rounded;
    } else if (cuisine.contains('chinese') || cuisine.contains('asian')) {
      return Icons.ramen_dining_rounded;
    } else if (cuisine.contains('cafe') || cuisine.contains('coffee')) {
      return Icons.local_cafe_rounded;
    } else if (cuisine.contains('bar') || cuisine.contains('pub')) {
      return Icons.local_bar_rounded;
    } else if (cuisine.contains('fast') || cuisine.contains('burger')) {
      return Icons.fastfood_rounded;
    } else if (cuisine.contains('dessert') || cuisine.contains('ice')) {
      return Icons.cake_rounded;
    } else if (cuisine.contains('indian') || cuisine.contains('biryani')) {
      return Icons.restaurant_menu_rounded;
    } else {
      return Icons.restaurant_rounded;
    }
  }
}

// Extensions are defined in the model files to avoid conflicts