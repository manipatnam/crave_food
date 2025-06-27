// Enhanced Favourite Card with Expandable Details
// lib/widgets/favourites/enhanced_favourite_card.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/favourite_model.dart';
import '../../animations/favourites/favourite_card_animations.dart';
import 'favourite_card_components.dart';

class EnhancedFavouriteCard extends StatefulWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Position? currentLocation;
  final bool showDistance;

  const EnhancedFavouriteCard({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
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
              FavouriteCardHeader(
                favourite: widget.favourite,
                currentLocation: widget.currentLocation,
                showDistance: widget.showDistance,
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