// lib/models/visit_status.dart
// Fixed visit status model with proper imports

import 'package:flutter/material.dart'; // ADD this import for Color

enum VisitStatus {
  notVisited('Not Visited', '📝', Color(0xFF9E9E9E)),
  planned('Planned', '📅', Color(0xFF2196F3)),
  visited('Visited', '✅', Color(0xFF4CAF50));

  const VisitStatus(this.label, this.emoji, this.color);
  final String label;
  final String emoji;
  final Color color;

  // Helper method to get status from string (for Firestore)
  static VisitStatus fromString(String? value) {
    switch (value) {
      case 'planned':
        return VisitStatus.planned;
      case 'visited':
        return VisitStatus.visited;
      default:
        return VisitStatus.notVisited;
    }
  }

  // Convert to string for Firestore storage
  String toFirestoreValue() {
    switch (this) {
      case VisitStatus.planned:
        return 'planned';
      case VisitStatus.visited:
        return 'visited';
      case VisitStatus.notVisited:
        return 'not_visited';
    }
  }
}