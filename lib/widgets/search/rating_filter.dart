import 'package:flutter/material.dart';

class RatingFilter extends StatelessWidget {
  final double minRating;
  final Function(double) onRatingChanged;

  const RatingFilter({
    super.key,
    required this.minRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: minRating,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                label: minRating == 0.0 ? 'Any' : minRating.toStringAsFixed(1),
                onChanged: onRatingChanged,
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                minRating == 0.0 ? 'Any' : '${minRating.toStringAsFixed(1)}+',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}