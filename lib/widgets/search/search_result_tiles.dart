// Search Result Tiles
// lib/widgets/search/search_result_tiles.dart

import 'package:flutter/material.dart';
import '../../models/search/recent_search_model.dart';
import '../../models/place_model.dart';

// Recent Search Tile (with clock icon)
class RecentSearchTile extends StatelessWidget {
  final RecentSearch recentSearch;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String? distanceText;

  const RecentSearchTile({
    super.key,
    required this.recentSearch,
    required this.onTap,
    this.onRemove,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Clock icon for recent searches
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.grey,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    recentSearch.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Address
                  Text(
                    recentSearch.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Status (Open/Closed) if available
                  if (recentSearch.status != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      recentSearch.status!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(recentSearch.status!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Distance if available
            if (distanceText != null && distanceText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                distanceText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            // Remove button (optional)
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 18,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('open')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('closed')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}

// Live Search Result Tile (with location pin icon)
class LiveSearchTile extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;
  final String? distanceText;

  const LiveSearchTile({
    super.key,
    required this.place,
    required this.onTap,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Location pin icon for search results
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.grey,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Address
                  Text(
                    place.displayAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Opening hours if available
                  const SizedBox(height: 2),
                  Text(
                    place.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: place.isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Distance
            if (distanceText != null && distanceText!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                distanceText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Section Header Widget
class SearchSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClearAll;

  const SearchSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (onClearAll != null)
            TextButton(
              onPressed: onClearAll,
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Empty State Widget
class SearchEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;

  const SearchEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.search_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}