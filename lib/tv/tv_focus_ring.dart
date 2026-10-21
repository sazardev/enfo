import 'package:flutter/material.dart';

import 'tv_mode.dart';

/// A high-contrast focus ring for Material controls (buttons, switches) that
/// do not use [BouncyTap].
///
/// The ring is drawn outside the child, so showing it does not move anything.
/// It only exists on TV; phones keep their normal Material focus styling.
class TvFocusRing extends StatelessWidget {
  const TvFocusRing({
    super.key,
    required this.node,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  final FocusNode node;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!TvMode.isTv) return child;
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) {
        if (!node.hasFocus) return child;
        final scheme = Theme.of(context).colorScheme;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -5,
              top: -5,
              right: -5,
              bottom: -5,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.92),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
