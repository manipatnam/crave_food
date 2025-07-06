import 'package:flutter/material.dart';

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final VoidCallback? onUpdate;

  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      onDeleted: () {
        onRemove();
        if (onUpdate != null) {
          onUpdate!();
        }
      },
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}