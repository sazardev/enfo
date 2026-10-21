import 'package:flutter/material.dart';

import '../../haptics/haptics.dart';
import '../../tv/tv_focus_hint.dart';
import '../../tv/tv_mode.dart';
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
    this.focusNode,
    this.focusLabel,
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

  /// Optional node, for callers that need to request focus themselves.
  final FocusNode? focusNode;

  /// Name shown in the TV hint bar while this control is focused. Usually
  /// the same text as its tooltip.
  final String? focusLabel;

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

  /// The FocusableActionDetector's autofocus can be lost when the button is
  /// built in a later frame (loading, a mode switch, a wizard step). Keep our
  /// own node and ask for focus once after the first frame.
  late final FocusNode _node =
      widget.focusNode ?? FocusNode(debugLabel: 'BouncyTap');
  late final bool _ownsNode = widget.focusNode == null;

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _node.canRequestFocus) _node.requestFocus();
      });
    }
  }

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

  void _handleFocus(bool focused) {
    // On TV always paint the ring when the control has focus, even when the
    // focus was moved programmatically (a mouse tap would otherwise leave
    // the focus highlight mode in `touch` and hide it).
    if (TvMode.isTv && _focused != focused) {
      setState(() => _focused = focused);
    }
    if (focused) {
      final label = widget.focusLabel;
      if (label != null && TvMode.isTv) TvFocusHint.show(label);
      // Focus traversal in a lazy list can land on a tile that is only just
      // built (or just outside the viewport). Keep it visible.
      if (TvMode.isTv) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (Scrollable.maybeOf(context) == null) return;
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
          );
        });
      }
    } else {
      final label = widget.focusLabel;
      if (label != null) TvFocusHint.clear(label);
    }
  }

  @override
  void didUpdateWidget(covariant BouncyTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A play button is often built disabled while preferences load, then
    // becomes tappable. Autofocus has already passed by then; retry it.
    if (widget.autofocus && oldWidget.onTap == null && widget.onTap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _node.canRequestFocus) _node.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    final label = widget.focusLabel;
    if (label != null) TvFocusHint.clear(label);
    if (_ownsNode) _node.dispose();
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Focusable so a TV remote (D-pad), a car rotary/keys or a keyboard can
    // reach and activate every control. The focus cue stays flat: a soft
    // tinted halo behind the child, no border or shadow.
    final scheme = Theme.of(context).colorScheme;
    return FocusableActionDetector(
      enabled: widget.onTap != null,
      autofocus: widget.autofocus,
      focusNode: _node,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onFocusChange: _handleFocus,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: _enabled,
        label: widget.focusLabel,
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
              scale:
                  _scale.value * (_focused ? (TvMode.isTv ? 1.06 : 1.05) : 1.0),
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
                        color: scheme.primary.withValues(
                          alpha: TvMode.isTv ? 0.30 : 0.22,
                        ),
                        borderRadius: widget.focusBorderRadius,
                        // On a TV the halo alone is too subtle from across
                        // the room; add a high-contrast ring (still flat).
                        border: TvMode.isTv
                            ? Border.all(
                                color: scheme.onSurface.withValues(alpha: 0.90),
                                width: 2.5,
                              )
                            : null,
                      ),
                    ),
                  ),
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
