import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../molecules/window_control_button.dart';

/// Flat, custom Windows title bar: draggable area, app title, and
/// minimize/maximize/close controls. Replaces the old `CustomAppBar`.
class WindowTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const WindowTitleBar({
    super.key,
    required this.title,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
  });

  final String title;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: preferredSize.height,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            WindowControlButton(
              icon: Icons.remove_rounded,
              onPressed: onMinimize,
            ),
            WindowControlButton(
              icon: Icons.crop_square_rounded,
              onPressed: onMaximize,
            ),
            WindowControlButton(
              icon: Icons.close_rounded,
              onPressed: onClose,
              dangerous: true,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
