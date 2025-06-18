import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/place_model.dart';
import '../../widgets/custom_text_field.dart';

class TimingInformationSection extends StatelessWidget {
  final PlaceModel? selectedPlace;
  final TimeOfDay? userOpeningTime;
  final TimeOfDay? userClosingTime;
  final TextEditingController timingNotesController;
  final Function(TimeOfDay?) onOpeningTimeChanged;
  final Function(TimeOfDay?) onClosingTimeChanged;

  const TimingInformationSection({
    super.key,
    required this.selectedPlace,
    required this.userOpeningTime,
    required this.userClosingTime,
    required this.timingNotesController,
    required this.onOpeningTimeChanged,
    required this.onClosingTimeChanged,
  });

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final formatter = DateFormat('h:mm a');
    final dateTime = DateTime(2000, 1, 1, time.hour, time.minute);
    return formatter.format(dateTime);
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timing Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Google Places Status (if available)
          if (selectedPlace?.isOpen != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedPlace!.isOpen! 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedPlace!.isOpen! 
                    ? Colors.green.withOpacity(0.3) 
                    : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedPlace!.isOpen! ? Icons.check_circle : Icons.cancel,
                    color: selectedPlace!.isOpen! ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Google Places: Currently ${selectedPlace!.isOpen! ? 'Open' : 'Closed'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selectedPlace!.isOpen! ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          
          if (selectedPlace?.isOpen != null) const SizedBox(height: 16),
          
          // User Timing Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Your Observed Timings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your own timing observations (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time Pickers Section
                Column(
                  children: [
                    // Opening Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Opening Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: userOpeningTime ?? const TimeOfDay(hour: 9, minute: 0),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                      primary: Colors.blue,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              onOpeningTimeChanged(picked);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatTimeOfDay(userOpeningTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: userOpeningTime != null ? Colors.black87 : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                if (userOpeningTime != null)
                                  GestureDetector(
                                    onTap: () => onOpeningTimeChanged(null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Closing Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Closing Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: userClosingTime ?? const TimeOfDay(hour: 22, minute: 0),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                      primary: Colors.blue,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              onClosingTimeChanged(picked);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatTimeOfDay(userClosingTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: userClosingTime != null ? Colors.black87 : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                if (userClosingTime != null)
                                  GestureDetector(
                                    onTap: () => onClosingTimeChanged(null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Timing Notes
                CustomTextField(
                  controller: timingNotesController,
                  hintText: 'Add timing notes (e.g., "Closes early on Sundays", "Call ahead for reservations")',
                  prefixIcon: Icons.note_alt,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          
          // Helper text
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your timing info complements Google\'s real-time data with personal observations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}