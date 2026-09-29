import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../atoms/bouncy_tap.dart';
import '../clock/clock_frame.dart';
import '../clock/clock_style.dart';
import '../clock/clock_style_l10n.dart';
import '../clock/clock_view.dart';
import '../design/motion.dart';
import '../design/spacing.dart';

/// Looping demo frame shared by every preview so they animate in lockstep.
ClockFrame demoFrame({
  required double seconds,
  required bool still,
  required ClockLabels labels,
  bool rest = false,
}) {
  const loop = 14.0;
  return ClockFrame(
    progress: still ? 0.35 : (seconds % loop) / loop,
    totalSeconds: 25 * 60,
    isRest: rest,
    time: still ? 0 : seconds,
    labels: labels,
  );
}

/// Selectable tile with a live, looping preview of a [ClockStyle].
///
/// Flat and expressive: no border or shadow. Selection morphs the tile's
/// shape (rounded rect → softer, rounder), pops the preview with a spring
/// and swaps in a check.
class ClockStyleTile extends StatelessWidget {
  const ClockStyleTile({
    super.key,
    required this.style,
    required this.selected,
    required this.onTap,
    required this.clock,
  });

  final ClockStyle style;
  final bool selected;
  final VoidCallback onTap;

  /// Seconds since the page opened; drives every preview in lockstep.
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = ClockPalette.of(cs, rest: false, paused: false);
    final still = MediaQuery.disableAnimationsOf(context);
    final labels = ClockLabels.of(context.l10n);

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.snappy,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(selected ? 48 : 28),
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
                    style: style,
                    fill: 0.92,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    style.labelOf(context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.onSecondaryContainer : cs.onSurface,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: Motion.medium,
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: cs.onSecondaryContainer,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
