import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../atoms/bouncy_tap.dart';
import '../clock/clock_combo.dart';
import '../clock/clock_frame.dart';
import '../clock/clock_view.dart';
import '../design/motion.dart';
import '../design/spacing.dart';
import 'clock_style_tile.dart';

/// Preset card: previews a style already dressed in its own accent color
/// (a full tonal scheme seeded from it), so the whole look is visible
/// before applying it.
class ClockComboCard extends StatelessWidget {
  const ClockComboCard({
    super.key,
    required this.combo,
    required this.selected,
    required this.onTap,
    required this.clock,
    this.width = 148,
  });

  final ClockCombo combo;
  final bool selected;
  final VoidCallback onTap;
  final Animation<double> clock;
  final double width;

  /// `ColorScheme.fromSeed` runs a heavy color-science pass; combos reuse
  /// the same handful of seeds on every rebuild, so memoize it.
  static final Map<(int, Brightness), ColorScheme> _schemes = {};

  static ColorScheme _scheme(Color seed, Brightness brightness) =>
      _schemes.putIfAbsent(
        (seed.toARGB32(), brightness),
        () => ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = _scheme(combo.color, brightness);
    final palette = ClockPalette.of(scheme, rest: false, paused: false);
    final still = MediaQuery.disableAnimationsOf(context);
    final labels = ClockLabels.of(context.l10n);

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.snappy,
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(selected ? 56 : 32),
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedScale(
                scale: selected ? 1.06 : 1.0,
                duration: Motion.slow,
                curve: Motion.bouncy,
                child: AnimatedBuilder(
                  animation: clock,
                  builder: (context, _) => ClockView(
                    style: combo.style,
                    fill: 0.9,
                    palette: palette,
                    frame: demoFrame(
                      seconds: clock.value,
                      still: still,
                      labels: labels,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              combo.labelOf(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
