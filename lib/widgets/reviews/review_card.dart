// lib/widgets/reviews/review_card.dart

import 'package:flutter/material.dart';
import '../../models/restaurant_review.dart';
import '../../models/review_enums.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final RestaurantReview review;
  final VoidCallback? onHelpfulTap;
  final VoidCallback? onRestaurantTap;
  final VoidCallback? onUserTap;
  final bool showFullReview;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpfulTap,
    this.onRestaurantTap,
    this.onUserTap,
    this.showFullReview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Header
            _buildRestaurantHeader(),
            
            const SizedBox(height: 12),
            
            // User Info & Date
            _buildUserInfo(),
            
            const SizedBox(height: 16),
            
            // Multi-dimensional Ratings
            _buildRatingsDisplay(),
            
            const SizedBox(height: 16),
            
            // Written Review
            _buildWrittenReview(),
            
            // Dish Reviews (if any)
            if (review.dishReviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDishReviews(),
            ],
            
            const SizedBox(height: 16),
            
            // Visit Context
            _buildVisitContext(),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return GestureDetector(
      onTap: onRestaurantTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.restaurantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.restaurantAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.orange[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          child: Text(
            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onUserTap,
                child: Text(
                  review.userDisplayName ?? review.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                _formatDate(review.reviewDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // Privacy indicator
        if (review.privacy != ReviewPrivacy.public)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPrivacyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              review.privacy.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getPrivacyColor(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingsDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Overall Rating (prominent)
          Row(
            children: [
              Text(
                'Overall',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < review.ratings.overallRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    review.ratings.overallRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Individual Ratings
          Row(
            children: [
              Expanded(child: _buildRatingItem('Food', review.ratings.foodRating, Colors.orange)),
              Expanded(child: _buildRatingItem('Service', review.ratings.serviceRating, Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildRatingItem('Ambience', review.ratings.ambienceRating, Colors.purple)),
              Expanded(child: _buildRatingItem('Value', review.ratings.valueRating, Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String label, double rating, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWrittenReview() {
    final maxLines = showFullReview ? null : 3;
    final shouldShowReadMore = !showFullReview && review.writtenReview.length > 150;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.writtenReview,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
          maxLines: maxLines,
          overflow: showFullReview ? null : TextOverflow.ellipsis,
        ),
        if (shouldShowReadMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Handle read more
            },
            child: Text(
              'Read more',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDishReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              'Dishes Reviewed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: review.dishReviews.take(3).map((dish) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepOrange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dish.dishName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepOrange[800],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.amber,
                  ),
                  Text(
                    dish.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (review.dishReviews.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${review.dishReviews.length - 3} more dishes',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVisitContext() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${review.visitType.emoji} ${review.visitType.displayName} • ${review.mealTime.emoji} ${review.mealTime.displayName} • ${review.occasion.emoji} ${review.occasion.displayName}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Helpful Button
        TextButton.icon(
          onPressed: onHelpfulTap,
          icon: Icon(
            Icons.thumb_up_outlined,
            size: 16,
            color: Colors.grey[600],
          ),
          label: Text(
            'Helpful${review.helpfulCount > 0 ? ' (${review.helpfulCount})' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Share Button
        TextButton.icon(
          onPressed: () {
            // Handle share
          },
          icon: Icon(
            Icons.share_outlined,
            size: 16,
            color: Colors.grey[600],
          ),
          label: Text(
            'Share',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        
        const Spacer(),
        
        // Visit Date
        Text(
          'Visited ${_formatDate(review.visitDate)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Color _getPrivacyColor() {
    switch (review.privacy) {
      case ReviewPrivacy.public:
        return Colors.green;
      case ReviewPrivacy.friends:
        return Colors.blue;
      case ReviewPrivacy.private:
        return Colors.grey;
    }
  }
}