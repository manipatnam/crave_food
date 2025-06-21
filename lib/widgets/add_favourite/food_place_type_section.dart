// Food Place Type Selection Widget
// lib/widgets/add_favourite/food_place_type_section.dart

import 'package:flutter/material.dart';
import '../../screens/add_favourite_screen.dart'; // For FoodPlaceType enum

class FoodPlaceTypeSection extends StatelessWidget {
  final FoodPlaceType? selectedType;
  final Function(FoodPlaceType) onTypeSelected;

  const FoodPlaceTypeSection({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Food Place Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'What type of food place is this?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        _buildFoodTypeList(context),
      ],
    );
  }

  Widget _buildFoodTypeList(BuildContext context) {
    return Column(
      children: FoodPlaceType.values.map((type) {
        final isSelected = selectedType == type;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildFoodTypeCard(context, type, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildFoodTypeCard(BuildContext context, FoodPlaceType type, bool isSelected) {
    const primaryColor = Color(0xFFFF6B35); // Food category color
    
    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? primaryColor
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? primaryColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.02),
              blurRadius: isSelected ? 8 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji and Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? primaryColor.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    type.icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Label
            Expanded(
              child: Text(
                type.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}