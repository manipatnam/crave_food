import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';

class FoodItemsSection extends StatelessWidget {
  final Favourite favourite;

  const FoodItemsSection({
    super.key,
    required this.favourite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 16,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Food Items',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: favourite.foodNames.take(4).map((food) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                food,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            );
          }).toList(),
        ),
        if (favourite.foodNames.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${favourite.foodNames.length - 4} more items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}