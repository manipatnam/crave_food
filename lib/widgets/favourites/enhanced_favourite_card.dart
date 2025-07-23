// Enhanced Favourite Card with Expandable Details
// lib/widgets/favourites/enhanced_favourite_card.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/favourite_model.dart';
import '../../animations/favourites/favourite_card_animations.dart';
import 'favourite_card_components.dart';
import '../../models/visit_status.dart';
import '../visit_status/visit_status_selector.dart';

class EnhancedFavouriteCard extends StatefulWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Favourite)? onStatusChanged; //NEW
  final Position? currentLocation;
  final bool showDistance;

  const EnhancedFavouriteCard({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
    this.onStatusChanged, //NEW
    this.currentLocation,
    this.showDistance = false,
  });

  @override
  State<EnhancedFavouriteCard> createState() => _EnhancedFavouriteCardState();
}

class _EnhancedFavouriteCardState extends State<EnhancedFavouriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late FavouriteCardAnimations animations;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    animations = FavouriteCardAnimations(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggleExpansion() {
    setState(() => isExpanded = !isExpanded);
    if (isExpanded) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) => controller.reverse(),
      onTapCancel: () => controller.reverse(),
      onTap: toggleExpansion,
      child: ScaleTransition(
        scale: animations.scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit status row at the top
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.favourite.restaurantName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Visit Status Selector
                      if (widget.onStatusChanged != null)
                        VisitStatusSelector(
                          selectedStatus: widget.favourite.visitStatus,
                          onStatusChanged: (newStatus) {
                            final updatedFavourite = widget.favourite.copyWith(
                              visitStatus: newStatus,
                            );
                            widget.onStatusChanged!(updatedFavourite);
                          },
                          isCompact: true,
                        )
                      else
                        VisitStatusChip(
                          status: widget.favourite.visitStatus,
                          showLabel: true,
                          fontSize: 11,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Your existing header content
                  FavouriteCardHeader(
                    favourite: widget.favourite,
                    currentLocation: widget.currentLocation,
                    showDistance: widget.showDistance,
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? FavouriteCardExpandedContent(
                        favourite: widget.favourite,
                        onLaunchUrl: widget.onLaunchUrl,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisitStatusChip extends StatelessWidget {
  final VisitStatus status;
  final bool showLabel;
  final double? fontSize;

  const VisitStatusChip({
    super.key,
    required this.status,
    this.showLabel = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.emoji,
            style: TextStyle(fontSize: fontSize ?? 12),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: fontSize ?? 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}