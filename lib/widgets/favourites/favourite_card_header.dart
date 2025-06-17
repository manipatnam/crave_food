import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';

class FavouriteCardHeader extends StatelessWidget {
  final Favourite favourite;

  const FavouriteCardHeader({
    super.key,
    required this.favourite,
  });

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant,
        size: 60,
        color: Theme.of(context).primaryColor.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Restaurant image
          if (favourite.restaurantImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                favourite.restaurantImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(context),
              ),
            )
          else
            _buildImagePlaceholder(context),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Content overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favourite.restaurantName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (favourite.rating != null) ...[
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        favourite.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (favourite.rating != null && favourite.cuisineType != null)
                      const Text(' • ', style: TextStyle(color: Colors.white70)),
                    if (favourite.cuisineType != null)
                      Expanded(
                        child: Text(
                          favourite.cuisineType!,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Date badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                favourite.formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}