// Enhanced Favourite Card Components with Images
// lib/widgets/favourites/favourite_card_components.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/favourite_model.dart';

class FavouriteCardHeader extends StatelessWidget {
  final Favourite favourite;
  final Position? currentLocation;
  final bool showDistance;

  const FavouriteCardHeader({
    super.key,
    required this.favourite,
    this.currentLocation,
    this.showDistance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image section
        _buildImageSection(context),
        // Content section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favourite.restaurantName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAddressFromCoordinates(favourite.coordinates),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showDistance && currentLocation != null)
                    _buildDistanceChip(context),
                  _buildRatingChip(context),
                ],
              ),
              const SizedBox(height: 16),
              if (favourite.tags.isNotEmpty) _buildTagsRow(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            _buildImage(context),
            // Gradient overlay
            _buildGradientOverlay(),
            // Status indicators
            _buildStatusIndicators(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (favourite.restaurantImageUrl != null && favourite.restaurantImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: favourite.restaurantImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(context),
        errorWidget: (context, url, error) => _buildImagePlaceholder(context),
      );
    } else {
      return _buildImagePlaceholder(context);
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPlaceCategoryIcon(),
              size: 60,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
            const SizedBox(height: 8),
            Text(
              favourite.cuisineType ?? 'Restaurant',
              style: TextStyle(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Open/Closed status
          if (favourite.isOpen != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: favourite.isOpen! ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    favourite.isOpen! ? Icons.check_circle : Icons.access_time,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    favourite.isOpen! ? 'Open' : 'Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Price level
          if (favourite.priceLevel?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                favourite.priceLevel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistanceChip(BuildContext context) {
    final distance = Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      favourite.coordinates.latitude,
      favourite.coordinates.longitude,
    );
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(distance / 1000).toStringAsFixed(1)}km',
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRatingChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 2),
          Text(
            favourite.rating?.toStringAsFixed(1) ?? '0.0',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: favourite.tags.take(3).map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  IconData _getPlaceCategoryIcon() {
    // Use cuisine type or place category to determine icon
    final category = favourite.cuisineType?.toLowerCase() ?? '';
    
    if (category.contains('italian') || category.contains('pizza')) {
      return Icons.local_pizza_rounded;
    } else if (category.contains('chinese') || category.contains('asian')) {
      return Icons.ramen_dining_rounded;
    } else if (category.contains('cafe') || category.contains('coffee')) {
      return Icons.local_cafe_rounded;
    } else if (category.contains('bar') || category.contains('pub')) {
      return Icons.local_bar_rounded;
    } else if (category.contains('fast') || category.contains('burger')) {
      return Icons.fastfood_rounded;
    } else if (category.contains('dessert') || category.contains('ice')) {
      return Icons.cake_rounded;
    } else {
      return Icons.restaurant_rounded;
    }
  }

  String _getAddressFromCoordinates(GeoPoint coordinates) {
    // For now, return coordinates as address
    // In a real app, you'd use reverse geocoding
    return '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
  }
}

class FavouriteCardExpandedContent extends StatelessWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FavouriteCardExpandedContent({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          // Restaurant details
          _buildDetailsGrid(context),
          const SizedBox(height: 16),
          // Notes section
          if (favourite.userNotes?.isNotEmpty ?? false) _buildNotesSection(context),
          // Cuisine type section
          if (favourite.cuisineType?.isNotEmpty ?? false) _buildCategorySection(context),
          // Food items section
          if (favourite.foodNames.isNotEmpty) _buildFoodItemsSection(context),
          // Dietary options
          if (favourite.isVegetarianAvailable || favourite.isNonVegetarianAvailable)
            _buildDietaryOptions(context),
          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context) {
    final details = <Widget>[];

    // Phone number
    if (favourite.phoneNumber?.isNotEmpty == true) {
      details.add(_buildDetailItem(
        context,
        Icons.phone_rounded,
        'Phone',
        favourite.phoneNumber!,
        Colors.green,
      ));
    }

    // Website
    if (favourite.website?.isNotEmpty == true) {
      details.add(_buildDetailItem(
        context,
        Icons.language_rounded,
        'Website',
        'Visit Website',
        Colors.blue,
      ));
    }

    // Timing
    if (favourite.userOpeningTime != null || favourite.userClosingTime != null) {
      final timing = _formatTiming();
      details.add(_buildDetailItem(
        context,
        Icons.access_time_rounded,
        'Hours',
        timing,
        Colors.orange,
      ));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: details,
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Text(
            favourite.userNotes!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            favourite.cuisineType!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFoodItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Items',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: favourite.foodNames.map((foodName) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              foodName,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDietaryOptions(BuildContext context) {
    final options = <Widget>[];
    
    if (favourite.isVegetarianAvailable) {
      options.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Vegetarian',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ));
    }
    
    if (favourite.isNonVegetarianAvailable) {
      options.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_rounded, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'Non-Vegetarian',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ));
    }

    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary Options',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onLaunchUrl(_generateGoogleMapsUrl()),
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          color: Theme.of(context).colorScheme.error,
          tooltip: 'Delete',
        ),
      ],
    );
  }

  String _generateGoogleMapsUrl() {
    final lat = favourite.coordinates.latitude;
    final lng = favourite.coordinates.longitude;
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  String _formatTiming() {
    if (favourite.userOpeningTime == null && favourite.userClosingTime == null) {
      return 'Hours not specified';
    }
    
    final opening = favourite.userOpeningTime != null 
        ? _formatTimeOfDay(favourite.userOpeningTime!) 
        : 'Unknown';
    final closing = favourite.userClosingTime != null 
        ? _formatTimeOfDay(favourite.userClosingTime!) 
        : 'Unknown';
    
    return '$opening - $closing';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}