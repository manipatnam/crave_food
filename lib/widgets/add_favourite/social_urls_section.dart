import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';

class SocialUrlsSection extends StatelessWidget {
  final TextEditingController controller;
  final List<String> socialUrls;
  final VoidCallback onAddUrl;
  final Function(int) onRemoveUrl;
  final VoidCallback onClipboardCheck;

  const SocialUrlsSection({
    super.key,
    required this.controller,
    required this.socialUrls,
    required this.onAddUrl,
    required this.onRemoveUrl,
    required this.onClipboardCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Social Media Links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Clipboard check button
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: onClipboardCheck,
                  icon: const Icon(
                    Icons.content_paste,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Check clipboard for links',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share from Instagram/social media and we\'ll auto-detect the link!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller,
                  hintText: 'https://instagram.com/restaurant...',
                  prefixIcon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAddUrl,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Social URLs Display
          if (socialUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: socialUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                
                IconData iconData = Icons.link;
                Color iconColor = Colors.blue;
                String platformName = 'Link';
                
                if (url.contains('instagram')) {
                  iconData = Icons.camera_alt;
                  iconColor = Colors.purple;
                  platformName = 'Instagram';
                } else if (url.contains('youtube')) {
                  iconData = Icons.play_circle;
                  iconColor = Colors.red;
                  platformName = 'YouTube';
                } else if (url.contains('facebook')) {
                  iconData = Icons.facebook;
                  iconColor = Colors.blue;
                  platformName = 'Facebook';
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              platformName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                            Text(
                              url,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemoveUrl(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}