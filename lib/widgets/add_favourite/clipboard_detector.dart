import 'package:flutter/material.dart';
import '../../services/clipboard_service.dart';

class ClipboardDetector extends StatefulWidget {
  final Function(String) onSocialUrlDetected;

  const ClipboardDetector({
    super.key,
    required this.onSocialUrlDetected,
  });

  @override
  State<ClipboardDetector> createState() => _ClipboardDetectorState();
}

class _ClipboardDetectorState extends State<ClipboardDetector> {
  bool _clipboardChecked = false;
  String? _detectedSocialUrl;

  @override
  void initState() {
    super.initState();
    _checkClipboardForSocialLinks();
  }

  // Check clipboard for social media links when screen loads
  Future<void> _checkClipboardForSocialLinks() async {
    if (_clipboardChecked) return;
    
    try {
      print('📋 Checking clipboard for social media links...');
      
      // Check for any social media URL (not just Instagram)
      final socialUrl = await ClipboardService.getSocialMediaLinkFromClipboard();
      
      if (socialUrl != null && mounted) {
        setState(() {
          _detectedSocialUrl = socialUrl;
          _clipboardChecked = true;
        });
        
        // Show dialog to ask user if they want to use the detected link
        _showClipboardDetectionDialog(socialUrl);
      } else {
        setState(() {
          _clipboardChecked = true;
        });
        print('📋 No social media links found in clipboard');
      }
    } catch (e) {
      print('❌ Error checking clipboard: $e');
      setState(() {
        _clipboardChecked = true;
      });
    }
  }

  // Show dialog when social media link is detected
  void _showClipboardDetectionDialog(String url) {
    final platformName = ClipboardService.getPlatformName(url);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForPlatform(platformName),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$platformName Link Detected!',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found a $platformName link in your clipboard. Would you like to add it to this place?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _detectedSocialUrl = null;
                });
              },
              child: Text(
                'No, thanks',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSocialUrlDetected(url);
                setState(() {
                  _detectedSocialUrl = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, add it!'),
            ),
          ],
        );
      },
    );
  }

  // Get icon for social media platform
  IconData _getIconForPlatform(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle;
      case 'facebook':
        return Icons.facebook;
      case 'twitter/x':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_video;
      case 'linkedin':
        return Icons.business;
      case 'snapchat':
        return Icons.camera;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is invisible but handles clipboard detection
    return const SizedBox.shrink();
  }
}