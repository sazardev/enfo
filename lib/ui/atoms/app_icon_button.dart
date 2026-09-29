import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/responsive.dart';
import 'bouncy_tap.dart';
import 'chubby_icon.dart';

/// Lets a toolbar dictate the diameter of every [AppIconButton] below it
/// (buttons with an explicit `size` keep theirs).
class AppIconButtonScope extends InheritedWidget {
  const AppIconButtonScope({
    super.key,
    required this.size,
    this.axis = Axis.horizontal,
    required super.child,
  });

  final double size;

  /// Direction of the toolbar, for grouped buttons that lay themselves out.
  final Axis axis;

  static double? sizeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppIconButtonScope>()?.size;

  static Axis axisOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppIconButtonScope>()?.axis ??
      Axis.horizontal;

  @override
  bool updateShouldNotify(AppIconButtonScope old) =>
      size != old.size || axis != old.axis;
}

/// Flat, round icon button with bouncy press feedback. Replaces raw
/// [IconButton] usage app-wide — no ripple, no elevation. [selected] fills
/// the circle with the primary color (e.g. an active toggle).
///
/// Plain [Icon]s passed as [icon] are drawn plump (see [ChubbyIcon]). On tap,
/// and whenever [selected] flips, the icon squashes, springs past its size
/// and settles with a small wobble.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.selected = false,
    this.size,
    this.autofocus = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;

  /// Diameter. Defaults to the screen-aware size: compact on a watch, and
  /// growing with the screen scale on tablets and TVs.
  final double? size;

  /// See [BouncyTap.autofocus].
  final bool autofocus;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  late final Animation<double> _scale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 0.72)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 18,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.72, end: 1.0)
          .chain(CurveTween(curve: Motion.bouncy)),
      weight: 82,
    ),
  ]).animate(_pop);

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _pop.forward(from: 0);
  }

  void _handleTap() {
    _play();
    widget.onPressed?.call();
  }

  @override
  void didUpdateWidget(covariant AppIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _play();
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  /// Bare [Icon]s become plump ones; anything else is left alone.
  Widget _plump(Widget icon) {
    if (icon is Icon && icon.icon != null) {
      return ChubbyIcon(icon.icon!, size: icon.size, color: icon.color);
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = Responsive.of(context);
    final size = widget.size ??
        AppIconButtonScope.sizeOf(context) ??
        (r.isWatch ? 34.0 : 44.0 * r.scale);
    final selected = widget.selected;

    final button = BouncyTap(
      onTap: widget.onPressed == null ? null : _handleTap,
      focusBorderRadius: BorderRadius.circular(size),
      pressedScale: 0.9,
      autofocus: widget.autofocus,
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
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) => Transform.rotate(
            angle: math.sin(_pop.value * math.pi * 3) * 0.16 * (1 - _pop.value),
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: size * 0.54,
            ),
            child: _plump(widget.icon),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
