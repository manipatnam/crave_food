// Place Info Sheet for Selected Places
// lib/widgets/search/place_info_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../models/place_model.dart';

class PlaceInfoSheet extends StatelessWidget {
  final PlaceModel place;
  final LatLng? currentLocation;
  final VoidCallback onAddToFavourites;
  final VoidCallback? onClose;

  const PlaceInfoSheet({
    super.key,
    required this.place,
    this.currentLocation,
    required this.onAddToFavourites,
    this.onClose,
  });

  String _getDistance() {
    if (currentLocation == null) return '';
    
    final placeLocation = LatLng(
      place.geoPoint.latitude,
      place.geoPoint.longitude,
    );
    
    // Simple distance calculation
    final distance = _calculateDistance(
      currentLocation!.latitude,
      currentLocation!.longitude,
      placeLocation.latitude,
      placeLocation.longitude,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m away';
    } else {
      return '${distance.toStringAsFixed(1)} km away';
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double latDiff = _degreesToRadians(lat2 - lat1);
    double lonDiff = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(lonDiff / 2) * math.sin(lonDiff / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
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

  Future<void> _openMaps() async {
    final lat = place.geoPoint.latitude;
    final lng = place.geoPoint.longitude;
    
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    await _launchUrl(googleMapsUrl);
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
                              child: place.photoUrl != null
                                  ? Image.network(
                                      place.photoUrl!,
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
                                  place.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (place.rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        place.rating!.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      if (place.userRatingsTotal != null) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${place.userRatingsTotal})',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                if (currentLocation != null)
                                  Text(
                                    _getDistance(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Close button
                          if (onClose != null)
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close, color: Colors.grey),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.displayAddress,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status indicators
                      Row(
                        children: [
                          // Open/Closed status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: place.isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.isOpen ? 'Open Now' : 'Closed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // Price level
                          if (place.priceLevel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Text(
                                place.priceLevel!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      Row(
                        children: [
                          // Directions button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openMaps,
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add to favorites button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onAddToFavourites,
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('Add to Favorites'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contact information
                      if (place.phoneNumber != null || place.website != null) ...[
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Phone
                        if (place.phoneNumber != null)
                          ListTile(
                            leading: const Icon(Icons.phone, color: Colors.blue),
                            title: Text(place.phoneNumber!),
                            trailing: const Icon(Icons.call, size: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                            ),
                            tileColor: Colors.blue.withOpacity(0.05),
                            onTap: () => _launchUrl('tel:${place.phoneNumber}'),
                          ),
                        
                        if (place.phoneNumber != null && place.website != null)
                          const SizedBox(height: 8),
                        
                        // Website
                        if (place.website != null)
                          ListTile(
                            leading: const Icon(Icons.language, color: Colors.green),
                            title: Text(
                              place.website!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.open_in_new, size: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.green.withOpacity(0.3)),
                            ),
                            tileColor: Colors.green.withOpacity(0.05),
                            onTap: () => _launchUrl(place.website!),
                          ),
                      ],
                      
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