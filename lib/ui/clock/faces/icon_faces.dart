import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../clock_frame.dart';
import '../paint_utils.dart';

/// A tomato that drains from the top as the focus session is used up.
class TomatoFace extends ClockFaceWidget {
  const TomatoFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TomatoPainter(frame, palette));
  }
}

class _TomatoPainter extends CustomPainter {
  _TomatoPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  static const _leaf = Color(0xFF43A047);
  static const _stem = Color(0xFF2E7D32);
  static const _red = Color(0xFFE5484D);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final ox = (size.width - s) / 2;
    final oy = (size.height - s) / 2;
    canvas.translate(ox, oy);

    final body = frame.isRest ? palette.accent : _red;
    final cx = s * 0.5;
    final cy = s * 0.58;
    final rx = s * 0.4;
    final ry = s * 0.34;
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );

    canvas.drawOval(bodyRect, fillPaint(body.withValues(alpha: 0.18)));

    canvas.save();
    final fillTop = bodyRect.bottom - bodyRect.height * frame.remainingFraction;
    canvas.clipRect(Rect.fromLTRB(0, fillTop, s, s));
    canvas.drawOval(bodyRect, fillPaint(body));
    canvas.restore();

    // Calyx: five rounded petals fanning out from the top of the body.
    final petals = fillPaint(_leaf);
    for (final deg in const [-72, -36, 0, 36, 72]) {
      canvas.save();
      canvas.translate(cx, cy - ry * 0.92);
      canvas.rotate(deg * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, s * 0.02),
          width: s * 0.11,
          height: s * 0.2,
        ),
        petals,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - ry - s * 0.05),
          width: s * 0.045,
          height: s * 0.13,
        ),
        Radius.circular(s * 0.022),
      ),
      fillPaint(_stem),
    );
  }

  @override
  bool shouldRepaint(covariant _TomatoPainter old) => true;
}

/// Flat hourglass: sand moves from the top chamber to the bottom one.
class HourglassFace extends ClockFaceWidget {
  const HourglassFace(
      {super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HourglassPainter(frame, palette));
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    final top = s * 0.15;
    final bottom = s * 0.85;
    final mid = s * 0.5;
    final left = s * 0.24;
    final right = s * 0.76;
    final neckL = s * 0.47;
    final neckR = s * 0.53;

    final glass = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(neckR, mid)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..lineTo(neckL, mid)
      ..close();

    final soften = s * 0.03;
    canvas.drawPath(glass, fillPaint(palette.container));
    canvas.drawPath(glass, strokePaint(palette.container, soften));

    final chamber = mid - top;
    canvas.save();
    canvas.clipPath(glass);
    final sand = fillPaint(palette.accent);
    final upperTop = mid - chamber * frame.remainingFraction;
    canvas.drawRect(Rect.fromLTRB(0, upperTop, s, mid), sand);
    final lowerTop = bottom - chamber * frame.p;
    canvas.drawRect(Rect.fromLTRB(0, lowerTop, s, bottom), sand);
    if (frame.running && frame.p > 0 && frame.p < 1) {
      canvas.drawLine(
        Offset(s * 0.5, mid - s * 0.02),
        Offset(s * 0.5, lowerTop),
        strokePaint(palette.accent, s * 0.014, cap: StrokeCap.butt),
      );
    }
    canvas.restore();

    final capPaint = fillPaint(palette.ink);
    final capH = s * 0.055;
    final radius = Radius.circular(capH / 2);
    for (final y in [top - capH * 0.6, bottom - capH * 0.4]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.16, y, s * 0.68, capH),
          radius,
        ),
        capPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter old) => true;
}

/// Battery: work drains it, rest charges it back up.
class BatteryFace extends ClockFaceWidget {
  const BatteryFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BatteryPainter(frame, palette));
  }
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final nubW = w * 0.05;
    final bodyW = w - nubW - w * 0.02;
    final radius = Radius.circular(h * 0.26);
    final body = Rect.fromLTWH(0, 0, bodyW, h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(body, radius),
      fillPaint(palette.container),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyW + w * 0.02, h * 0.32, nubW, h * 0.36),
        Radius.circular(nubW / 2),
      ),
      fillPaint(palette.container),
    );

    final level = frame.isRest ? frame.p : frame.remainingFraction;
    final pad = h * 0.1;
    final inner = Rect.fromLTWH(pad, pad, bodyW - pad * 2, h - pad * 2);
    final fillW = inner.width * level;
    if (fillW > 0.5) {
      final low = !frame.isRest && level < 0.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inner.left, inner.top, fillW, inner.height),
          Radius.circular(h * 0.18),
        ),
        fillPaint(low ? palette.alert : palette.accent),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) => true;
}

/// Squircle whose two-tone icon fills up from the bottom as time passes.
class IconFace extends ClockFaceWidget {
  const IconFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      final icon = frame.paused
          ? Icons.pause_rounded
          : frame.isRest
              ? Icons.coffee_rounded
              : Icons.timer_rounded;

      Widget layer(Color bg, Color fg) => SizedBox.square(
            dimension: s,
            child: ColoredBox(
              color: bg,
              child: Center(child: Icon(icon, size: s * 0.46, color: fg)),
            ),
          );

      return ClipRRect(
        borderRadius: BorderRadius.circular(s * 0.32),
        child: Stack(
          children: [
            layer(palette.container, palette.onContainer),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: frame.p,
                  child: layer(palette.accent, palette.onAccent),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
