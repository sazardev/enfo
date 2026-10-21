import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../ui/atoms/app_icon_button.dart';

/// Up/down buttons for lists that can only be reordered by dragging on a
/// touchscreen. A TV remote has no drag gesture, so TV users get two
/// focusable buttons instead (the drag handle stays on phones/tablets).
class TvReorderButtons extends StatelessWidget {
  const TvReorderButtons({
    super.key,
    required this.onMoveUp,
    required this.onMoveDown,
    this.canMoveUp = true,
    this.canMoveDown = true,
    this.size = 32,
  });

  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          size: size,
          tooltip: l10n.tvMoveUp,
          onPressed: canMoveUp ? onMoveUp : null,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
        AppIconButton(
          size: size,
          tooltip: l10n.tvMoveDown,
          onPressed: canMoveDown ? onMoveDown : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ],
    );
  }
}
