import 'package:flutter/material.dart';

import '../atoms/bouncy_tap.dart';

/// Flat, round window-chrome button (minimize/maximize/close) for the
/// custom Windows title bar. Highlights on hover; [dangerous] tints the
/// hover state with the error color (used for the close button).
class WindowControlButton extends StatefulWidget {
  const WindowControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.dangerous = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool dangerous;

  @override
  State<WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<WindowControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hoverBackground = widget.dangerous
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final hoverForeground =
        widget.dangerous ? colorScheme.onErrorContainer : colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: BouncyTap(
        onTap: widget.onPressed,
        pressedScale: 0.88,
        enableFeedback: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? hoverBackground : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: _hovered ? hoverForeground : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
