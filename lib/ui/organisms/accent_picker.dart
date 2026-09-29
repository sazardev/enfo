import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../atoms/accent_swatch.dart';
import '../atoms/bouncy_tap.dart';
import '../design/motion.dart';
import '../design/spacing.dart';
import '../molecules/color_picker_panel.dart';

/// Accent-color choices: palette swatches, plus (optionally) a custom color
/// with an inline HSV/hex picker. Controlled by the caller through [color]
/// and [onChanged]; used by the accent page and by the onboarding.
class AccentPicker extends StatefulWidget {
  const AccentPicker({
    super.key,
    required this.colors,
    required this.color,
    required this.onChanged,
    this.swatchSize = 52,
    this.allowCustom = true,
  });

  final List<Color> colors;
  final Color color;
  final ValueChanged<Color> onChanged;
  final double swatchSize;

  /// Typing hex / dragging sliders isn't a watch interaction.
  final bool allowCustom;

  @override
  State<AccentPicker> createState() => _AccentPickerState();
}

class _AccentPickerState extends State<AccentPicker> {
  /// The user's custom color, if the accent isn't a palette color (or the
  /// custom picker was opened this visit).
  late Color? _custom = _inPalette(widget.color) ? null : widget.color;
  late bool _customOpen = _custom != null;

  /// Last color this widget reported, to tell its own updates apart from
  /// the caller changing the color from outside (e.g. applying a combo).
  late int _emitted = widget.color.toARGB32();

  bool _inPalette(Color color) =>
      widget.colors.any((c) => c.toARGB32() == color.toARGB32());

  @override
  void didUpdateWidget(covariant AccentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.color.toARGB32();
    if (incoming == _emitted) return;
    _emitted = incoming;
    if (_inPalette(widget.color)) {
      _customOpen = false;
    } else {
      _custom = widget.color;
      _customOpen = true;
    }
  }

  void _emit(Color color) {
    _emitted = color.toARGB32();
    widget.onChanged(color);
  }

  void _pickPalette(Color color) {
    setState(() => _customOpen = false);
    _emit(color);
  }

  void _openCustom() {
    setState(() {
      _custom ??= widget.color;
      _customOpen = true;
    });
    _emit(_custom!);
  }

  void _changeCustom(Color color) {
    setState(() => _custom = color);
    _emit(color);
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.swatchSize < 48 ? AppSpacing.sm : AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in widget.colors)
              AccentSwatch(
                color: c,
                size: widget.swatchSize,
                selected:
                    !_customOpen && c.toARGB32() == widget.color.toARGB32(),
                onTap: () => _pickPalette(c),
              ),
            if (widget.allowCustom)
              _CustomSwatch(
                size: widget.swatchSize,
                color: _custom,
                selected: _customOpen,
                onTap: _openCustom,
              ),
          ],
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Curves.easeOutCubic,
          child: _customOpen && widget.allowCustom
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: ColorPickerPanel(
                    color: _custom!,
                    onChanged: _changeCustom,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// "Custom" swatch: a neutral disc with a picker icon until there is a
/// custom color; flat like the palette swatches (selection morphs the
/// circle into a squircle).
class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({
    required this.size,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double size;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final custom = color;
    final background = custom ?? colorScheme.surfaceContainerHighest;
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return BouncyTap(
      onTap: onTap,
      focusBorderRadius: BorderRadius.circular(size),
      pressedScale: 0.88,
      child: Semantics(
        button: true,
        label: context.l10n.accentCustom,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            borderRadius:
                BorderRadius.circular(selected ? size * 0.32 : size / 2),
          ),
          child: Icon(
            selected ? Icons.check_rounded : Icons.colorize_rounded,
            color: custom == null ? colorScheme.onSurfaceVariant : foreground,
          ),
        ),
      ),
    );
  }
}
