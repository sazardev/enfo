import 'dart:async';

import 'package:flutter/material.dart';

import '../design/motion.dart';

/// One-shot entrance: the child pops in from nothing with a springy
/// overshoot and a slight twist, after an optional [delay]. Stagger a row of
/// these by giving each a larger delay. Skipped when animations are off.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 560),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _spring =
      CurvedAnimation(parent: _controller, curve: Motion.bouncy);
  late final CurvedAnimation _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4));
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spring.dispose();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: (1 - _spring.value) * -0.35,
          child: Transform.scale(scale: _spring.value, child: child),
        ),
      ),
    );
  }
}
