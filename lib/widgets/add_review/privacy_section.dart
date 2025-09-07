// lib/widgets/add_review/privacy_section.dart

import 'package:flutter/material.dart';
import '../../models/review_enums.dart';

class PrivacySection extends StatelessWidget {
  final ReviewPrivacy privacy;
  final Function(ReviewPrivacy) onPrivacyChanged;

  const PrivacySection({
    super.key,
    required this.privacy,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.visibility,
              color: Colors.blueGrey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Review Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Description
        Text(
          'Choose who can see your review',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Privacy Options
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: Column(
            children: ReviewPrivacy.values.map((privacyOption) {
              final isSelected = privacy == privacyOption;
              final isFirst = privacyOption == ReviewPrivacy.values.first;
              final isLast = privacyOption == ReviewPrivacy.values.last;
              
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? _getPrivacyColor(privacyOption).withOpacity(0.1) : null,
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? const Radius.circular(11) : Radius.zero,
                    bottom: isLast ? const Radius.circular(11) : Radius.zero,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () => onPrivacyChanged(privacyOption),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? _getPrivacyColor(privacyOption) 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getPrivacyIcon(privacyOption),
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            privacyOption.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? _getPrivacyColor(privacyOption) 
                                  : Colors.black87,
                            ),
                          ),
                          if (privacyOption == ReviewPrivacy.public) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                          if (privacyOption == ReviewPrivacy.friends) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getPrivacyDescription(privacyOption),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ),
                      trailing: Radio<ReviewPrivacy>(
                        value: privacyOption,
                        groupValue: privacy,
                        onChanged: (ReviewPrivacy? value) {
                          if (value != null) {
                            onPrivacyChanged(value);
                          }
                        },
                        activeColor: _getPrivacyColor(privacyOption),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                    
                    // Divider (except for last item)
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: Colors.grey[200],
                        indent: 72,
                        endIndent: 16,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        // Additional Info for Selected Privacy
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPrivacyColor(privacy).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPrivacyColor(privacy).withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: _getPrivacyColor(privacy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${privacy.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPrivacyColor(privacy),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDetailedDescription(privacy),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getPrivacyColor(privacy).withOpacity(0.8),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Future Features Note (if friends or private selected)
        if (privacy != ReviewPrivacy.public) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Social features are coming soon! For now, all reviews are public.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getPrivacyIcon(ReviewPrivacy privacy) {
    switch (privacy) {
      case ReviewPrivacy.public:
        return Icons.public;
      case ReviewPrivacy.friends:
        return Icons.people;
      case ReviewPrivacy.private:
        return Icons.lock;
    }
  }

  Color _getPrivacyColor(ReviewPrivacy privacy) {
    switch (privacy) {
      case ReviewPrivacy.public:
        return Colors.green;
      case ReviewPrivacy.friends:
        return Colors.blue;
      case ReviewPrivacy.private:
        return Colors.grey;
    }
  }

  String _getPrivacyDescription(ReviewPrivacy privacy) {
    switch (privacy) {
      case ReviewPrivacy.public:
        return 'Anyone can see this review and it helps other users discover great places';
      case ReviewPrivacy.friends:
        return 'Only your friends can see this review in their personalized feed';
      case ReviewPrivacy.private:
        return 'Only you can see this review - great for personal notes';
    }
  }

  String _getDetailedDescription(ReviewPrivacy privacy) {
    switch (privacy) {
      case ReviewPrivacy.public:
        return 'Your review will appear in public feeds, restaurant pages, and search results. This helps the community discover great places!';
      case ReviewPrivacy.friends:
        return 'Your review will only be visible to people you follow. Perfect for sharing recommendations with your circle.';
      case ReviewPrivacy.private:
        return 'Your review is completely private and only visible to you. Use this for personal dining notes and memories.';
    }
  }
}