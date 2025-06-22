// Enhanced Map Filters Widget
// lib/widgets/search/enhanced_map_filters.dart

import 'package:flutter/material.dart';

class EnhancedMapFilters extends StatelessWidget {
  final bool showVegOnly;
  final bool showNonVegOnly;
  final bool showOpenOnly;
  final List<String> selectedTags;
  final double minRating;
  final double maxDistance;
  final Function({
    bool? showVegOnly,
    bool? showNonVegOnly,
    bool? showOpenOnly,
    List<String>? selectedTags,
    double? minRating,
    double? maxDistance,
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
    'live music',
    'rooftop',
    'bar',
    'cafe',
  ];

  const EnhancedMapFilters({
    super.key,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.showOpenOnly,
    required this.selectedTags,
    required this.minRating,
    required this.maxDistance,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Dietary Filters
            _buildDietaryFilter(
              'Veg Only',
              '🥬',
              showVegOnly,
              Colors.green,
              () => onFilterChanged(
                showVegOnly: !showVegOnly,
                showNonVegOnly: showVegOnly ? showNonVegOnly : false,
              ),
            ),
            const SizedBox(width: 12),
            
            _buildDietaryFilter(
              'Non-Veg',
              '🍖',
              showNonVegOnly,
              Colors.red,
              () => onFilterChanged(
                showNonVegOnly: !showNonVegOnly,
                showVegOnly: showNonVegOnly ? showVegOnly : false,
              ),
            ),
            const SizedBox(width: 12),
            
            // Open Now Filter
            _buildQuickFilter(
              'Open Now',
              '🕐',
              showOpenOnly,
              Colors.blue,
              () => onFilterChanged(showOpenOnly: !showOpenOnly),
              context,
            ),
            const SizedBox(width: 12),
            
            // Rating Filter Indicator
            if (minRating > 0.0) ...[
              _buildIndicatorChip(
                '${minRating.toStringAsFixed(1)}★+',
                Colors.orange,
                () => onFilterChanged(minRating: 0.0),
                context,
              ),
              const SizedBox(width: 12),
            ],
            
            // Distance Filter Indicator
            if (maxDistance < 50.0) ...[
              _buildIndicatorChip(
                '${maxDistance.toInt()}km',
                Colors.purple,
                () => onFilterChanged(maxDistance: 50.0),
                context,
              ),
              const SizedBox(width: 12),
            ],
            
            // Divider
            if (_hasBasicFilters()) ...[
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
            
            // Tag Filters
            ...popularTags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildTagFilter(tag, context),
                )),
          ],
        ),
      ),
    );
  }

  bool _hasBasicFilters() {
    return showVegOnly || showNonVegOnly || showOpenOnly || minRating > 0.0 || maxDistance < 50.0;
  }

  Widget _buildDietaryFilter(
    String label,
    String emoji,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return _buildFilterButton(
      label: label,
      emoji: emoji,
      isSelected: isSelected,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildQuickFilter(
    String label,
    String emoji,
    bool isSelected,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return _buildFilterButton(
      label: label,
      emoji: emoji,
      isSelected: isSelected,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String emoji,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorChip(
    String label,
    Color color,
    VoidCallback onRemove,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: color,
            ),
          ),
        ],
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.15) 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.25),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_rounded,
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
                    : Colors.grey[700],
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

// Compact version for mobile optimization
class CompactMapFilters extends StatelessWidget {
  final bool showVegOnly;
  final bool showNonVegOnly;
  final bool showOpenOnly;
  final int activeFiltersCount;
  final VoidCallback onToggleFilters;
  final Function({
    bool? showVegOnly,
    bool? showNonVegOnly,
    bool? showOpenOnly,
  }) onQuickFilterChanged;

  const CompactMapFilters({
    super.key,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.showOpenOnly,
    required this.activeFiltersCount,
    required this.onToggleFilters,
    required this.onQuickFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16),
          
          // Quick dietary filters
          _buildCompactFilter(
            '🥬',
            showVegOnly,
            Colors.green,
            () => onQuickFilterChanged(
              showVegOnly: !showVegOnly,
              showNonVegOnly: showVegOnly ? showNonVegOnly : false,
            ),
          ),
          const SizedBox(width: 8),
          
          _buildCompactFilter(
            '🍖',
            showNonVegOnly,
            Colors.red,
            () => onQuickFilterChanged(
              showNonVegOnly: !showNonVegOnly,
              showVegOnly: showNonVegOnly ? showVegOnly : false,
            ),
          ),
          const SizedBox(width: 8),
          
          _buildCompactFilter(
            '🕐',
            showOpenOnly,
            Colors.blue,
            () => onQuickFilterChanged(showOpenOnly: !showOpenOnly),
          ),
          
          // Divider
          Container(
            height: 30,
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          
          // More filters button
          GestureDetector(
            onTap: onToggleFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: activeFiltersCount > 0 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: activeFiltersCount > 0 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
                  ),
                  if (activeFiltersCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activeFiltersCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildCompactFilter(
    String emoji,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}