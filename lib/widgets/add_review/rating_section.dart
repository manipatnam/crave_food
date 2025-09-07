// lib/widgets/add_review/rating_section.dart

import 'package:flutter/material.dart';

class RatingSection extends StatelessWidget {
  final double foodRating;
  final double serviceRating;
  final double ambienceRating;
  final double valueRating;
  final double overallRating;
  final bool autoCalculateOverall;
  final Function(double) onFoodRatingChanged;
  final Function(double) onServiceRatingChanged;
  final Function(double) onAmbienceRatingChanged;
  final Function(double) onValueRatingChanged;
  final Function(double) onOverallRatingChanged;
  final Function(bool) onAutoCalculateToggled;

  const RatingSection({
    super.key,
    required this.foodRating,
    required this.serviceRating,
    required this.ambienceRating,
    required this.valueRating,
    required this.overallRating,
    required this.autoCalculateOverall,
    required this.onFoodRatingChanged,
    required this.onServiceRatingChanged,
    required this.onAmbienceRatingChanged,
    required this.onValueRatingChanged,
    required this.onOverallRatingChanged,
    required this.onAutoCalculateToggled,
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
              Icons.star_rate,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Rate Your Experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Individual Rating Categories
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // Food Rating
              _buildRatingRow(
                'Food Quality',
                Icons.restaurant_menu,
                Colors.orange,
                foodRating,
                onFoodRatingChanged,
                'How was the taste, freshness, and presentation?',
              ),
              
              const SizedBox(height: 20),
              
              // Service Rating
              _buildRatingRow(
                'Service',
                Icons.room_service,
                Colors.blue,
                serviceRating,
                onServiceRatingChanged,
                'How was the staff behavior and speed?',
              ),
              
              const SizedBox(height: 20),
              
              // Ambience Rating
              _buildRatingRow(
                'Ambience',
                Icons.music_note,
                Colors.purple,
                ambienceRating,
                onAmbienceRatingChanged,
                'How was the atmosphere and environment?',
              ),
              
              const SizedBox(height: 20),
              
              // Value for Money Rating
              _buildRatingRow(
                'Value for Money',
                Icons.attach_money,
                Colors.green,
                valueRating,
                onValueRatingChanged,
                'Was it worth the price you paid?',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Overall Rating Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: autoCalculateOverall ? Colors.amber[50] : Colors.blue[50],
            border: Border.all(
              color: autoCalculateOverall ? Colors.amber[200]! : Colors.blue[200]!,
            ),
          ),
          child: Column(
            children: [
              // Overall Rating Header
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: autoCalculateOverall ? Colors.amber : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overall Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    overallRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: autoCalculateOverall ? Colors.amber[700] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Auto Calculate Toggle
              Row(
                children: [
                  Switch(
                    value: autoCalculateOverall,
                    onChanged: onAutoCalculateToggled,
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      autoCalculateOverall 
                          ? 'Auto-calculated from above ratings'
                          : 'Set custom overall rating',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Manual Overall Rating (if not auto-calculated)
              if (!autoCalculateOverall) ...[
                const SizedBox(height: 12),
                _buildRatingSlider(
                  overallRating,
                  onOverallRatingChanged,
                  Colors.blue,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(
    String title,
    IconData icon,
    Color color,
    double rating,
    Function(double) onChanged,
    String helpText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Help Text
        Text(
          helpText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Rating Slider and Stars
        Row(
          children: [
            // Star Display
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            
            const SizedBox(width: 12),
            
            // Slider
            Expanded(
              child: _buildRatingSlider(rating, onChanged, color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSlider(double rating, Function(double) onChanged, Color color) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        activeTrackColor: color,
        inactiveTrackColor: color.withOpacity(0.3),
        thumbColor: color,
        overlayColor: color.withOpacity(0.2),
        valueIndicatorColor: color,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        showValueIndicator: ShowValueIndicator.always,
      ),
      child: Slider(
        value: rating,
        min: 1.0,
        max: 5.0,
        divisions: 8, // Allows half-star ratings (1.0, 1.5, 2.0, etc.)
        onChanged: onChanged,
        label: rating.toStringAsFixed(1),
      ),
    );
  }
}