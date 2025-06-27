// Favorites Filter Panel Widget (Fixed)
// lib/widgets/favourites/favorites_filter_panel.dart

import 'package:flutter/material.dart';

class FavoritesFilterPanel extends StatelessWidget {
  final List<String> selectedCategories;
  final List<String> selectedTags;
  final double minRating;
  final bool showOpenOnly;
  final bool showVegOnly;
  final bool showNonVegOnly;
  final String searchQuery;
  final Function({
    String? searchQuery,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    double? minRating,
    bool? showOpenOnly,
    bool? showVegOnly,
    bool? showNonVegOnly,
  }) onFiltersChanged;
  final VoidCallback onClearFilters;

  const FavoritesFilterPanel({
    super.key,
    required this.selectedCategories,
    required this.selectedTags,
    required this.minRating,
    required this.showOpenOnly,
    required this.showVegOnly,
    required this.showNonVegOnly,
    required this.searchQuery,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSearchField(context),
          const SizedBox(height: 16),
          _buildRatingFilter(context),
          const SizedBox(height: 16),
          _buildToggleFilters(context),
          const SizedBox(height: 16),
          _buildCategoryFilter(context),
          if (selectedCategories.isNotEmpty || selectedTags.isNotEmpty || minRating > 0 || 
              showOpenOnly || showVegOnly || showNonVegOnly) ...[
            const SizedBox(height: 16),
            _buildActiveFilters(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onClearFilters,
          child: const Text('Clear All'),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      onChanged: (value) => onFiltersChanged(searchQuery: value),
      decoration: InputDecoration(
        hintText: 'Search favourites...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating: ${minRating.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          onChanged: (value) => onFiltersChanged(minRating: value),
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildToggleFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              context,
              'Open Now',
              showOpenOnly,
              Icons.access_time_rounded,
              () => onFiltersChanged(showOpenOnly: !showOpenOnly),
            ),
            _buildFilterChip(
              context,
              'Vegetarian',
              showVegOnly,
              Icons.eco_rounded,
              () => onFiltersChanged(showVegOnly: !showVegOnly),
            ),
            _buildFilterChip(
              context,
              'Non-Vegetarian',
              showNonVegOnly,
              Icons.restaurant_rounded,
              () => onFiltersChanged(showNonVegOnly: !showNonVegOnly),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final availableCategories = [
      'Italian', 'Chinese', 'Indian', 'Mexican', 'Japanese', 'Thai',
      'American', 'Mediterranean', 'Fast Food', 'Cafe', 'Dessert'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableCategories.map((category) {
            final isSelected = selectedCategories.contains(category);
            return _buildFilterChip(
              context,
              category,
              isSelected,
              Icons.restaurant_menu_rounded,
              () {
                final newCategories = List<String>.from(selectedCategories);
                if (isSelected) {
                  newCategories.remove(category);
                } else {
                  newCategories.add(category);
                }
                onFiltersChanged(selectedCategories: newCategories);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    IconData icon,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).colorScheme.background,
      side: BorderSide(
        color: isSelected 
            ? Theme.of(context).primaryColor 
            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final activeFilters = <Widget>[];

    if (selectedCategories.isNotEmpty) {
      for (final category in selectedCategories) {
        activeFilters.add(_buildActiveFilterChip(context, category, () {
          final newCategories = List<String>.from(selectedCategories);
          newCategories.remove(category);
          onFiltersChanged(selectedCategories: newCategories);
        }));
      }
    }

    if (minRating > 0) {
      activeFilters.add(_buildActiveFilterChip(
        context,
        'Rating ${minRating.toStringAsFixed(1)}+',
        () => onFiltersChanged(minRating: 0.0),
      ));
    }

    if (showOpenOnly) {
      activeFilters.add(_buildActiveFilterChip(
        context,
        'Open Now',
        () => onFiltersChanged(showOpenOnly: false),
      ));
    }

    if (showVegOnly) {
      activeFilters.add(_buildActiveFilterChip(
        context,
        'Vegetarian',
        () => onFiltersChanged(showVegOnly: false),
      ));
    }

    if (showNonVegOnly) {
      activeFilters.add(_buildActiveFilterChip(
        context,
        'Non-Vegetarian',
        () => onFiltersChanged(showNonVegOnly: false),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Filters',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${activeFilters.length} active',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeFilters,
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(BuildContext context, String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}