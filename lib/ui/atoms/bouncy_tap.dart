import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';

/// Flat press-feedback wrapper: scales [child] down on press and springs it
/// back on release. No ink ripple — interactive feedback is entirely
/// motion-based, matching the app's flat, shadow-free design system.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.92,
    this.duration = Motion.fast,
    this.releaseCurve = Motion.bouncy,
    this.enableFeedback = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final Curve releaseCurve;
  final bool enableFeedback;
  final HitTestBehavior behavior;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: widget.releaseCurve,
  );
  late final Animation<double> _scale =
      _curved.drive(Tween<double>(begin: 1.0, end: widget.pressedScale));

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _press() {
    if (!_enabled) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
    if (widget.enableFeedback) HapticFeedback.selectionClick();
  }

  void _release() {
    if (!_enabled) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.0;
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
