// FILE: lib/widgets/search/map_filters.dart

import 'package:flutter/material.dart';

class MapFilters extends StatelessWidget {
  final bool showVegOnly;
  final bool showNonVegOnly;
  final List<String> selectedTags;
  final Function({
    bool? showVegOnly,
    bool? showNonVegOnly,
    List<String>? selectedTags,
  }) onFilterChanged;

  static const List<String> popularTags = [
    'buffet',
    'romantic',
    'family dining',
    'quick bites',
    'fine dining',
    'budget friendly',
    'desserts',
    'outdoor seating',
  ];

  const MapFilters({
    super.key,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.selectedTags,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Dietary Filters
          _buildDietaryFilter(
            'Veg',
            '🥬',
            showVegOnly,
            Colors.green,
            () => onFilterChanged(showVegOnly: !showVegOnly),
          ),
          const SizedBox(width: 8),
          _buildDietaryFilter(
            'Non-Veg',
            '🍖',
            showNonVegOnly,
            Colors.red,
            () => onFilterChanged(showNonVegOnly: !showNonVegOnly),
          ),
          const SizedBox(width: 16),
          
          // Tag Filters
          ...popularTags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildTagFilter(tag, context),
              )),
        ],
      ),
    );
  }

  Widget _buildDietaryFilter(
    String label,
    String emoji,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilter(String tag, BuildContext context) {
    final isSelected = selectedTags.contains(tag);
    
    return GestureDetector(
      onTap: () {
        final newTags = List<String>.from(selectedTags);
        if (isSelected) {
          newTags.remove(tag);
        } else {
          newTags.add(tag);
        }
        onFilterChanged(selectedTags: newTags);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.2) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label,
              size: 14,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}