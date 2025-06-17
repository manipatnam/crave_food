import 'package:flutter/material.dart';
import '../../models/favourite_model.dart';

class NotesSection extends StatelessWidget {
  final Favourite favourite;

  const NotesSection({
    super.key,
    required this.favourite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.note_alt,
                size: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Notes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Text(
            favourite.userNotes!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}