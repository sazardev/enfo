import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../clock_frame.dart';
import '../paint_utils.dart';

const double _tau = 2 * math.pi;
const double _top = -math.pi / 2;

abstract class _P extends CustomPainter {
  _P(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// Face = painter with an optional centered/aligned label.
class _Painted extends StatelessWidget {
  const _Painted({
    required this.painter,
    this.label,
    this.labelAlign = Alignment.center,
    this.labelScale = 0.16,
    this.color,
  });

  final CustomPainter painter;
  final String? label;
  final Alignment labelAlign;
  final double labelScale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      return CustomPaint(
        painter: painter,
        child: label == null
            ? null
            : Align(
                alignment: labelAlign,
                child: FaceText(
                  label!,
                  size: s * labelScale,
                  color: color ?? Colors.white,
                ),
              ),
      );
    });
  }
}

/// Speedometer-style gauge with a needle.
class GaugeFace extends ClockFaceWidget {
  const GaugeFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _GaugePainter(frame, palette),
        label: frame.ringText,
        labelAlign: const Alignment(0, 0.62),
        labelScale: 0.15,
        color: palette.ink,
      );
}

class _GaugePainter extends _P {
  _GaugePainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height * 1.3);
    final c = Offset(size.width / 2, size.height * 0.52);
    final r = s * 0.42;
    const start = math.pi * 0.8;
    const sweep = math.pi * 1.4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final stroke = s * 0.09;
    canvas.drawArc(
        rect, start, sweep, false, strokePaint(palette.track, stroke));
    canvas.drawArc(rect, start, sweep * frame.remainingFraction, false,
        strokePaint(palette.accent, stroke));
    final a = start + sweep * frame.remainingFraction;
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
        c, c + dir * (r * 0.78), strokePaint(palette.ink, s * 0.03));
    canvas.drawCircle(c, s * 0.05, fillPaint(palette.ink));
    canvas.drawCircle(c, s * 0.022, fillPaint(palette.accent));
  }
}

/// Ticked dial with a needle making one lap per phase.
class NeedleFace extends ClockFaceWidget {
  const NeedleFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _NeedlePainter(frame, palette),
        label: frame.ringText,
        labelAlign: const Alignment(0, 0.42),
        labelScale: 0.11,
        color: palette.ink,
      );
}

class _NeedlePainter extends _P {
  _NeedlePainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.46;
    for (var i = 0; i < 60; i++) {
      final a = _top + _tau * i / 60;
      final d = Offset(math.cos(a), math.sin(a));
      final major = i % 5 == 0;
      final passed = i / 60 <= frame.p;
      canvas.drawLine(
        c + d * (r - s * (major ? 0.07 : 0.04)),
        c + d * r,
        strokePaint(passed ? palette.accent : palette.track, s * 0.014),
      );
    }
    final a = _top + _tau * frame.p;
    final d = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(c - d * (s * 0.06), c + d * (r * 0.8),
        strokePaint(palette.accent, s * 0.03));
    canvas.drawCircle(c, s * 0.04, fillPaint(palette.accent));
  }
}

/// Analog clock hands showing the time left.
class AnalogFace extends ClockFaceWidget {
  const AnalogFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) =>
      _Painted(painter: _AnalogPainter(frame, palette));
}

class _AnalogPainter extends _P {
  _AnalogPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.46;
    for (var i = 0; i < 12; i++) {
      final a = _top + _tau * i / 12;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r * 0.86), c + d * r,
          strokePaint(palette.muted, s * (i % 3 == 0 ? 0.03 : 0.018)));
    }
    final left = frame.remainingExact;
    Offset hand(double turns, double len) {
      final a = _top + _tau * turns;
      return c + Offset(math.cos(a), math.sin(a)) * len;
    }

    canvas.drawLine(
        c, hand(left / 43200, r * 0.5), strokePaint(palette.ink, s * 0.04));
    canvas.drawLine(
        c, hand(left / 3600, r * 0.76), strokePaint(palette.ink, s * 0.028));
    canvas.drawLine(c, hand((left % 60) / 60, r * 0.86),
        strokePaint(palette.accent, s * 0.014));
    canvas.drawCircle(c, s * 0.035, fillPaint(palette.accent));
  }
}

/// Three concentric rings: phase, current minute, and a slow breath.
class RingsFace extends ClockFaceWidget {
  const RingsFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _RingsPainter(frame, palette),
        label: frame.ringText,
        labelScale: 0.1,
        color: palette.ink,
      );
}

class _RingsPainter extends _P {
  _RingsPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final stroke = s * 0.07;
    final rings = [
      (s * 0.44, frame.p, palette.accent),
      (s * 0.34, frame.minuteFraction, palette.onContainer),
      (s * 0.24, (frame.remainingExact % 1), palette.muted),
    ];
    for (final (r, v, color) in rings) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(c, r, strokePaint(palette.track, stroke));
      if (v > 0.002) {
        canvas.drawArc(rect, _top, _tau * v, false, strokePaint(color, stroke));
      }
    }
  }
}

/// Rounded-square outline that fills around its perimeter.
class SquircleFace extends ClockFaceWidget {
  const SquircleFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _SquirclePainter(frame, palette),
        label: frame.ringText,
        labelScale: 0.15,
        color: palette.ink,
      );
}

class _SquirclePainter extends _P {
  _SquirclePainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.08;
    final inset = stroke / 2 + s * 0.02;
    final l = (size.width - s) / 2 + inset;
    final t = (size.height - s) / 2 + inset;
    final rr = l + s - 2 * inset;
    final bb = t + s - 2 * inset;
    final rad = s * 0.24;
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, t)
      ..lineTo(rr - rad, t)
      ..arcToPoint(Offset(rr, t + rad), radius: Radius.circular(rad))
      ..lineTo(rr, bb - rad)
      ..arcToPoint(Offset(rr - rad, bb), radius: Radius.circular(rad))
      ..lineTo(l + rad, bb)
      ..arcToPoint(Offset(l, bb - rad), radius: Radius.circular(rad))
      ..lineTo(l, t + rad)
      ..arcToPoint(Offset(l + rad, t), radius: Radius.circular(rad))
      ..lineTo(cx, t);
    canvas.drawPath(path, strokePaint(palette.track, stroke));
    for (final m in path.computeMetrics()) {
      if (frame.p > 0.002) {
        canvas.drawPath(m.extractPath(0, m.length * frame.p),
            strokePaint(palette.accent, stroke));
      }
    }
  }
}

/// Signal-strength style columns that drop out.
class ColumnsFace extends ClockFaceWidget {
  const ColumnsFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaceText(frame.centerText, size: h * 0.2, color: palette.ink),
            SizedBox(height: h * 0.06),
            SizedBox(
              width: box.maxWidth,
              height: h * 0.55,
              child: CustomPaint(painter: _ColumnsPainter(frame, palette)),
            ),
          ],
        );
      });
}

class _ColumnsPainter extends _P {
  _ColumnsPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 12;
    final bw = size.width / (n * 1.6);
    final gap = bw * 0.6;
    final x0 = (size.width - (n * bw + (n - 1) * gap)) / 2;
    final left = n * frame.remainingFraction;
    for (var i = 0; i < n; i++) {
      final h = size.height * (0.28 + 0.72 * (i + 1) / n);
      final lit = i + 1 <= left.ceil();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x0 + i * (bw + gap), size.height - h, bw, h),
          Radius.circular(bw / 2),
        ),
        fillPaint(lit ? palette.accent : palette.track),
      );
    }
  }
}

/// Thermometer-like vertical capsule that fills upward.
class VerticalFace extends ClockFaceWidget {
  const VerticalFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Column(
          children: [
            SizedBox(
              width: w,
              child:
                  FitText(frame.centerText, size: w * 0.3, color: palette.ink),
            ),
            SizedBox(height: w * 0.08),
            Expanded(
                child: CustomPaint(
                    painter: _VerticalPainter(frame, palette),
                    size: Size.infinite)),
          ],
        );
      });
}

class _VerticalPainter extends _P {
  _VerticalPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.min(size.width * 0.5, size.height * 0.35);
    final r = Rect.fromLTWH((size.width - w) / 2, 0, w, size.height);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(w / 2));
    canvas.drawRRect(rr, fillPaint(palette.track));
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      Rect.fromLTRB(r.left, r.bottom - r.height * frame.p, r.right, r.bottom),
      fillPaint(palette.accent),
    );
    canvas.restore();
  }
}

/// Ten big dots, one per 10%.
class StepsFace extends ClockFaceWidget {
  const StepsFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaceText(frame.centerText, size: h * 0.24, color: palette.ink),
            SizedBox(height: h * 0.1),
            SizedBox(
              width: box.maxWidth,
              height: h * 0.22,
              child: CustomPaint(painter: _StepsPainter(frame, palette)),
            ),
          ],
        );
      });
}

class _StepsPainter extends _P {
  _StepsPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 10;
    final cell = size.width / n;
    final elapsed = n * frame.p;
    for (var i = 0; i < n; i++) {
      final at = Offset((i + 0.5) * cell, size.height / 2);
      final gone = i < elapsed.floor();
      final part = i == elapsed.floor() ? 1 - (elapsed - elapsed.floor()) : 1.0;
      canvas.drawCircle(
        at,
        cell * (gone ? 0.16 : 0.16 + 0.24 * part),
        fillPaint(gone ? palette.track : palette.accent),
      );
    }
  }
}

/// 5x5 grid of rounded blocks that vanish one by one.
class BlocksFace extends ClockFaceWidget {
  const BlocksFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) =>
      _Painted(painter: _BlocksPainter(frame, palette));
}

class _BlocksPainter extends _P {
  _BlocksPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    final s = size.shortestSide;
    final cell = s * 0.92 / n;
    final ox = (size.width - cell * n) / 2;
    final oy = (size.height - cell * n) / 2;
    final elapsed = n * n * frame.p;
    for (var i = 0; i < n * n; i++) {
      final rect = Rect.fromCenter(
        center: Offset(ox + (i % n + 0.5) * cell, oy + (i ~/ n + 0.5) * cell),
        width: cell * 0.84,
        height: cell * 0.84,
      );
      final gone = i < elapsed.floor();
      final part = i == elapsed.floor() ? 1 - (elapsed - elapsed.floor()) : 1.0;
      final k = gone ? 0.0 : part;
      if (gone) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: rect.center, width: cell * 0.2, height: cell * 0.2),
              Radius.circular(cell * 0.1)),
          fillPaint(palette.track),
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: rect.center,
                width: rect.width * (0.3 + 0.7 * k),
                height: rect.height * (0.3 + 0.7 * k)),
            Radius.circular(cell * 0.22),
          ),
          fillPaint(palette.accent),
        );
      }
    }
  }
}

/// Archimedean spiral that draws itself.
class SpiralFace extends ClockFaceWidget {
  const SpiralFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _SpiralPainter(frame, palette),
        label: frame.ringText,
        labelScale: 0.0,
      );
}

class _SpiralPainter extends _P {
  _SpiralPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    const turns = 3.2;
    const steps = 360;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final a = _top + _tau * turns * t;
      final r = s * (0.05 + 0.41 * t);
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final stroke = s * 0.045;
    canvas.drawPath(path, strokePaint(palette.track, stroke));
    for (final m in path.computeMetrics()) {
      if (frame.p > 0.002) {
        canvas.drawPath(m.extractPath(0, m.length * frame.p),
            strokePaint(palette.accent, stroke));
      }
    }
  }
}

/// Ring of chunky "orange slice" arcs.
class SlicesFace extends ClockFaceWidget {
  const SlicesFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _SlicesPainter(frame, palette),
        label: frame.ringText,
        labelScale: 0.15,
        color: palette.ink,
      );
}

class _SlicesPainter extends _P {
  _SlicesPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 12;
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final stroke = s * 0.14;
    final r = s * 0.5 - stroke / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final step = _tau / n;
    final gap = step * 0.14;
    final elapsed = n * frame.p;
    for (var i = 0; i < n; i++) {
      final gone = i < elapsed.floor();
      final part = i == elapsed.floor() ? 1 - (elapsed - elapsed.floor()) : 1.0;
      final sweep = (step - gap) * (gone ? 1 : part);
      final start = _top + i * step + gap / 2;
      canvas.drawArc(
        rect,
        start,
        step - gap,
        false,
        strokePaint(palette.track, stroke, cap: StrokeCap.butt),
      );
      if (!gone) {
        canvas.drawArc(
          rect,
          start + (step - gap) - sweep,
          sweep,
          false,
          strokePaint(palette.accent, stroke, cap: StrokeCap.butt),
        );
      }
    }
  }
}

/// Segmented horizontal bar: ten pills filling left to right.
class PillsFace extends ClockFaceWidget {
  const PillsFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: w,
                child: FitText(frame.centerText,
                    size: w * 0.24, color: palette.ink)),
            SizedBox(height: w * 0.08),
            SizedBox(
                width: w,
                height: w * 0.12,
                child: CustomPaint(painter: _PillsPainter(frame, palette))),
          ],
        );
      });
}

class _PillsPainter extends _P {
  _PillsPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 10;
    final gap = size.width * 0.02;
    final w = (size.width - gap * (n - 1)) / n;
    final elapsed = n * frame.p;
    for (var i = 0; i < n; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (w + gap), 0, w, size.height),
        Radius.circular(size.height / 2),
      );
      canvas.drawRRect(r, fillPaint(palette.track));
      final fill = (elapsed - i).clamp(0.0, 1.0);
      if (fill > 0) {
        canvas.save();
        canvas.clipRRect(r);
        canvas.drawRect(Rect.fromLTWH(r.left, 0, w * fill, size.height),
            fillPaint(palette.accent));
        canvas.restore();
      }
    }
  }
}

/// Hexagon outline that fills around its perimeter.
class HexagonFace extends ClockFaceWidget {
  const HexagonFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => _Painted(
        painter: _HexPainter(frame, palette),
        label: frame.ringText,
        labelScale: 0.15,
        color: palette.ink,
      );
}

class _HexPainter extends _P {
  _HexPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.44;
    final path = Path();
    for (var i = 0; i <= 6; i++) {
      final a = _top + _tau * i / 6;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final stroke = s * 0.07;
    canvas.drawPath(path, strokePaint(palette.track, stroke));
    for (final m in path.computeMetrics()) {
      if (frame.p > 0.002) {
        canvas.drawPath(m.extractPath(0, m.length * frame.p),
            strokePaint(palette.accent, stroke));
      }
    }
  }
}

/// Ascending stairs whose steps go dark.
class StairsFace extends ClockFaceWidget {
  const StairsFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaceText(frame.centerText, size: h * 0.2, color: palette.ink),
            SizedBox(height: h * 0.06),
            SizedBox(
                width: box.maxWidth,
                height: h * 0.55,
                child: CustomPaint(painter: _StairsPainter(frame, palette))),
          ],
        );
      });
}

class _StairsPainter extends _P {
  _StairsPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 8;
    final w = size.width / n;
    final left = (n * frame.remainingFraction).ceil();
    for (var i = 0; i < n; i++) {
      final h = size.height * (i + 1) / n;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(i * w + w * 0.06, size.height - h, w * 0.88, h),
          topLeft: Radius.circular(w * 0.22),
          topRight: Radius.circular(w * 0.22),
        ),
        fillPaint(i < left ? palette.accent : palette.track),
      );
    }
  }
}

/// Candle that burns down, flame flickering.
class CandleFace extends ClockFaceWidget {
  const CandleFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) =>
      _Painted(painter: _CandlePainter(frame, palette));
}

class _CandlePainter extends _P {
  _CandlePainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height * 0.9);
    final cx = size.width / 2;
    final bottom = size.height * 0.94;
    final bodyW = s * 0.42;
    final maxH = size.height * 0.5;
    final bodyH = maxH * (0.12 + 0.88 * frame.remainingFraction);
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - bodyW / 2, bottom - bodyH, bodyW, bodyH),
      topLeft: Radius.circular(bodyW * 0.18),
      topRight: Radius.circular(bodyW * 0.18),
      bottomLeft: Radius.circular(bodyW * 0.1),
      bottomRight: Radius.circular(bodyW * 0.1),
    );
    canvas.drawRRect(
      body,
      fillPaint(Color.lerp(palette.container, palette.accent, 0.4)!),
    );
    final top = bottom - bodyH;
    canvas.drawLine(Offset(cx, top), Offset(cx, top - s * 0.08),
        strokePaint(palette.ink, s * 0.02));

    final flick = frame.running
        ? math.sin(frame.time * 9) * 0.06 + math.sin(frame.time * 5.3) * 0.04
        : 0.0;
    final fh = s * 0.3 * (1 + flick);
    final fw = s * 0.15 * (1 - flick * 0.6);
    final base = Offset(cx, top - s * 0.06);
    final flame = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - fw, base.dy - fh * 0.2, base.dx - fw * 0.5,
          base.dy - fh * 0.7, base.dx + flick * s, base.dy - fh)
      ..cubicTo(base.dx + fw * 0.5, base.dy - fh * 0.7, base.dx + fw,
          base.dy - fh * 0.2, base.dx, base.dy)
      ..close();
    canvas.drawPath(flame, fillPaint(palette.accent));
  }
}

/// Moon that wanes to nothing.
class MoonFace extends ClockFaceWidget {
  const MoonFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) =>
      _Painted(painter: _MoonPainter(frame, palette));
}

class _MoonPainter extends _P {
  _MoonPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final r = s * 0.42;
    canvas.drawCircle(c, r, fillPaint(palette.track));
    final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    // A same-size shadow slides in from the right: full moon at p=0, gone
    // at p=1, crescents in between.
    final shadow = Path()
      ..addOval(
        Rect.fromCircle(
            center: c + Offset(2 * r * (1 - frame.p), 0), radius: r),
      );
    final lit = Path.combine(PathOperation.difference, moon, shadow);
    canvas.drawPath(lit, fillPaint(palette.accent));
  }
}

/// Measuring-tape ruler scrolling under a fixed marker.
class RulerFace extends ClockFaceWidget {
  const RulerFace({super.key, required super.frame, required super.palette});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: w,
                child: FitText(frame.centerText,
                    size: w * 0.22, color: palette.ink)),
            SizedBox(height: w * 0.05),
            SizedBox(
                width: w,
                height: w * 0.32,
                child: CustomPaint(painter: _RulerPainter(frame, palette))),
          ],
        );
      });
}

class _RulerPainter extends _P {
  _RulerPainter(super.frame, super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const unit = 10.0; // seconds per tick
    final spacing = size.width / 18;
    final cx = size.width / 2;
    final pos = frame.remainingExact / unit;
    final first = (pos - 10).floor().clamp(0, 1 << 30);
    final last = (pos + 10).ceil();
    for (var i = first; i <= last; i++) {
      if (i * unit > frame.totalSeconds) break;
      final x = cx + (i - pos) * spacing;
      final major = i % 6 == 0;
      final lit = i <= pos;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (major ? 0.25 : 0.55)),
        strokePaint(
            lit ? palette.ink : palette.track, spacing * (major ? 0.16 : 0.1)),
      );
    }
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height),
        strokePaint(palette.accent, spacing * 0.26));
  }
}
