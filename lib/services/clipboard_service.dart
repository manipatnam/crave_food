import 'package:flutter/services.dart';

class ClipboardService {
  // Check if clipboard contains Instagram URL
  static Future<String?> getInstagramLinkFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      if (clipboardText != null && _isInstagramUrl(clipboardText)) {
        print('📋 Found Instagram URL in clipboard: $clipboardText');
        return clipboardText;
      }
      
      return null;
    } catch (e) {
      print('❌ Error reading clipboard: $e');
      return null;
    }
  }
  
  // Check if clipboard contains any social media URL
  static Future<String?> getSocialMediaLinkFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      if (clipboardText != null && _isSocialMediaUrl(clipboardText)) {
        print('📋 Found social media URL in clipboard: $clipboardText');
        return clipboardText;
      }
      
      return null;
    } catch (e) {
      print('❌ Error reading clipboard: $e');
      return null;
    }
  }
  
  // Check if text is Instagram URL
  static bool _isInstagramUrl(String text) {
    final instagramPatterns = [
      r'https?://(?:www\.)?instagram\.com/',
      r'https?://(?:www\.)?instagr\.am/',
      r'https?://ig\.me/',
    ];
    
    for (String pattern in instagramPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Check if text is any social media URL
  static bool _isSocialMediaUrl(String text) {
    final socialMediaPatterns = [
      // Instagram
      r'https?://(?:www\.)?instagram\.com/',
      r'https?://(?:www\.)?instagr\.am/',
      r'https?://ig\.me/',
      
      // YouTube
      r'https?://(?:www\.)?youtube\.com/',
      r'https?://(?:www\.)?youtu\.be/',
      
      // Facebook
      r'https?://(?:www\.)?facebook\.com/',
      r'https?://(?:www\.)?fb\.com/',
      r'https?://(?:www\.)?fb\.me/',
      
      // Twitter/X
      r'https?://(?:www\.)?twitter\.com/',
      r'https?://(?:www\.)?x\.com/',
      r'https?://(?:www\.)?t\.co/',
      
      // TikTok
      r'https?://(?:www\.)?tiktok\.com/',
      r'https?://(?:www\.)?vm\.tiktok\.com/',
      
      // LinkedIn
      r'https?://(?:www\.)?linkedin\.com/',
      
      // Snapchat
      r'https?://(?:www\.)?snapchat\.com/',
    ];
    
    for (String pattern in socialMediaPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Get platform name from URL
  static String getPlatformName(String url) {
    if (url.contains('instagram.com') || url.contains('instagr.am') || url.contains('ig.me')) {
      return 'Instagram';
    } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube';
    } else if (url.contains('facebook.com') || url.contains('fb.com') || url.contains('fb.me')) {
      return 'Facebook';
    } else if (url.contains('twitter.com') || url.contains('x.com') || url.contains('t.co')) {
      return 'Twitter/X';
    } else if (url.contains('tiktok.com')) {
      return 'TikTok';
    } else if (url.contains('linkedin.com')) {
      return 'LinkedIn';
    } else if (url.contains('snapchat.com')) {
      return 'Snapchat';
    }
    
    return 'Social Media';
  }
  
  // Clear clipboard (optional, for privacy)
  static Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      print('🧹 Clipboard cleared');
    } catch (e) {
      print('❌ Error clearing clipboard: $e');
    }
  }
}