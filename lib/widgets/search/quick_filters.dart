import 'package:flutter/material.dart';

class QuickFilters extends StatelessWidget {
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;
  final bool showFavoritesOnly;
  final Function({
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
    bool? showFavoritesOnly,
  }) onFiltersChanged;

  const QuickFilters({
    super.key,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.showFavoritesOnly,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Open Now'),
              selected: showOpenOnly,
              onSelected: (selected) => onFiltersChanged(showOpenOnly: selected),
            ),
            FilterChip(
              label: const Text('Vegetarian'),
              selected: showVegOnly,
              onSelected: (selected) => onFiltersChanged(
                showVegOnly: selected,
                showNonVegOnly: selected ? false : showNonVegOnly,
              ),
            ),
            FilterChip(
              label: const Text('Non-Vegetarian'),
              selected: showNonVegOnly,
              onSelected: (selected) => onFiltersChanged(
                showNonVegOnly: selected,
                showVegOnly: selected ? false : showVegOnly,
              ),
            ),
            FilterChip(
              label: const Text('Favorites Only'),
              selected: showFavoritesOnly,
              onSelected: (selected) => onFiltersChanged(showFavoritesOnly: selected),
            ),
          ],
        ),
      ],
    );
  }
}