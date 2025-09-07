// lib/widgets/add_review/visit_context_section.dart

import 'package:flutter/material.dart';
import '../../models/review_enums.dart';

class VisitContextSection extends StatelessWidget {
  final DateTime visitDate;
  final VisitType visitType;
  final MealTime mealTime;
  final Occasion occasion;
  final Function(DateTime) onVisitDateChanged;
  final Function(VisitType) onVisitTypeChanged;
  final Function(MealTime) onMealTimeChanged;
  final Function(Occasion) onOccasionChanged;

  const VisitContextSection({
    super.key,
    required this.visitDate,
    required this.visitType,
    required this.mealTime,
    required this.occasion,
    required this.onVisitDateChanged,
    required this.onVisitTypeChanged,
    required this.onMealTimeChanged,
    required this.onOccasionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Colors.indigo,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Visit Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Description
        Text(
          'Help others understand the context of your visit',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Visit Date Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.indigo[50],
            border: Border.all(color: Colors.indigo[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visit Date Header
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Colors.indigo,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'When did you visit?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date Picker Button
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigo[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(visitDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Visit Type Section
        _buildSelectionSection(
          'Who did you visit with?',
          Icons.people,
          Colors.teal,
          VisitType.values,
          visitType,
          (VisitType type) => onVisitTypeChanged(type),
          (VisitType type) => type.displayName,
          (VisitType type) => type.emoji,
        ),
        
        const SizedBox(height: 16),
        
        // Meal Time Section
        _buildSelectionSection(
          'What time did you visit?',
          Icons.schedule,
          Colors.orange,
          MealTime.values,
          mealTime,
          (MealTime time) => onMealTimeChanged(time),
          (MealTime time) => time.displayName,
          (MealTime time) => time.emoji,
        ),
        
        const SizedBox(height: 16),
        
        // Occasion Section
        _buildSelectionSection(
          'What was the occasion?',
          Icons.celebration,
          Colors.pink,
          Occasion.values,
          occasion,
          (Occasion occ) => onOccasionChanged(occ),
          (Occasion occ) => occ.displayName,
          (Occasion occ) => occ.emoji,
        ),
      ],
    );
  }

  Widget _buildSelectionSection<T>(
    String title,
    IconData icon,
    Color color,
    List<T> options,
    T selectedValue,
    Function(T) onChanged,
    String Function(T) getDisplayName,
    String Function(T) getEmoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Options Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = option == selectedValue;
              return GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getEmoji(option),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getDisplayName(option),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Selected Value Info (for meal time)
          if (selectedValue is MealTime) ...[
            const SizedBox(height: 8),
            Text(
              (selectedValue as MealTime).timeRange,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final visitDateOnly = DateTime(date.year, date.month, date.day);

    if (visitDateOnly == today) {
      return 'Today';
    } else if (visitDateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago
      lastDate: DateTime.now(), // Cannot select future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.indigo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != visitDate) {
      onVisitDateChanged(picked);
    }
  }
}