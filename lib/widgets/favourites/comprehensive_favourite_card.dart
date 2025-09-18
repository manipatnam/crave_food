// Comprehensive Favourite Card - Shows ALL favourite details
// lib/widgets/favourites/comprehensive_favourite_card.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../models/favourite_model.dart';
import '../../services/location_service.dart';
import '../visit_status/visit_status_selector.dart';

class ComprehensiveFavouriteCard extends StatefulWidget {
  final Favourite favourite;
  final LatLng? currentLocation;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onLaunchUrl;
  final Function(Favourite)? onStatusChanged;

  const ComprehensiveFavouriteCard({
    super.key,
    required this.favourite,
    this.currentLocation,
    this.onEdit,
    this.onDelete,
    this.onLaunchUrl,
    this.onStatusChanged,
  });

  @override
  State<ComprehensiveFavouriteCard> createState() => _ComprehensiveFavouriteCardState();
}

class _ComprehensiveFavouriteCardState extends State<ComprehensiveFavouriteCard>
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main card content (always visible)
          _buildMainCard(context),
          
          // Expanded details (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: _isExpanded ? _buildExpandedContent(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final theme = Theme.of(context);
    final distance = _calculateDistance();
    
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Image + Main Info + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Image or Icon
                _buildLeadingImage(theme),
                const SizedBox(width: 16),
                
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      Text(
                        widget.favourite.restaurantName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Category & Type Row
                      _buildCategoryRow(theme),
                      
                      const SizedBox(height: 8),
                      
                      // Rating & Distance Row
                      _buildMetaRow(theme, distance),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Visit Status + Expand Icon
                Column(
                  children: [
                    _buildVisitStatusBadge(theme),
                    const SizedBox(height: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Food Items Preview (if any)
            if (widget.favourite.foodNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildFoodItemsPreview(theme),
            ],
            
            // Tags Row (if any)
            if (widget.favourite.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTagsRow(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingImage(ThemeData theme) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: widget.favourite.restaurantImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                widget.favourite.restaurantImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(theme),
              ),
            )
          : _buildFallbackIcon(theme),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: widget.favourite.placeCategoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        widget.favourite.placeCategoryIcon,
        color: widget.favourite.placeCategoryColor,
        size: 32,
      ),
    );
  }

  Widget _buildCategoryRow(ThemeData theme) {
    return Row(
      children: [
        // Place Category
        if (widget.favourite.placeCategory != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.favourite.placeCategoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.favourite.placeCategory!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.favourite.placeCategoryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
        
        // Food Place Type (if it's a food place)
        if (widget.favourite.isFoodPlace && widget.favourite.foodPlaceType != null) ...[
          if (widget.favourite.placeCategory != null) const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.favourite.foodPlaceTypeEmoji,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 3),
                Text(
                  widget.favourite.foodPlaceType!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Cuisine Type
        if (widget.favourite.cuisineType?.isNotEmpty == true) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.favourite.cuisineType!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaRow(ThemeData theme, double? distance) {
    final List<Widget> items = [];
    
    // Rating
    if (widget.favourite.rating != null && widget.favourite.rating! > 0) {
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
              widget.favourite.rating!.toStringAsFixed(1),
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
    if (distance != null) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
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
    
    // Price Level
    if (widget.favourite.priceLevel?.isNotEmpty == true) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      items.add(
        Text(
          widget.favourite.priceLevel!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }
    
    // Dietary Options
    if (widget.favourite.isVegetarianAvailable || widget.favourite.isNonVegetarianAvailable) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      
      if (widget.favourite.isVegetarianAvailable) {
        items.add(
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
      
      if (widget.favourite.isNonVegetarianAvailable) {
        if (widget.favourite.isVegetarianAvailable) items.add(const SizedBox(width: 4));
        items.add(
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
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

  Widget _buildVisitStatusBadge(ThemeData theme) {
    return GestureDetector(
      onTap: () => _showVisitStatusSelector(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }

  Widget _buildFoodItemsPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.favourite.foodNamesPreview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.favourite.tags.take(4).map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Text(
          tag,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          
          // User Notes
          if (widget.favourite.userNotes?.isNotEmpty == true) ...[
            _buildDetailSection(
              theme,
              'Notes',
              Icons.note_rounded,
              widget.favourite.userNotes!,
            ),
            const SizedBox(height: 16),
          ],
          
          // Contact Information
          if (widget.favourite.phoneNumber?.isNotEmpty == true || 
              widget.favourite.website?.isNotEmpty == true) ...[
            _buildContactSection(theme),
            const SizedBox(height: 16),
          ],
          
          // Timing Information
          if (widget.favourite.userOpeningTime != null || 
              widget.favourite.userClosingTime != null ||
              widget.favourite.timingNotes?.isNotEmpty == true) ...[
            _buildTimingSection(theme),
            const SizedBox(height: 16),
          ],
          
          // Social URLs
          if (widget.favourite.socialUrls.isNotEmpty) ...[
            _buildSocialSection(theme),
            const SizedBox(height: 16),
          ],
          
          // All Food Items (if more than shown in preview)
          if (widget.favourite.foodNames.length > 3) ...[
            _buildAllFoodItemsSection(theme),
            const SizedBox(height: 16),
          ],
          
          // All Tags (if more than shown in main card)
          if (widget.favourite.tags.length > 4) ...[
            _buildAllTagsSection(theme),
            const SizedBox(height: 16),
          ],
          
          // Date Added
          _buildDetailSection(
            theme,
            'Added',
            Icons.calendar_today_rounded,
            widget.favourite.formattedDate,
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildDetailSection(ThemeData theme, String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Contact',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.favourite.phoneNumber?.isNotEmpty == true) ...[
          _buildContactItem(theme, Icons.phone_rounded, widget.favourite.phoneNumber!, () {
            _launchPhone(widget.favourite.phoneNumber!);
          }),
        ],
        if (widget.favourite.website?.isNotEmpty == true) ...[
          _buildContactItem(theme, Icons.language_rounded, widget.favourite.website!, () {
            widget.onLaunchUrl?.call(widget.favourite.website!);
          }),
        ],
      ],
    );
  }

  Widget _buildContactItem(ThemeData theme, IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(
              Icons.launch_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Timing',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.favourite.userOpeningTime != null && widget.favourite.userClosingTime != null)
          Text(
            '${_formatTimeOfDay(widget.favourite.userOpeningTime!)} - ${_formatTimeOfDay(widget.favourite.userClosingTime!)}',
            style: theme.textTheme.bodyMedium,
          ),
        if (widget.favourite.timingNotes?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            widget.favourite.timingNotes!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.share_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Social Links',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.favourite.socialUrls.map((url) => 
            _buildSocialButton(theme, url)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialButton(ThemeData theme, String url) {
    return InkWell(
      onTap: () => widget.onLaunchUrl?.call(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSocialIcon(url),
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _getSocialLabel(url),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllFoodItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'All Food Items',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.favourite.foodNames.map((food) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              food,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
                fontSize: 11,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAllTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'All Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.favourite.tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              tag,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _launchDirections(),
            icon: const Icon(Icons.directions_rounded, size: 16),
            label: const Text('Directions'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_rounded, color: Colors.red),
          tooltip: 'Remove from favorites',
        ),
      ],
    );
  }

  // Helper Methods
  double? _calculateDistance() {
    if (widget.currentLocation == null) return null;
    return LocationService.calculateDistance(
      widget.currentLocation!,
      LatLng(widget.favourite.coordinates.latitude, widget.favourite.coordinates.longitude),
    );
  }

  void _showVisitStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VisitStatusSelector(
        selectedStatus: widget.favourite.visitStatus, // ✅ FIXED: Use correct parameter name
        onStatusChanged: (newStatus) {
          final updatedFavourite = widget.favourite.copyWith(visitStatus: newStatus);
          widget.onStatusChanged?.call(updatedFavourite);
        },
      ),
    );
  }

  void _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    }
  }

  void _launchDirections() async {
    final lat = widget.favourite.coordinates.latitude;
    final lng = widget.favourite.coordinates.longitude;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  IconData _getSocialIcon(String url) {
    if (url.toLowerCase().contains('instagram')) return Icons.camera_alt_rounded;
    if (url.toLowerCase().contains('facebook')) return Icons.facebook_rounded;
    if (url.toLowerCase().contains('twitter')) return Icons.alternate_email_rounded;
    return Icons.link_rounded;
  }

  String _getSocialLabel(String url) {
    if (url.toLowerCase().contains('instagram')) return 'Instagram';
    if (url.toLowerCase().contains('facebook')) return 'Facebook';
    if (url.toLowerCase().contains('twitter')) return 'Twitter';
    return 'Link';
  }
}