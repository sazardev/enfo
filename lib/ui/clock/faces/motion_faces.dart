import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../clock_frame.dart';
import '../paint_utils.dart';

/// M3 Expressive cookie shapes that spin while the inner one shrinks.
class CookieFace extends ClockFaceWidget {
  const CookieFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CookiePainter(frame, palette));
  }
}

class _CookiePainter extends CustomPainter {
  _CookiePainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final outer = s * 0.5;

    canvas.drawPath(
      cookiePath(
        center: center,
        radius: outer,
        lobes: 9,
        depth: 0.09,
        rotation: frame.time * 0.22,
      ),
      fillPaint(palette.container),
    );

    final inner = outer * (0.14 + 0.72 * frame.remainingFraction);
    canvas.drawPath(
      cookiePath(
        center: center,
        radius: inner,
        lobes: 9,
        depth: 0.12,
        rotation: -frame.time * 0.5,
      ),
      fillPaint(palette.accent),
    );
  }

  @override
  bool shouldRepaint(covariant _CookiePainter old) => true;
}

/// Circular tank filling with two layers of drifting waves.
class LiquidFace extends ClockFaceWidget {
  const LiquidFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LiquidPainter(frame, palette));
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  Path _wave(double s, double level, double amp, double length, double phase) {
    final y = s * (1 - level);
    final path = Path()..moveTo(0, s);
    for (var x = 0.0; x <= s; x += 3) {
      path.lineTo(x, y + amp * math.sin(2 * math.pi * x / length + phase));
    }
    return path
      ..lineTo(s, s)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final circle = Path()..addOval(Rect.fromLTWH(0, 0, s, s));

    canvas.drawPath(circle, fillPaint(palette.container));
    canvas.save();
    canvas.clipPath(circle);
    final level = 0.06 + 0.88 * frame.p;
    canvas.drawPath(
      _wave(s, level, s * 0.026, s * 0.9, frame.time * 1.6 + 1.5),
      fillPaint(palette.accent.withValues(alpha: 0.5)),
    );
    canvas.drawPath(
      _wave(s, level, s * 0.02, s * 0.65, -frame.time * 2.1),
      fillPaint(palette.accent),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) => true;
}

/// A single circle that breathes on a slow 5s cycle and contracts overall.
class BreatheFace extends ClockFaceWidget {
  const BreatheFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BreathePainter(frame, palette));
  }
}

class _BreathePainter extends CustomPainter {
  _BreathePainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final breath = 1 + 0.09 * math.sin(frame.time * 2 * math.pi / 5);
    final radius = s * 0.5 * (0.32 + 0.68 * frame.remainingFraction) * breath;
    canvas.drawCircle(
        size.center(Offset.zero), radius, fillPaint(palette.accent));
  }

  @override
  bool shouldRepaint(covariant _BreathePainter old) => true;
}

/// Audio-style bars that dance while running and double as a progress meter.
class EqualizerFace extends ClockFaceWidget {
  const EqualizerFace(
      {super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _EqualizerPainter(frame, palette));
  }
}

class _EqualizerPainter extends CustomPainter {
  _EqualizerPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 9;
    final barW = size.width / (n * 1.7);
    final gap = barW * 0.7;
    final total = n * barW + (n - 1) * gap;
    final startX = (size.width - total) / 2;
    final remaining = frame.remainingFraction;

    for (var i = 0; i < n; i++) {
      final wave =
          0.5 + 0.5 * math.sin(frame.time * (1.7 + 0.37 * i) + i * 1.7);
      final h = size.height * (0.22 + 0.72 * wave);
      final lit = (i + 0.5) / n <= remaining;
      final x = startX + i * (barW + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barW / 2, size.height / 2),
            width: barW,
            height: h,
          ),
          Radius.circular(barW / 2),
        ),
        fillPaint(lit ? palette.accent : palette.track),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter old) => true;
}

/// A dot that emits soft expanding rings; the dot shrinks over time.
class RippleFace extends ClockFaceWidget {
  const RippleFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RipplePainter(frame, palette));
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final beat = frame.running
        ? 1 + 0.05 * math.sin(frame.time * 2 * math.pi / 1.6)
        : 1.0;
    final dot = s * (0.09 + 0.1 * frame.remainingFraction) * beat;

    // Waves are bare rings that fade out completely: nothing lingers behind
    // the dot as a backdrop.
    for (var k = 0; k < 3; k++) {
      final phase = (frame.time / 3.2 + k / 3) % 1;
      final radius = dot + (s * 0.5 - dot) * Curves.easeOut.transform(phase);
      canvas.drawCircle(
        center,
        radius,
        strokePaint(
          palette.accent.withValues(alpha: 0.55 * (1 - phase)),
          s * 0.02,
        ),
      );
    }
    canvas.drawCircle(center, dot, fillPaint(palette.accent));
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => true;
}
