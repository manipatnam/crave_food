// FILE: lib/widgets/search/restaurant_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/favourite_model.dart';
import '../../services/location_service.dart';

class RestaurantInfoSheet extends StatelessWidget {
  final Favourite favourite;
  final LatLng currentLocation;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  const RestaurantInfoSheet({
    super.key,
    required this.favourite,
    required this.currentLocation,
    required this.onNavigate,
    required this.onClose,
  });

  String _getDistance() {
    final restaurantLocation = LatLng(
      favourite.coordinates.latitude,
      favourite.coordinates.longitude,
    );
    final distance = LocationService.calculateDistance(currentLocation, restaurantLocation);
    return LocationService.formatDistance(distance);
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with image and basic info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Restaurant image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: favourite.restaurantImageUrl != null
                                  ? Image.network(
                                      favourite.restaurantImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.restaurant,
                                        size: 40,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.restaurant,
                                      size: 40,
                                      color: Theme.of(context).primaryColor,
                                    ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Restaurant details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  favourite.restaurantName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (favourite.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        favourite.rating!.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '📍 ${_getDistance()} away',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Close button
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Status indicators
                      Row(
                        children: [
                          if (favourite.dietaryOptionsDisplay.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Text(
                                favourite.dietaryOptionsDisplay,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (favourite.isOpen != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: favourite.isOpen! ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                favourite.isOpen! ? 'Open Now' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Food items
                      if (favourite.foodNames.isNotEmpty) ...[
                        const Text(
                          '🍽️ Your Favorite Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: favourite.foodNames.map((food) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                food,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Timing information
                      if (favourite.userTimingDisplay.isNotEmpty || favourite.timingNotes != null) ...[
                        const Text(
                          '⏰ Timing Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (favourite.userTimingDisplay.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.blue, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  favourite.userTimingDisplay,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        if (favourite.timingNotes != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              favourite.timingNotes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                      
                      // Tags
                      if (favourite.tags.isNotEmpty) ...[
                        const Text(
                          '🏷️ Tags',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: favourite.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Social links
                      if (favourite.hasSocialUrls) ...[
                        const Text(
                          '🔗 Social Links',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: favourite.socialUrls.map((url) {
                            String platformName = 'Link';
                            IconData iconData = Icons.link;
                            Color iconColor = Colors.blue;
                            
                            if (url.contains('instagram')) {
                              platformName = 'Instagram';
                              iconData = Icons.camera_alt;
                              iconColor = Colors.purple;
                            } else if (url.contains('youtube')) {
                              platformName = 'YouTube';
                              iconData = Icons.play_circle;
                              iconColor = Colors.red;
                            } else if (url.contains('facebook')) {
                              platformName = 'Facebook';
                              iconData = Icons.facebook;
                              iconColor = Colors.blue;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(iconData, color: iconColor, size: 20),
                                ),
                                title: Text(
                                  platformName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.open_in_new, size: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: iconColor.withOpacity(0.3)),
                                ),
                                tileColor: iconColor.withOpacity(0.05),
                                onTap: () => _launchUrl(url),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Personal notes
                      if (favourite.userNotes != null && favourite.userNotes!.isNotEmpty) ...[
                        const Text(
                          '📝 Your Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            favourite.userNotes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onNavigate,
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (favourite.phoneNumber != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchUrl('tel:${favourite.phoneNumber}'),
                                icon: const Icon(Icons.phone),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}