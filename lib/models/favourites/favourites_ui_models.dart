// UI Models for Favourites Feature
// lib/models/favourites/favourites_ui_models.dart

import 'package:flutter/material.dart';

class FavouriteDisplayModel {
  final String id;
  final String restaurantName;
  final String address;
  final double rating;
  final String category;
  final List<String> tags;
  final String notes;
  final DateTime dateAdded;
  final double? distance;
  final bool isExpanded;
  final Color? categoryColor;

  const FavouriteDisplayModel({
    required this.id,
    required this.restaurantName,
    required this.address,
    required this.rating,
    required this.category,
    required this.tags,
    required this.notes,
    required this.dateAdded,
    this.distance,
    this.isExpanded = false,
    this.categoryColor,
  });

  FavouriteDisplayModel copyWith({
    String? id,
    String? restaurantName,
    String? address,
    double? rating,
    String? category,
    List<String>? tags,
    String? notes,
    DateTime? dateAdded,
    double? distance,
    bool? isExpanded,
    Color? categoryColor,
  }) {
    return FavouriteDisplayModel(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      dateAdded: dateAdded ?? this.dateAdded,
      distance: distance ?? this.distance,
      isExpanded: isExpanded ?? this.isExpanded,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}

class FilterChipModel {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const FilterChipModel({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
}

class SortOptionModel {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final String? subtitle;
  final VoidCallback onTap;

  const SortOptionModel({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    this.subtitle,
    required this.onTap,
  });
}

class FilterSummaryModel {
  final int totalFilters;
  final List<String> activeFilters;
  final bool hasActiveFilters;

  const FilterSummaryModel({
    required this.totalFilters,
    required this.activeFilters,
    required this.hasActiveFilters,
  });
}