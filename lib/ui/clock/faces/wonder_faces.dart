import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../clock_frame.dart';
import '../paint_utils.dart';

// Animation-only faces. Each one is a single flat subject (no backdrop, no
// translucent wash) and shows progress through size or how many elements
// remain, so the countdown is readable without any digits.

const double _tau = 2 * math.pi;

/// Base for faces that are just one painter.
abstract class _PaintedFace extends ClockFaceWidget {
  const _PaintedFace({super.key, required super.frame, required super.palette});

  CustomPainter painter();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: painter());
}

abstract class _FacePainter extends CustomPainter {
  _FacePainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Organic blob that wobbles and shrinks.
class BlobFace extends _PaintedFace {
  const BlobFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _BlobPainter(frame, palette);
}

class _BlobPainter extends _FacePainter {
  _BlobPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final t = frame.time;
    final base = s * 0.46 * (0.34 + 0.66 * frame.remainingFraction);
    final path = Path();
    const steps = 180;
    for (var i = 0; i <= steps; i++) {
      final a = _tau * i / steps;
      final r = base *
          (1 +
              0.08 * math.sin(3 * a + t * 1.3) +
              0.05 * math.sin(5 * a - t * 1.9) +
              0.03 * math.sin(2 * a + t * 0.7));
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), fillPaint(palette.accent));
  }
}

/// Flower that drops a petal as time passes.
class FlowerFace extends _PaintedFace {
  const FlowerFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _FlowerPainter(frame, palette);
}

class _FlowerPainter extends _FacePainter {
  _FlowerPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 8;
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < n; i++) {
      final lit = i < left;
      final breathe = 1 + 0.07 * math.sin(frame.time * 2 + i * 0.8);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(_tau * i / n + frame.time * 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * 0.235, 0),
          width: s * 0.3 * breathe,
          height: s * 0.19,
        ),
        fillPaint(lit ? palette.accent : palette.track),
      );
      canvas.restore();
    }
    canvas.drawCircle(c, s * 0.085, fillPaint(palette.container));
  }
}

/// Sun with pulsing rays that go out one by one.
class SunFace extends _PaintedFace {
  const SunFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _SunPainter(frame, palette);
}

class _SunPainter extends _FacePainter {
  _SunPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 12;
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, s * 0.2, fillPaint(palette.accent));
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < left; i++) {
      final a = _tau * i / n + frame.time * 0.4;
      final len = s * 0.11 * (1 + 0.3 * math.sin(frame.time * 3 + i));
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (s * 0.3),
        c + dir * (s * 0.3 + len),
        strokePaint(palette.accent, s * 0.045),
      );
    }
  }
}

/// Two meshing gears that turn and shrink.
class GearsFace extends _PaintedFace {
  const GearsFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _GearsPainter(frame, palette);
}

class _GearsPainter extends _FacePainter {
  _GearsPainter(super.frame, super.palette);

  Path _gear(Offset c, double r, int teeth, double rot) {
    final step = _tau / teeth;
    final inner = r * 0.8;
    final path = Path()..fillType = PathFillType.evenOdd;
    for (var i = 0; i < teeth; i++) {
      final a0 = rot + i * step;
      final pts = [
        (a0 - step * 0.3, inner),
        (a0 - step * 0.15, r),
        (a0 + step * 0.15, r),
        (a0 + step * 0.3, inner),
      ];
      for (var j = 0; j < pts.length; j++) {
        final p =
            c + Offset(math.cos(pts[j].$1), math.sin(pts[j].$1)) * pts[j].$2;
        i == 0 && j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    path.addOval(Rect.fromCircle(center: c, radius: r * 0.32));
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final k = 0.5 + 0.5 * frame.remainingFraction;
    final r1 = s * 0.27 * k;
    final r2 = r1 * 0.72;
    const t1 = 12;
    const t2 = 9;
    final c1 = Offset(s * 0.5 - r1 * 0.35, s * 0.5 + r1 * 0.35);
    final mesh = -0.75;
    final dist = (r1 + r2) * 0.9;
    final c2 = c1 + Offset(math.cos(mesh), math.sin(mesh)) * dist;
    final rot1 = frame.time * 0.6;
    final rot2 = -rot1 * t1 / t2 + _tau / t2 / 2 + mesh * (t1 + t2) / t2;

    canvas.drawPath(_gear(c1, r1, t1, rot1), fillPaint(palette.accent));
    canvas.drawPath(_gear(c2, r2, t2, rot2), fillPaint(palette.container));
  }
}

/// Bubbles rising; one pops per slice of time.
class BubblesFace extends _PaintedFace {
  const BubblesFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _BubblesPainter(frame, palette);
}

class _BubblesPainter extends _FacePainter {
  _BubblesPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 14;
    final s = size.shortestSide;
    final ox = (size.width - s) / 2;
    final oy = (size.height - s) / 2;
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < left; i++) {
      final speed = 0.09 + 0.07 * ((i * 0.37) % 1);
      final phase = (frame.time * speed + i * 0.211) % 1;
      final x =
          0.14 + 0.72 * ((i * 0.618) % 1) + 0.03 * math.sin(frame.time * 2 + i);
      final y = 1.02 - 1.04 * phase;
      final r = s * (0.045 + 0.07 * ((i * 0.53) % 1));
      canvas.drawCircle(
        Offset(ox + x * s, oy + y * s),
        r,
        fillPaint(i.isEven ? palette.accent : palette.container),
      );
    }
  }
}

/// Sunflower spiral (golden angle) whose outer seeds disappear.
class SunflowerFace extends _PaintedFace {
  const SunflowerFace(
      {super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _SunflowerPainter(frame, palette);
}

class _SunflowerPainter extends _FacePainter {
  _SunflowerPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 60;
    const golden = 2.399963;
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < left; i++) {
      final a = i * golden + frame.time * 0.35;
      final r = s * 0.46 * math.sqrt((i + 0.5) / n);
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r,
        s * (0.014 + 0.026 * i / n),
        fillPaint(i % 5 == 0 ? palette.container : palette.accent),
      );
    }
  }
}

/// Fireflies drifting on looping paths; they go out over time.
class FirefliesFace extends _PaintedFace {
  const FirefliesFace(
      {super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _FirefliesPainter(frame, palette);
}

class _FirefliesPainter extends _FacePainter {
  _FirefliesPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 12;
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < left; i++) {
      final t = frame.time;
      final x = math.sin(t * (0.5 + 0.07 * i) + i * 1.3);
      final y = math.sin(t * (0.4 + 0.05 * i) + i * 2.1);
      final twinkle = 0.75 + 0.25 * math.sin(t * 3 + i * 1.7);
      canvas.drawCircle(
        c + Offset(x, y) * (s * 0.38),
        s * (0.045 + 0.03 * ((i * 0.37) % 1)) * twinkle,
        fillPaint(palette.accent),
      );
    }
  }
}

/// Newton's cradle; balls go dim from the middle out.
class PendulumFace extends _PaintedFace {
  const PendulumFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _PendulumPainter(frame, palette);
}

class _PendulumPainter extends _FacePainter {
  _PendulumPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    const dimOrder = [2, 1, 3, 0, 4];
    final w = size.width;
    final h = size.height;
    final r = w / (n * 2) * 0.98;
    final len = h * 0.55;
    final top = h * 0.1;
    final u = frame.time * 2.6;
    const maxAngle = 0.62;
    final dimmed = n - (n * frame.remainingFraction).ceil();
    final off = {for (var k = 0; k < dimmed; k++) dimOrder[k]};

    for (var i = 0; i < n; i++) {
      var angle = 0.0;
      if (i == 0) angle = -maxAngle * math.max(0, math.sin(u));
      if (i == n - 1) angle = maxAngle * math.max(0, -math.sin(u));
      final px = (i + 0.5) * 2 * r + (w - n * 2 * r) / 2;
      final ball =
          Offset(px + len * math.sin(angle), top + len * math.cos(angle));
      canvas.drawLine(
        Offset(px, top),
        ball,
        strokePaint(palette.muted, w * 0.012),
      );
      canvas.drawCircle(
        ball,
        r,
        fillPaint(off.contains(i) ? palette.track : palette.accent),
      );
    }
    canvas.drawLine(
      Offset(w * 0.02, top),
      Offset(w * 0.98, top),
      strokePaint(palette.ink, w * 0.028),
    );
  }
}

/// Bouncing dots that settle one by one.
class BounceFace extends _PaintedFace {
  const BounceFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _BouncePainter(frame, palette);
}

class _BouncePainter extends _FacePainter {
  _BouncePainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    final w = size.width;
    final h = size.height;
    final r = w * 0.07;
    final floor = h * 0.78;
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) * w / n;
      if (i >= left) {
        canvas.drawCircle(Offset(x, floor), r * 0.6, fillPaint(palette.track));
        continue;
      }
      final b = math.sin(frame.time * 3.4 + i * 0.55).abs();
      final squash = 1 - 0.25 * math.pow(1 - b, 6);
      final y = floor - h * 0.5 * b;
      canvas.save();
      canvas.translate(x, y + r * (1 - squash));
      canvas.scale(1 + (1 - squash), squash);
      canvas.drawCircle(Offset.zero, r, fillPaint(palette.accent));
      canvas.restore();
    }
  }
}

/// M3 Expressive-style shape morph: soft polygons flow into each other.
class MorphFace extends _PaintedFace {
  const MorphFace({super.key, required super.frame, required super.palette});
  @override
  CustomPainter painter() => _MorphPainter(frame, palette);
}

class _MorphPainter extends _FacePainter {
  _MorphPainter(super.frame, super.palette);

  static const _sides = [3, 4, 5, 6, 7, 8];

  double _radius(double a, int n, double big) {
    final step = _tau / n;
    final local = ((a % step) + step) % step - step / 2;
    final polygon = big * math.cos(math.pi / n) / math.cos(local);
    return polygon * 0.4 + big * 0.9 * 0.6;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final big = s * 0.46 * (0.4 + 0.6 * frame.remainingFraction);
    final u = frame.time / 1.3;
    final i = u.floor();
    final e = Curves.easeInOutCubic.transform(u - i);
    final from = _sides[i % _sides.length];
    final to = _sides[(i + 1) % _sides.length];
    final rot = frame.time * 0.5;

    final path = Path();
    const steps = 200;
    for (var k = 0; k <= steps; k++) {
      final a = _tau * k / steps;
      final r = _radius(a, from, big) * (1 - e) + _radius(a, to, big) * e;
      final p = c + Offset(math.cos(a + rot), math.sin(a + rot)) * r;
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), fillPaint(palette.accent));
  }
}
