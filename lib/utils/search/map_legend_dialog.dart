// lib/utils/map_legend_dialog.dart

import 'package:flutter/material.dart';

class MapLegendDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Map Legend'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem('📍🟢', 'Vegetarian Only', 'Green pins - Restaurants serving only vegetarian food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🔴', 'Non-Vegetarian Only', 'Red pins - Restaurants serving only non-vegetarian food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟠', 'Mixed Options', 'Orange pins - Restaurants serving both veg & non-veg food'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟣', 'Default', 'Purple pins - Restaurants with unspecified dietary options'),
              const SizedBox(height: 12),
              _buildLegendItem('📍🟡', 'Search Results', 'Yellow pins - Restaurants from your current search'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tip: Use filters to narrow down results and find exactly what you\'re looking for!',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildLegendItem(String icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}