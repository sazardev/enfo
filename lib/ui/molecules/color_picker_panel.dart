import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/locale_controller.dart';
import '../design/radii.dart';
import '../design/spacing.dart';

/// Inline custom-color picker (no dialog): hue / saturation / brightness
/// sliders over gradient tracks, plus a hex field. Reports every change.
class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  // HSV is the source of truth: round-tripping through RGB would lose hue
  // whenever saturation or brightness hits 0.
  late HSVColor _hsv = HSVColor.fromColor(widget.color);
  late final TextEditingController _hex =
      TextEditingController(text: _hexOf(widget.color));

  static String _hexOf(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  void _setHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    _hex.text = _hexOf(hsv.toColor());
    widget.onChanged(hsv.toColor());
  }

  void _onHexChanged(String value) {
    if (value.length != 6) return;
    final rgb = int.tryParse(value, radix: 16);
    if (rgb == null) return;
    final color = Color(0xFF000000 | rgb);
    setState(() => _hsv = HSVColor.fromColor(color));
    widget.onChanged(color);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final h = _hsv.hue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GradientSlider(
          label: l10n.accentHue,
          value: h,
          max: 360,
          thumbColor: HSVColor.fromAHSV(1, h, 1, 1).toColor(),
          colors: [
            for (var i = 0; i <= 6; i++)
              HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
          ],
          onChanged: (v) => _setHsv(_hsv.withHue(v)),
        ),
        _GradientSlider(
          label: l10n.accentSaturation,
          value: _hsv.saturation,
          max: 1,
          thumbColor: _hsv.toColor(),
          colors: [
            HSVColor.fromAHSV(1, h, 0, _hsv.value).toColor(),
            HSVColor.fromAHSV(1, h, 1, _hsv.value).toColor(),
          ],
          onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
        ),
        _GradientSlider(
          label: l10n.accentBrightness,
          value: _hsv.value,
          max: 1,
          thumbColor: _hsv.toColor(),
          colors: [
            Colors.black,
            HSVColor.fromAHSV(1, h, _hsv.saturation, 1).toColor(),
          ],
          onChanged: (v) => _setHsv(_hsv.withValue(v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _hex,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.accentHex,
            prefixText: '#',
            counterText: '',
            border: const OutlineInputBorder(borderRadius: AppRadii.smRadius),
          ),
          onChanged: _onHexChanged,
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
    required this.thumbColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(label, style: textTheme.labelLarge),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            // The slider's own track is transparent; this bar is the track.
            Container(
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(colors: colors),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 12,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: thumbColor,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 12,
                  elevation: 0,
                  pressedElevation: 0,
                ),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: value.clamp(0, max),
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
