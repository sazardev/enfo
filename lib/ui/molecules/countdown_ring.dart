import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Stateless, purely presentational countdown ring. No timers, no gestures —
/// [progress] (0..1, already computed by the caller) and [label] are the
/// only inputs that change over time. Flat: a filled circular surface, a
/// muted full-circle track, and a rounded progress arc — no shadow, no
/// gradient.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.label,
    required this.labelStyle,
    required this.ringColor,
    required this.trackColor,
    required this.surfaceColor,
  });

  final double progress;
  final String label;
  final TextStyle labelStyle;
  final Color ringColor;
  final Color trackColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    // Defensively clip to a circle: guarantees nothing square/rectangular
    // (from this painter or any ancestor) can ever show outside the ring,
    // regardless of the box it's laid out in.
    return ClipOval(
      child: CustomPaint(
        painter: _CountdownRingPainter(
          progress: progress,
          label: label,
          labelStyle: labelStyle,
          ringColor: ringColor,
          trackColor: trackColor,
          surfaceColor: surfaceColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.label,
    required this.labelStyle,
    required this.ringColor,
    required this.trackColor,
    required this.surfaceColor,
  });

  final double progress;
  final String label;
  final TextStyle labelStyle;
  final Color ringColor;
  final Color trackColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.shortestSide / 2;
    final strokeWidth = outerRadius * 2 * 0.16;
    final ringRadius = outerRadius - strokeWidth / 2;

    canvas.drawCircle(center, outerRadius, Paint()..color = surfaceColor);

    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor,
    );

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2,
        2 * math.pi * clamped,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = ringColor,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - strokeWidth * 2.5);
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.label != label ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.labelStyle != labelStyle;
}
