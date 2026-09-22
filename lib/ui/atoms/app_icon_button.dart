import 'package:flutter/material.dart';

import 'bouncy_tap.dart';

/// Flat, round icon button with bouncy press feedback. Replaces raw
/// [IconButton] usage app-wide — no ripple, no elevation. [selected] fills
/// the circle with the primary color (e.g. an active toggle).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.selected = false,
    this.size = 44,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = BouncyTap(
      onTap: onPressed,
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color:
                selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            size: size * 0.5,
          ),
          child: icon,
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
