import 'package:flutter/material.dart';
import '../../models/place_model.dart';

class SelectedPlaceCard extends StatelessWidget {
  final PlaceModel? selectedPlace;
  final VoidCallback onClear;

  const SelectedPlaceCard({
    super.key,
    required this.selectedPlace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPlace == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: selectedPlace!.photoUrl != null
                  ? Image.network(
                      selectedPlace!.photoUrl!,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Selected Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selectedPlace!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (selectedPlace!.rating != null || selectedPlace!.cuisineTypes.isNotEmpty)
                  Row(
                    children: [
                      if (selectedPlace!.rating != null) ...[
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          selectedPlace!.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (selectedPlace!.rating != null && selectedPlace!.cuisineTypes.isNotEmpty)
                        const Text(' • ', style: TextStyle(fontSize: 12)),
                      if (selectedPlace!.cuisineTypes.isNotEmpty)
                        Expanded(
                          child: Text(
                            selectedPlace!.cuisineTypes,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}