// lib/widgets/add_review/written_review_section.dart

import 'package:flutter/material.dart';

class WrittenReviewSection extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const WrittenReviewSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<WrittenReviewSection> createState() => _WrittenReviewSectionState();
}

class _WrittenReviewSectionState extends State<WrittenReviewSection> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    widget.controller.addListener(widget.onChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterCount = widget.controller.text.length;
    final minCharacters = 50;
    final maxCharacters = 500;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.edit_note,
              color: Colors.deepPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Share Your Experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Description with tips
        Text(
          'Tell others about your experience. What made it special or what could be improved?',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Text Input Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? Colors.deepPurple : 
                     characterCount < minCharacters ? Colors.red[300]! :
                     Colors.grey[300]!,
              width: _isFocused ? 2 : 1,
            ),
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
              // Main Text Field
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: 6,
                minLines: 4,
                maxLength: maxCharacters,
                decoration: InputDecoration(
                  hintText: 'Write your review here...\n\nTip: Mention specific dishes, service quality, ambience, or any memorable moments.',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '', // Hide the default counter
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              
              // Custom Footer with Character Count and Tips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    // Writing Tips Icon
                    if (characterCount < minCharacters)
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                    if (characterCount < minCharacters)
                      const SizedBox(width: 6),
                    
                    // Status Text
                    Expanded(
                      child: Text(
                        characterCount < minCharacters 
                            ? 'Write at least ${minCharacters - characterCount} more characters for a helpful review'
                            : characterCount >= minCharacters && characterCount <= maxCharacters * 0.8
                                ? 'Great! Keep going...'
                                : characterCount > maxCharacters * 0.8
                                    ? 'Almost at the limit'
                                    : 'Perfect length!',
                        style: TextStyle(
                          fontSize: 11,
                          color: characterCount < minCharacters ? Colors.red[600] :
                                 characterCount > maxCharacters * 0.8 ? Colors.orange[700] :
                                 Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // Character Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: characterCount < minCharacters ? Colors.red[100] :
                               characterCount > maxCharacters * 0.8 ? Colors.orange[100] :
                               Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$characterCount/$maxCharacters',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: characterCount < minCharacters ? Colors.red[700] :
                                 characterCount > maxCharacters * 0.8 ? Colors.orange[700] :
                                 Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Writing Tips (shown when focused or text is short)
        if (_isFocused || characterCount < minCharacters) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tips for a helpful review:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._buildTips().map((tip) => Padding(
                  padding: const EdgeInsets.only(left: 22, top: 2),
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      height: 1.2,
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
        
        // Validation Message
        if (characterCount > 0 && characterCount < minCharacters) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.red[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Please write at least $minCharacters characters for a complete review',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<String> _buildTips() {
    return [
      '• Mention specific dishes you tried and how they tasted',
      '• Describe the service quality and staff behavior', 
      '• Share details about the atmosphere and cleanliness',
      '• Include any special moments or memorable experiences',
      '• Be honest but constructive in your feedback',
    ];
  }
}