import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';

class SocialLinksSection extends StatelessWidget {
  final Favourite favourite;
  final Function(String) onLaunchUrl;

  const SocialLinksSection({
    super.key,
    required this.favourite,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.link,
                size: 16,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Social Links',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: favourite.socialUrls.map((url) {
            IconData iconData = Icons.link;
            Color iconColor = Colors.blue;
            String label = 'Link';
            
            if (url.contains('instagram')) {
              iconData = Icons.camera_alt;
              iconColor = Colors.purple;
              label = 'Instagram';
            } else if (url.contains('youtube')) {
              iconData = Icons.play_circle;
              iconColor = Colors.red;
              label = 'YouTube';
            } else if (url.contains('facebook')) {
              iconData = Icons.facebook;
              iconColor = Colors.blue;
              label = 'Facebook';
            }
            
            return GestureDetector(
              onTap: () => onLaunchUrl(url),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, size: 14, color: iconColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}