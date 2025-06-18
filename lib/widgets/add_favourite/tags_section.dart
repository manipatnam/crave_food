import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';

class TagsSection extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final VoidCallback onAddTag;
  final Function(int) onRemoveTag;

  // Predefined tag suggestions
  static const List<String> suggestedTags = [
    'buffet',
    'desserts',
    'main course',
    'quick bites',
    'family dining',
    'romantic',
    'casual',
    'fine dining',
    'breakfast',
    'lunch',
    'dinner',
    'late night',
    'takeaway',
    'delivery',
    'outdoor seating',
    'air conditioned',
    'budget friendly',
    'premium',
    'authentic',
    'fusion',
    'street food',
    'pure veg',
    'live music',
    'party place',
    'quiet ambiance',
  ];

  const TagsSection({
    super.key,
    required this.controller,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  Color _getTagColor(String tag) {
    // Different colors for different tag categories
    if (['buffet', 'desserts', 'main course', 'quick bites'].contains(tag)) {
      return Colors.orange;
    } else if (['family dining', 'romantic', 'casual', 'fine dining'].contains(tag)) {
      return Colors.purple;
    } else if (['breakfast', 'lunch', 'dinner', 'late night'].contains(tag)) {
      return Colors.blue;
    } else if (['takeaway', 'delivery', 'outdoor seating', 'air conditioned'].contains(tag)) {
      return Colors.green;
    } else if (['budget friendly', 'premium'].contains(tag)) {
      return Colors.amber;
    } else {
      return Colors.indigo;
    }
  }

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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.label,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tags.length} tags',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add tags to help categorize and find this restaurant easily',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          
          // Add tag input
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller,
                  hintText: 'Add a tag...',
                  prefixIcon: Icons.add_circle_outline,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAddTag,
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
          
          const SizedBox(height: 16),
          
          // Suggested tags
          if (tags.length < 8) ...[
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Suggested tags:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestedTags
                  .where((tag) => !tags.contains(tag))
                  .take(6)
                  .map((tag) {
                final color = _getTagColor(tag);
                return GestureDetector(
                  onTap: () {
                    controller.text = tag;
                    onAddTag();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
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
          
          // Current tags display
          if (tags.isNotEmpty) ...[
            const Text(
              'Your tags:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                final color = _getTagColor(tag);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: color.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => onRemoveTag(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
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