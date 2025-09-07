// lib/widgets/add_review/dish_reviews_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dish_review.dart';

class DishReviewsSection extends StatelessWidget {
  final List<DishReview> dishReviews;
  final VoidCallback onDishAdded;
  final Function(int) onDishRemoved;
  final Function(int, DishReview) onDishUpdated;

  const DishReviewsSection({
    super.key,
    required this.dishReviews,
    required this.onDishAdded,
    required this.onDishRemoved,
    required this.onDishUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.local_dining,
              color: Colors.deepOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Rate Individual Dishes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Description
        Text(
          'Add specific dishes you tried and rate them individually',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Dish Reviews List
        if (dishReviews.isNotEmpty) ...[
          ...dishReviews.asMap().entries.map((entry) {
            final index = entry.key;
            final dish = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDishReviewCard(context, index, dish),
            );
          }).toList(),
        ],
        
        // Add Dish Button
        OutlinedButton.icon(
          onPressed: onDishAdded,
          icon: Icon(
            Icons.add,
            color: Colors.deepOrange,
          ),
          label: Text(
            dishReviews.isEmpty ? 'Add First Dish' : 'Add Another Dish',
            style: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.deepOrange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Tips
        if (dishReviews.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pro tip: Rating individual dishes helps other users discover the best items on the menu!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDishReviewCard(BuildContext context, int index, DishReview dish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish Header with Remove Button
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.deepOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Dish ${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => onDishRemoved(index),
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Remove dish',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Dish Name Input
          TextFormField(
            initialValue: dish.dishName,
            onChanged: (value) {
              _updateDish(index, dish.copyWith(dishName: value));
            },
            decoration: InputDecoration(
              labelText: 'Dish Name *',
              hintText: 'e.g., Chicken Biryani, Margherita Pizza',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.deepOrange),
              ),
              labelStyle: TextStyle(color: Colors.deepOrange),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter dish name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rating Row
          Row(
            children: [
              Text(
                'Rating:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              
              // Star Display
              Row(
                children: List.generate(5, (starIndex) {
                  return GestureDetector(
                    onTap: () => _updateDish(
                      index,
                      dish.copyWith(rating: starIndex + 1.0),
                    ),
                    child: Icon(
                      starIndex < dish.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 22,
                    ),
                  );
                }),
              ),
              
              const SizedBox(width: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dish.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price and Quick Note Row
          Row(
            children: [
              // Price Input
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: dish.price?.toStringAsFixed(0) ?? '',
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    _updateDish(index, dish.copyWith(price: price));
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    hintText: '320',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                    labelStyle: TextStyle(color: Colors.deepOrange),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    prefixText: '₹ ',
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Quick Note Input
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: dish.quickNote ?? '',
                  onChanged: (value) {
                    _updateDish(index, dish.copyWith(quickNote: value.isEmpty ? null : value));
                  },
                  decoration: InputDecoration(
                    labelText: 'Quick Note',
                    hintText: 'Perfect spice level',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                    labelStyle: TextStyle(color: Colors.deepOrange),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  maxLength: 50,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return null; // Hide character counter
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateDish(int index, DishReview updatedDish) {
    onDishUpdated(index, updatedDish);
  }
}