import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';
import 'food_items_section.dart';
import 'social_links_section.dart';
import 'notes_section.dart';

class FavouriteCardContent extends StatelessWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FavouriteCardContent({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food items
          if (favourite.foodNames.isNotEmpty)
            FoodItemsSection(favourite: favourite),
          
          // Social links
          if (favourite.hasSocialUrls)
            SocialLinksSection(
              favourite: favourite,
              onLaunchUrl: onLaunchUrl,
            ),
          
          // Notes
          if (favourite.userNotes != null && favourite.userNotes!.isNotEmpty)
            NotesSection(favourite: favourite),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (favourite.priceLevel != null) ...[
                    Text(
                      favourite.priceLevel!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (favourite.isOpen != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: favourite.isOpen! ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        favourite.isOpen! ? 'Open' : 'Closed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}