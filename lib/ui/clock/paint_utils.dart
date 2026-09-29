import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Themed, single-line label for faces. Real [Text] (not a TextPainter) so
/// the app font carries through.
class FaceText extends StatelessWidget {
  const FaceText(
    this.text, {
    super.key,
    required this.size,
    required this.color,
    this.weight = FontWeight.w700,
  });

  final String text;
  final double size;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      // Sized relative to the face; app-wide text scaling would grow it twice.
      textScaler: TextScaler.noScaling,
      style: base.copyWith(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.0,
      ),
    );
  }
}

/// [FaceText] that shrinks to fit its parent's width.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.size,
    required this.color,
    this.weight = FontWeight.w700,
  });

  final String text;
  final double size;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: FaceText(text, size: size, color: color, weight: weight),
    );
  }
}

/// Sampled arc whose radius oscillates: the Material 3 Expressive "wavy"
/// circular progress. [waves] must be an integer so full circles close.
Path wavyArcPath({
  required Offset center,
  required double radius,
  required double amplitude,
  required int waves,
  required double phase,
  required double startAngle,
  required double sweep,
}) {
  final steps = math.max(8, (sweep.abs() * radius / 3).ceil().clamp(8, 900));
  final path = Path();
  for (var i = 0; i <= steps; i++) {
    final a = startAngle + sweep * i / steps;
    final r = radius + amplitude * math.sin(waves * a + phase);
    final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  return path;
}

/// Horizontal wavy line from [x0] to [x1] centered on [y].
Path wavyLinePath({
  required double x0,
  required double x1,
  required double y,
  required double amplitude,
  required double wavelength,
  required double phase,
}) {
  final path = Path();
  final steps = math.max(2, ((x1 - x0) / 2).ceil());
  for (var i = 0; i <= steps; i++) {
    final x = x0 + (x1 - x0) * i / steps;
    final yy = y + amplitude * math.sin(2 * math.pi * x / wavelength + phase);
    if (i == 0) {
      path.moveTo(x, yy);
    } else {
      path.lineTo(x, yy);
    }
  }
  return path;
}

/// Scalloped "cookie" blob (Material 3 Expressive shape), max radius
/// [radius], [lobes] bumps, [depth] = scallop depth as a fraction of radius.
Path cookiePath({
  required Offset center,
  required double radius,
  required int lobes,
  required double depth,
  required double rotation,
}) {
  const steps = 220;
  final path = Path();
  for (var i = 0; i <= steps; i++) {
    final a = 2 * math.pi * i / steps;
    final r = radius * (1 - depth * (1 - math.cos(lobes * a)) / 2);
    final pt =
        center + Offset(math.cos(a + rotation) * r, math.sin(a + rotation) * r);
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  return path..close();
}

Paint fillPaint(Color color) => Paint()..color = color;

Paint strokePaint(
  Color color,
  double width, {
  StrokeCap cap = StrokeCap.round,
}) =>
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round
      ..color = color;
