import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';

/// The Enfo logo: a lowercase "e" drawn as the timer ring, whose crossbar is
/// the clock hand, with a pivot dot at the centre. Geometry mirrors
/// tools/make_logo.py (ring radius 140, stroke 52, in a 332-unit box).
///
/// [progress] (0..1) plays the build: the dial sketches itself, the pivot
/// pops in, then the hand shoots out to meet the ring. At 1 it is the final
/// logo. Colours follow the accent, so the mark matches the chosen theme.
class EnfoMark extends StatelessWidget {
  const EnfoMark({
    super.key,
    required this.progress,
    this.size = 160,
    this.color,
    this.tint,
  });

  final Animation<double> progress;
  final double size;

  /// The ring; defaults to the theme's primary.
  final Color? color;

  /// The hand and pivot; defaults to a lighter tone of [color].
  final Color? tint;

  static const _ring = Interval(0.0, 0.55, curve: Curves.easeInOutCubic);
  static const _track = Interval(0.0, 0.2, curve: Curves.easeOut);
  static const _trackOut = Interval(0.45, 0.6);
  static const _pivot = Interval(0.42, 0.7, curve: Motion.bouncy);
  static const _hand = Interval(0.62, 0.92, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    final light = tint ?? Color.lerp(base, Colors.white, 0.55)!;
    return Semantics(
      image: true,
      label: 'Enfo',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final t = progress.value;
              return CustomPaint(
                size: Size.square(size),
                painter: _MarkPainter(
                  ring: _ring.transform(t),
                  track: _track.transform(t) * (1 - _trackOut.transform(t)),
                  pivot: _pivot.transform(t),
                  hand: _hand.transform(t),
                  color: base,
                  tint: light,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.ring,
    required this.track,
    required this.pivot,
    required this.hand,
    required this.color,
    required this.tint,
  });

  final double ring, track, pivot, hand;
  final Color color, tint;

  static const _radius = 140.0;
  static const _stroke = 52.0;
  static const _box = 332.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final k = size.shortestSide / _box;
    canvas.scale(k);

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    // The full dial, faintly, until the "e" takes its place.
    if (track > 0) {
      canvas.drawCircle(
        Offset.zero,
        _radius,
        stroke(color.withValues(alpha: 0.14 * track)),
      );
    }

    // The ring opens at the lower right: 140 deg clockwise from 12 o'clock
    // (50 deg in canvas terms) round to the 3 o'clock end of the hand.
    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: _radius),
        50 * math.pi / 180,
        310 * math.pi / 180 * ring,
        false,
        stroke(color),
      );
    }

    if (hand > 0) {
      canvas.drawLine(
        Offset.zero,
        Offset(_radius * hand, 0),
        stroke(tint),
      );
    }

    if (pivot > 0) {
      canvas.drawCircle(
        Offset.zero,
        44 * pivot,
        Paint()..color = tint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      ring != old.ring ||
      track != old.track ||
      pivot != old.pivot ||
      hand != old.hand ||
      color != old.color ||
      tint != old.tint;
}
