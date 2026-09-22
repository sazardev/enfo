import 'package:flutter/material.dart';

/// A labeled minutes slider used by the custom (manual) preset sliders.
class MinutesSlider extends StatelessWidget {
  const MinutesSlider({
    super.key,
    required this.label,
    required this.color,
    required this.minutes,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final int minutes;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$minutes min',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: minutes.toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }
}
