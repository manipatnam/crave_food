import 'package:flutter/material.dart';

class FavouritesAppBar extends StatelessWidget {
  final bool sortByName;
  final VoidCallback onToggleSort;

  const FavouritesAppBar({
    super.key,
    required this.sortByName,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'My Favourites',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Food Journey',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              sortByName ? Icons.sort_by_alpha : Icons.access_time,
              color: Colors.white,
            ),
            onPressed: onToggleSort,
            tooltip: sortByName ? 'Sort by Date' : 'Sort by Name',
          ),
        ),
      ],
    );
  }
}