import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../atoms/chubby_icon.dart';
import '../design/motion.dart';

/// The mode's main control in the button bar: a play icon that becomes a
/// filled pause while running. [label] feeds the tooltip and semantics.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.running,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final bool running;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppIconButton(
      tooltip: label,
      selected: running,
      // Where a remote / keyboard starts: OK or Enter presses play.
      autofocus: true,
      onPressed: enabled ? onPressed : null,
      icon: AnimatedSwitcher(
        duration: Motion.medium,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: 0.25, end: 0).animate(animation),
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: ChubbyIcon(
          running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: ValueKey(running),
          // Selected fills the circle; the icon then takes the theme's
          // on-primary color, otherwise it wears the accent.
          color: running
              ? null
              : (enabled
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.38)),
        ),
      ),
    );
  }
}
