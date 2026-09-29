import 'package:flutter/material.dart';
import '../../haptics/haptics.dart';

import '../design/motion.dart';
import '../design/radii.dart';

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
    this.longPressFeedback = true,
    this.behavior = HitTestBehavior.opaque,
    this.focusBorderRadius = AppRadii.mdRadius,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final Curve releaseCurve;
  final bool enableFeedback;

  /// Whether a long press adds its own confirm beat. Off for callers whose
  /// action already has a haptic of its own.
  final bool longPressFeedback;
  final HitTestBehavior behavior;

  /// Shape of the keyboard / D-pad focus halo. Match the child's shape.
  final BorderRadius focusBorderRadius;

  /// Takes focus when first shown, so a remote or keyboard has a starting
  /// point. (The halo only appears while navigating with keys / D-pad.)
  final bool autofocus;

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

  bool _focused = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _press() {
    if (!_enabled) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
    // Lands with the press-down scale, so touch and motion agree.
    if (widget.enableFeedback) Haptics.tap();
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
    // Focusable so a TV remote (D-pad), a car rotary/keys or a keyboard can
    // reach and activate every control. The focus cue stays flat: a soft
    // tinted halo behind the child, no border or shadow.
    return FocusableActionDetector(
      enabled: widget.onTap != null,
      autofocus: widget.autofocus,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                if (widget.longPressFeedback) Haptics.confirm();
                widget.onLongPress!();
              },
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value * (_focused ? 1.05 : 1.0),
            child: child,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (_focused)
                Positioned.fill(
                  left: -6,
                  top: -6,
                  right: -6,
                  bottom: -6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.22),
                      borderRadius: widget.focusBorderRadius,
                    ),
                  ),
                ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}
