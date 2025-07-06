import 'package:flutter/material.dart';

class DistanceFilter extends StatelessWidget {
  final double maxDistance;
  final Function(double) onDistanceChanged;

  const DistanceFilter({
    super.key,
    required this.maxDistance,
    required this.onDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Distance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: maxDistance,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: maxDistance >= 50.0 ? 'Any' : '${maxDistance.toInt()} km',
                onChanged: onDistanceChanged,
              ),
            ),
            Container(
              width: 80,
              alignment: Alignment.center,
              child: Text(
                maxDistance >= 50.0 ? 'Any distance' : '${maxDistance.toInt()} km',
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