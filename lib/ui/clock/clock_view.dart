import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/locale_controller.dart';
import '../design/motion.dart';
import 'clock_frame.dart';
import 'clock_style.dart';

/// Pure renderer: sizes the face to its preferred aspect ratio inside the
/// available space and draws it. Used by both the live dial and previews.
class ClockView extends StatelessWidget {
  const ClockView({
    super.key,
    required this.style,
    required this.frame,
    required this.palette,
    this.fill = 1.0,
  });

  final ClockStyle style;
  final ClockFrame frame;
  final ClockPalette palette;

  /// Fraction of the available box the face occupies.
  final double fill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight;
      final a = style.aspectRatio;
      final double w;
      final double h;
      if (maxW / maxH > a) {
        h = maxH;
        w = h * a;
      } else {
        w = maxW;
        h = w / a;
      }
      return Center(
        child: SizedBox(
          width: w * fill,
          height: h * fill,
          child: style.face(frame, palette),
        ),
      );
    });
  }
}

/// The live timer visual. Rebuilds with [progress] and, for animated
/// styles, runs a ticker only while the countdown is running so idle and
/// paused states cost nothing (and waves/rotation freeze on pause).
class LiveClockView extends StatefulWidget {
  const LiveClockView({
    super.key,
    required this.style,
    required this.progress,
    required this.totalSeconds,
    required this.isRest,
    required this.phase,
    required this.wordMode,
  });

  final ClockStyle style;
  final Animation<double> progress;
  final int totalSeconds;
  final bool isRest;
  final ClockPhase phase;
  final bool wordMode;

  @override
  State<LiveClockView> createState() => _LiveClockViewState();
}

class _LiveClockViewState extends State<LiveClockView>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);
  double _base = 0;

  void _onTick(Duration elapsed) {
    _time.value =
        _base + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void _syncTicker() {
    final shouldRun = widget.phase == ClockPhase.running &&
        widget.style.animated &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
      _base = _time.value;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant LiveClockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ClockLabels.of(context.l10n);
    final palette = ClockPalette.of(
      Theme.of(context).colorScheme,
      rest: widget.isRest,
      paused: widget.phase == ClockPhase.paused,
    );

    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.medium,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(widget.style),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.progress, _time]),
          builder: (context, _) => ClockView(
            style: widget.style,
            fill: 0.9,
            palette: palette,
            frame: ClockFrame(
              progress: widget.progress.value,
              totalSeconds: widget.totalSeconds,
              isRest: widget.isRest,
              phase: widget.phase,
              wordMode: widget.wordMode,
              time: _time.value,
              labels: labels,
            ),
          ),
        ),
      ),
    );
  }
}
