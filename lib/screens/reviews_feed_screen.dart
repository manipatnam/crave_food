// lib/screens/reviews_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reviews_service.dart';
import '../models/restaurant_review.dart';
import '../widgets/reviews/review_card.dart';
import '../widgets/reviews/review_filter_chips.dart';
import 'add_review_screen.dart';

class ReviewsFeedScreen extends StatefulWidget {
  const ReviewsFeedScreen({super.key});

  @override
  State<ReviewsFeedScreen> createState() => _ReviewsFeedScreenState();
}

class _ReviewsFeedScreenState extends State<ReviewsFeedScreen>
    with TickerProviderStateMixin {
  final ReviewsService _reviewsService = ReviewsService();
  final ScrollController _scrollController = ScrollController();
  
  // Filter and sort state
  ReviewSortType _currentSort = ReviewSortType.newest;
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Tab controller for different feeds
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurant Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All Reviews'),
            Tab(text: 'Trending'),
            Tab(text: 'My Reviews'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<ReviewSortType>(
            onSelected: (sortType) {
              setState(() {
                _currentSort = sortType;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ReviewSortType.newest,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text('Newest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ReviewSortType.highestRated,
                child: Row(
                  children: [
                    Icon(Icons.star, size: 18),
                    SizedBox(width: 8),
                    Text('Highest Rated'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ReviewSortType.mostHelpful,
                child: Row(
                  children: [
                    Icon(Icons.thumb_up, size: 18),
                    SizedBox(width: 8),
                    Text('Most Helpful'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Reviews Tab
          _buildReviewsFeed(ReviewFeedType.all),
          
          // Trending Tab
          _buildReviewsFeed(ReviewFeedType.trending),
          
          // My Reviews Tab
          _buildReviewsFeed(ReviewFeedType.user),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReviewScreen(),
            ),
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.rate_review),
        label: const Text('Write Review'),
      ),
    );
  }

  Widget _buildReviewsFeed(ReviewFeedType feedType) {
    return Column(
      children: [
        // Filter Chips
        if (feedType == ReviewFeedType.all)
          ReviewFilterChips(
            onSortChanged: (sortType) {
              setState(() {
                _currentSort = sortType;
              });
            },
            currentSort: _currentSort,
          ),
        
        // Reviews List
        Expanded(
          child: _buildReviewsList(feedType),
        ),
      ],
    );
  }

  Widget _buildReviewsList(ReviewFeedType feedType) {
    return StreamBuilder<List<RestaurantReview>>(
      stream: _getReviewStream(feedType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return _buildEmptyState(feedType);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic would go here
            setState(() {});
          },
          color: Colors.orange,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ReviewCard(
                  review: review,
                  onHelpfulTap: () => _toggleHelpfulVote(review),
                  onRestaurantTap: () => _navigateToRestaurant(review.restaurantId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<RestaurantReview>> _getReviewStream(ReviewFeedType feedType) {
    switch (feedType) {
      case ReviewFeedType.all:
        return _reviewsService.getPublicReviews(
          sortBy: _currentSort,
          limit: 50,
        );
      case ReviewFeedType.trending:
        // For trending, we'll use newest for now
        // Later: implement trending algorithm
        return _reviewsService.getPublicReviews(
          sortBy: ReviewSortType.mostHelpful,
          limit: 30,
        );
      case ReviewFeedType.user:
        return _reviewsService.getUserReviews(
          sortBy: _currentSort,
          limit: 100,
        );
    }
  }

  Widget _buildEmptyState(ReviewFeedType feedType) {
    IconData icon;
    String title;
    String subtitle;
    String buttonText;
    VoidCallback? buttonAction;

    switch (feedType) {
      case ReviewFeedType.all:
        icon = Icons.rate_review_outlined;
        title = 'No reviews yet';
        subtitle = 'Be the first to share your dining experience!';
        buttonText = 'Write First Review';
        buttonAction = () => _navigateToWriteReview();
        break;
      case ReviewFeedType.trending:
        icon = Icons.trending_up_outlined;
        title = 'No trending reviews';
        subtitle = 'Popular reviews will appear here once people start reviewing.';
        buttonText = 'Write a Review';
        buttonAction = () => _navigateToWriteReview();
        break;
      case ReviewFeedType.user:
        icon = Icons.person_outline;
        title = 'No reviews written yet';
        subtitle = 'Start reviewing restaurants to see your reviews here.';
        buttonText = 'Write Your First Review';
        buttonAction = () => _navigateToWriteReview();
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: buttonAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.rate_review),
                label: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load reviews. Please try again.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  // Trigger rebuild to retry
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Reviews'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search restaurants or reviews...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            // Implement search functionality
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    
    // Implement search logic here
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for "$query"...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleHelpfulVote(RestaurantReview review) async {
    try {
      // Check if user already voted
      // For now, just add the vote
      await _reviewsService.addHelpfulVote(review.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRestaurant(String restaurantId) {
    // Navigate to restaurant detail page
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to restaurant: $restaurantId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddReviewScreen(),
      ),
    );
  }
}

// Enum for different feed types
enum ReviewFeedType {
  all,
  trending,
  user,
}