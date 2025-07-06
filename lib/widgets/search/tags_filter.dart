import 'package:flutter/material.dart';

class TagsFilter extends StatelessWidget {
  final List<String> tags;
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const TagsFilter({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedTags);
                if (selected) {
                  newSelection.add(tag);
                } else {
                  newSelection.remove(tag);
                }
                onTagsChanged(newSelection);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}