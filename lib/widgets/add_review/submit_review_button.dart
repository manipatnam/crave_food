// lib/widgets/add_review/submit_review_button.dart

import 'package:flutter/material.dart';

class SubmitReviewButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final bool isEnabled;

  const SubmitReviewButton({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Submit Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          child: ElevatedButton(
            onPressed: (isEnabled && !isSubmitting) ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? Colors.orange : Colors.grey[300],
              foregroundColor: isEnabled ? Colors.white : Colors.grey[600],
              elevation: isEnabled ? 3 : 0,
              shadowColor: Colors.orange.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isEnabled ? Colors.white : Colors.grey[600]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Submitting Review...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        size: 20,
                        color: isEnabled ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        // Status Message
        const SizedBox(height: 12),
        _buildStatusMessage(),
        
        // Help Text
        if (!isSubmitting) ...[
          const SizedBox(height: 8),
          Text(
            'By submitting, you agree that your review is honest and based on your own experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (isSubmitting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Creating your review and updating restaurant data...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (!isEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.red[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please select a restaurant and write a review to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.green[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ready to submit! Your review will help others discover great places.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}