// lib/widgets/reviews/review_filter_chips.dart

import 'package:flutter/material.dart';
import '../../services/reviews_service.dart';

class ReviewFilterChips extends StatelessWidget {
  final ReviewSortType currentSort;
  final Function(ReviewSortType) onSortChanged;

  const ReviewFilterChips({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sort Options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(
                  'Newest First',
                  Icons.access_time,
                  ReviewSortType.newest,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'Highest Rated',
                  Icons.star,
                  ReviewSortType.highestRated,
                  Colors.amber,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'Most Helpful',
                  Icons.thumb_up,
                  ReviewSortType.mostHelpful,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'Oldest First',
                  Icons.history,
                  ReviewSortType.oldest,
                  Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    IconData icon,
    ReviewSortType sortType,
    Color color,
  ) {
    final isSelected = currentSort == sortType;
    
    return GestureDetector(
      onTap: () => onSortChanged(sortType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}