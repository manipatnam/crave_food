// lib/widgets/favourites/visit_status_filter_section.dart
// NEW: Filter section for visit status

import 'package:flutter/material.dart';
import '../../models/visit_status.dart';
import '../visit_status/visit_status_selector.dart';

class VisitStatusFilterSection extends StatelessWidget {
  final List<VisitStatus> selectedStatuses;
  final Function(List<VisitStatus>) onStatusesChanged;

  const VisitStatusFilterSection({
    super.key,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Status',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VisitStatus.values.map((status) {
            final isSelected = selectedStatuses.contains(status);
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status.emoji),
                  const SizedBox(width: 4),
                  Text(status.label),
                ],
              ),
              onSelected: (selected) {
                List<VisitStatus> newStatuses = List.from(selectedStatuses);
                if (selected) {
                  newStatuses.add(status);
                } else {
                  newStatuses.remove(status);
                }
                onStatusesChanged(newStatuses);
              },
              selectedColor: status.color.withOpacity(0.2),
              checkmarkColor: status.color,
              side: BorderSide(
                color: isSelected 
                    ? status.color 
                    : Colors.grey.withOpacity(0.3),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Quick filter buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  onStatusesChanged([VisitStatus.notVisited]);
                },
                icon: Text(VisitStatus.notVisited.emoji),
                label: const Text('To Visit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VisitStatus.notVisited.color,
                  side: BorderSide(color: VisitStatus.notVisited.color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  onStatusesChanged([VisitStatus.visited]);
                },
                icon: Text(VisitStatus.visited.emoji),
                label: const Text('Been There'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VisitStatus.visited.color,
                  side: BorderSide(color: VisitStatus.visited.color),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              onStatusesChanged([]);
            },
            child: const Text('Clear Status Filters'),
          ),
        ),
      ],
    );
  }
}