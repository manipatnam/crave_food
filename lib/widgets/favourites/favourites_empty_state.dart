import 'package:flutter/material.dart';

class FavouritesEmptyState extends StatelessWidget {
  final VoidCallback onAddFavourite;

  const FavouritesEmptyState({
    super.key,
    required this.onAddFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(75),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Favourites Yet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start your culinary journey by adding\nyour favorite restaurants and dishes!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: onAddFavourite,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Favourite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}