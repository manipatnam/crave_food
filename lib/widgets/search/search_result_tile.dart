// Search Result Tile Widget - Exact copy from enhanced search screen
// lib/widgets/search/search_result_tile.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/place_model.dart';
import '../../services/location_service.dart';

class SearchResultTile extends StatelessWidget {
  final PlaceModel place;
  final bool isLast;
  final LatLng? currentLocation;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.place,
    required this.isLast,
    required this.currentLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distance = currentLocation != null 
        ? LocationService.calculateDistance(
            currentLocation!,
            LatLng(place.geoPoint.latitude, place.geoPoint.longitude),
          )
        : 0.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          place.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.displayAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                place.displayAddress,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (place.rating != null && place.rating! > 0) ...[
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.orange[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (currentLocation != null) ...[
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onTap,
          icon: Icon(
            Icons.add_circle_rounded,
            color: Theme.of(context).primaryColor,
          ),
          tooltip: 'Add to Favorites',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}