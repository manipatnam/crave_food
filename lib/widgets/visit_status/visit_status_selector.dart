// lib/widgets/visit_status/visit_status_selector.dart
// Complete visit status selector widget

import 'package:flutter/material.dart';
import '../../models/visit_status.dart';

class VisitStatusSelector extends StatelessWidget {
  final VisitStatus selectedStatus;
  final Function(VisitStatus) onStatusChanged;
  final bool isCompact;

  const VisitStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactSelector(context);
    }
    return _buildFullSelector(context);
  }

  Widget _buildCompactSelector(BuildContext context) {
    return PopupMenuButton<VisitStatus>(
      initialValue: selectedStatus,
      onSelected: onStatusChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selectedStatus.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selectedStatus.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedStatus.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              selectedStatus.label,
              style: TextStyle(
                color: selectedStatus.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: selectedStatus.color,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => VisitStatus.values.map((status) {
        return PopupMenuItem<VisitStatus>(
          value: status,
          child: Row(
            children: [
              Text(status.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Status',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: VisitStatus.values.map((status) {
            final isSelected = selectedStatus == status;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onStatusChanged(status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? status.color.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? status.color 
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          status.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            color: isSelected ? status.color : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// lib/widgets/visit_status/visit_status_chip.dart
// Simple chip to display status in cards

class VisitStatusChip extends StatelessWidget {
  final VisitStatus status;
  final bool showLabel;
  final double? fontSize;

  const VisitStatusChip({
    super.key,
    required this.status,
    this.showLabel = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.emoji,
            style: TextStyle(fontSize: fontSize ?? 12),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: fontSize ?? 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}