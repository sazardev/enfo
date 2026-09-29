import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../molecules/countdown_ring.dart';
import '../clock_frame.dart';
import '../paint_utils.dart';

const double _top = -math.pi / 2;
const double _tau = 2 * math.pi;

/// Classic filled ring (the original Enfo dial).
class RingFace extends ClockFaceWidget {
  const RingFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      final base =
          Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
      return CountdownRing(
        progress: frame.p,
        label: frame.ringText,
        labelStyle: base.copyWith(
          fontSize: s / 6,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        ringColor: palette.accent,
        trackColor: palette.track,
        surfaceColor: palette.surface,
      );
    });
  }
}

/// M3 Expressive wavy circular progress: the remaining arc ripples.
class WavyRingFace extends ClockFaceWidget {
  const WavyRingFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return CustomPaint(
        painter: _WavyRingPainter(frame, palette),
        child: Center(
          child: FaceText(frame.ringText, size: s / 6, color: palette.ink),
        ),
      );
    });
  }
}

class _WavyRingPainter extends CustomPainter {
  _WavyRingPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final stroke = s * 0.07;
    final radius = s / 2 - stroke * 1.4;

    canvas.drawCircle(center, radius, strokePaint(palette.track, stroke));

    final remaining = frame.remainingFraction;
    if (remaining <= 0.001) return;
    canvas.drawPath(
      wavyArcPath(
        center: center,
        radius: radius,
        amplitude: s * 0.017,
        waves: 10,
        phase: -frame.time * 2.4,
        startAngle: _top,
        sweep: _tau * remaining,
      ),
      strokePaint(palette.accent, stroke * 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _WavyRingPainter old) => true;
}

/// Ring of 60 tick marks that switch off as time passes.
class SegmentsFace extends ClockFaceWidget {
  const SegmentsFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return CustomPaint(
        painter: _SegmentsPainter(frame, palette),
        child: Center(
          child: FaceText(frame.ringText, size: s / 6, color: palette.ink),
        ),
      );
    });
  }
}

class _SegmentsPainter extends CustomPainter {
  _SegmentsPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 60;
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final outer = s / 2 - s * 0.03;
    final width = s * 0.024;
    final elapsedExact = n * frame.p;
    final elapsed = elapsedExact.floor();

    for (var i = 0; i < n; i++) {
      final a = _top + _tau * i / n;
      final major = i % 5 == 0;
      final fullLen = s * (major ? 0.115 : 0.085);
      final lit = i >= elapsed;
      // The tick being consumed shrinks smoothly instead of popping off.
      final partial = i == elapsed ? 1 - (elapsedExact - elapsed) : 1.0;
      final len = lit ? fullLen * (0.4 + 0.6 * partial) : fullLen * 0.42;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (outer - len),
        center + dir * outer,
        strokePaint(lit ? palette.accent : palette.track, width),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentsPainter old) => true;
}

/// Planet orbiting a ring, with a thin inner arc for the current minute.
class OrbitFace extends ClockFaceWidget {
  const OrbitFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return CustomPaint(
        painter: _OrbitPainter(frame, palette),
        child: Center(
          child: FaceText(frame.ringText, size: s / 6.5, color: palette.ink),
        ),
      );
    });
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final radius = s / 2 - s * 0.08;

    canvas.drawCircle(center, radius, strokePaint(palette.track, s * 0.02));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _top,
      _tau * frame.p,
      false,
      strokePaint(palette.accent, s * 0.02),
    );

    final inner = radius * 0.8;
    canvas.drawCircle(center, inner, strokePaint(palette.track, s * 0.03));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: inner),
      _top,
      _tau * frame.minuteFraction,
      false,
      strokePaint(palette.accent.withValues(alpha: 0.55), s * 0.03),
    );

    final a = _top + _tau * frame.p;
    final planet = center + Offset(math.cos(a), math.sin(a)) * radius;
    canvas.drawCircle(planet, s * 0.075, fillPaint(palette.container));
    canvas.drawCircle(planet, s * 0.05, fillPaint(palette.accent));
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => true;
}

/// Pie wedge that shrinks, digits underneath.
class PieFace extends ClockFaceWidget {
  const PieFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: s * 0.7,
            child: CustomPaint(painter: _PiePainter(frame, palette)),
          ),
          SizedBox(height: s * 0.06),
          FaceText(frame.centerText, size: s * 0.14, color: palette.ink),
        ],
      );
    });
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(center, r, fillPaint(palette.container));
    final remaining = frame.remainingFraction;
    if (remaining <= 0.001) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      _top + _tau * frame.p,
      _tau * remaining,
      true,
      fillPaint(palette.accent),
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => true;
}

/// Kitchen-timer dial: a wedge counts down toward 12 o'clock.
class KitchenFace extends ClockFaceWidget {
  const KitchenFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return CustomPaint(
        painter: _KitchenPainter(frame, palette),
        child: Align(
          alignment: const Alignment(0, 0.52),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(s),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: s * 0.05,
                vertical: s * 0.025,
              ),
              child: FaceText(
                frame.centerText,
                size: s * 0.1,
                color: palette.ink,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _KitchenPainter extends CustomPainter {
  _KitchenPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = size.center(Offset.zero);
    final r = s / 2;
    canvas.drawCircle(center, r, fillPaint(palette.surface));

    final span = math.max(3600, frame.totalSeconds).toDouble();
    final sweep = _tau * (frame.remainingExact / span);
    final wedgeR = r * 0.8;
    final rect = Rect.fromCircle(center: center, radius: wedgeR);
    canvas.drawArc(rect, _top, sweep, true, fillPaint(palette.container));

    for (var i = 0; i < 12; i++) {
      final a = _top + _tau * i / 12;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * (r * 0.9),
        s * (i % 3 == 0 ? 0.017 : 0.011),
        fillPaint(palette.muted),
      );
    }

    final end = _top + sweep;
    canvas.drawLine(
      center,
      center + Offset(math.cos(end), math.sin(end)) * wedgeR,
      strokePaint(palette.accent, s * 0.032),
    );
    canvas.drawCircle(center, s * 0.05, fillPaint(palette.accent));
  }

  @override
  bool shouldRepaint(covariant _KitchenPainter old) => true;
}

/// Grid of 60 dots; each one shrinks away as its minute-slice is used up.
class DotsFace extends ClockFaceWidget {
  const DotsFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaceText(frame.centerText, size: s * 0.16, color: palette.ink),
          SizedBox(height: s * 0.09),
          SizedBox(
            width: s,
            height: s * 0.6,
            child: CustomPaint(painter: _DotsPainter(frame, palette)),
          ),
        ],
      );
    });
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 10;
    const rows = 6;
    final cell = size.width / cols;
    final elapsedExact = cols * rows * frame.p;
    final elapsed = elapsedExact.floor();
    for (var i = 0; i < cols * rows; i++) {
      final c = i % cols;
      final r = i ~/ cols;
      final at = Offset((c + 0.5) * cell, (r + 0.5) * cell);
      if (i < elapsed) {
        canvas.drawCircle(at, cell * 0.14, fillPaint(palette.track));
      } else {
        final partial = i == elapsed ? 1 - (elapsedExact - elapsed) : 1.0;
        canvas.drawCircle(
          at,
          cell * (0.14 + 0.2 * partial),
          fillPaint(palette.accent),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => true;
}

/// M3-style linear progress (active bar, gap, track, end dot); optionally
/// wavy, with digits above.
class BarFace extends ClockFaceWidget {
  const BarFace({
    super.key,
    required super.frame,
    required super.palette,
    this.wavy = false,
  });

  final bool wavy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: w,
            child:
                FitText(frame.centerText, size: w * 0.24, color: palette.ink),
          ),
          SizedBox(height: w * 0.08),
          SizedBox(
            width: w,
            height: w * 0.14,
            child: CustomPaint(painter: _BarPainter(frame, palette, wavy)),
          ),
        ],
      );
    });
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.frame, this.palette, this.wavy);
  final ClockFrame frame;
  final ClockPalette palette;
  final bool wavy;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.05;
    final inset = stroke / 2;
    final y = size.height / 2;
    final x0 = inset;
    final x1 = size.width - inset;
    final xa = x0 + (x1 - x0) * frame.p;
    final gap = stroke * 0.7;

    final trackStart = xa + stroke / 2 + gap;
    if (trackStart < x1) {
      canvas.drawLine(
        Offset(trackStart, y),
        Offset(x1, y),
        strokePaint(palette.track, stroke),
      );
    }
    canvas.drawCircle(Offset(x1, y), stroke * 0.22, fillPaint(palette.accent));

    if (wavy) {
      final amp = stroke * 0.55 * math.min(1, (xa - x0) / (stroke * 2) + 0.2);
      canvas.drawPath(
        wavyLinePath(
          x0: x0,
          x1: math.max(x0 + 0.1, xa),
          y: y,
          amplitude: amp,
          wavelength: stroke * 5,
          phase: -frame.time * 5,
        ),
        strokePaint(palette.accent, stroke * 0.8)..style = PaintingStyle.stroke,
      );
    } else {
      canvas.drawLine(
        Offset(x0, y),
        Offset(math.max(x0 + 0.1, xa), y),
        strokePaint(palette.accent, stroke),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => true;
}
