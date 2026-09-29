import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Source of "now" for every mode. Tests replace it to freeze time.
DateTime Function() nowProvider = DateTime.now;

/// Rebuilds with the current time.
///
/// * [smooth]: every frame (for a sweeping second hand).
/// * otherwise: once per second, aligned to the second boundary so the
///   display flips exactly when the real second does.
class TimeBuilder extends StatefulWidget {
  const TimeBuilder({super.key, this.smooth = false, required this.builder});

  final bool smooth;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<TimeBuilder> createState() => _TimeBuilderState();
}

class _TimeBuilderState extends State<TimeBuilder>
    with SingleTickerProviderStateMixin {
  late DateTime _now = nowProvider();
  Ticker? _ticker;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TimeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.smooth != widget.smooth) {
      _stop();
      _start();
    }
  }

  void _start() {
    if (widget.smooth) {
      _ticker = createTicker((_) => setState(() => _now = nowProvider()))
        ..start();
    } else {
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    final now = nowProvider();
    final untilNextSecond = 1000 - now.millisecond;
    _timer = Timer(Duration(milliseconds: untilNextSecond + 5), () {
      if (!mounted) return;
      setState(() => _now = nowProvider());
      _scheduleNext();
    });
  }

  void _stop() {
    _ticker?.dispose();
    _ticker = null;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
