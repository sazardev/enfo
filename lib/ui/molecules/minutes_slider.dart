import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../atoms/app_icon_button.dart';
import '../design/spacing.dart';

/// A labeled minutes control: coarse slider plus −/+ buttons for exact
/// one-minute adjustments. Used by the custom (manual) preset.
class MinutesSlider extends StatelessWidget {
  const MinutesSlider({
    super.key,
    required this.label,
    required this.color,
    required this.minutes,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final int minutes;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AppIconButton(
              size: 36,
              tooltip: '-1',
              onPressed: minutes > min ? () => onChanged(minutes - 1) : null,
              icon: const Icon(Icons.remove_rounded, size: 20),
            ),
            SizedBox(
              width: 76,
              child: Text(
                context.l10n.minutes(minutes),
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            AppIconButton(
              size: 36,
              tooltip: '+1',
              onPressed: minutes < max ? () => onChanged(minutes + 1) : null,
              icon: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: minutes.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }
}
