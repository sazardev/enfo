import 'package:flutter/material.dart';

import 'bouncy_tap.dart';

/// A single selectable accent-color circle, used by the accent-color page.
/// Fixed-size by design — it must never stretch to fill whatever grid/wrap
/// cell it's laid out in, or it renders as an oversized color blob.
class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 52,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      focusBorderRadius: BorderRadius.circular(size),
      pressedScale: 0.88,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          // Flat selection cue: the circle morphs into a squircle (+ check).
          borderRadius:
              BorderRadius.circular(selected ? size * 0.32 : size / 2),
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: _foregroundFor(color))
            : null,
      ),
    );
  }

  Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
