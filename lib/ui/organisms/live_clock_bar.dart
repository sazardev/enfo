import 'package:flutter/material.dart';

import '../../live_clock.dart';

/// Small, muted "current time" readout shown above the countdown dial
/// (home) and above the app title (onboarding) — consistent styling.
class LiveClockBar extends StatelessWidget {
  const LiveClockBar({super.key, this.fontSize = 14});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LiveClock(
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
