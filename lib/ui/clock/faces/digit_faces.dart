import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../clock_frame.dart';
import '../paint_utils.dart';
import 'number_faces.dart' show DigitSwitcher;

// Number-focused faces: no progress graphic, the time itself is the design.

/// Digits that fill with the accent color from the bottom as time passes.
class FillFace extends ClockFaceWidget {
  const FillFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      Widget layer(Color color) => SizedBox(
            width: w,
            height: h,
            child: Center(
              child: FitText(frame.centerText, size: h * 0.7, color: color),
            ),
          );
      return Stack(children: [
        layer(palette.track.withValues(alpha: 0.3)),
        Align(
          alignment: Alignment.bottomCenter,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: frame.p,
              child: layer(palette.accent),
            ),
          ),
        ),
      ]);
    });
  }
}

/// Time inside a solid pill.
class CapsuleFace extends ClockFaceWidget {
  const CapsuleFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: frame.paused ? palette.container : palette.accent,
            borderRadius: BorderRadius.circular(h),
          ),
          child: SizedBox(
            width: box.maxWidth,
            height: h * 0.62,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: h * 0.2),
                child: FitText(
                  frame.centerText,
                  size: h * 0.4,
                  color: frame.paused ? palette.onContainer : palette.onAccent,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Four separately rolling digits (no tiles).
class RollersFace extends ClockFaceWidget {
  const RollersFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = math.min(box.maxHeight * 0.7, box.maxWidth / 3.2);
      // Key on the digit itself so only changed digits roll.
      Widget roll(String d) => ClipRect(
            child: SizedBox(
              width: size * 0.62,
              height: size * 1.2,
              child: Center(
                child: DigitSwitcher(
                  text: d,
                  child: FaceText(d, size: size, color: palette.ink),
                ),
              ),
            ),
          );
      return Center(
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                roll(frame.mm[0]),
                roll(frame.mm[1]),
                FaceText(':', size: size, color: palette.accent),
                roll(frame.ss[0]),
                roll(frame.ss[1]),
              ],
            )),
      );
    });
  }
}

const _font5x7 = <String, List<String>>{
  '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
  ':': ['0', '0', '1', '0', '1', '0', '0'],
};

/// Dot-matrix (5x7) digits.
class MatrixFace extends ClockFaceWidget {
  const MatrixFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MatrixPainter(frame, palette));
  }
}

class _MatrixPainter extends CustomPainter {
  _MatrixPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final chars = frame.timeText.split('');
    var cols = 0;
    for (final c in chars) {
      cols += _font5x7[c]![0].length + 1;
    }
    cols -= 1;
    final cell = math.min(size.width / cols, size.height / 7);
    final ox = (size.width - cols * cell) / 2;
    final oy = (size.height - 7 * cell) / 2;
    var x = 0;
    final blink = !frame.running || math.sin(frame.time * math.pi * 2) > -0.4;
    for (final c in chars) {
      final glyph = _font5x7[c]!;
      for (var r = 0; r < 7; r++) {
        for (var k = 0; k < glyph[r].length; k++) {
          final on = glyph[r][k] == '1' && (c != ':' || blink);
          final at = Offset(ox + (x + k + 0.5) * cell, oy + (r + 0.5) * cell);
          canvas.drawCircle(
            at,
            cell * (on ? 0.4 : 0.14),
            fillPaint(on ? palette.accent : palette.track),
          );
        }
      }
      x += glyph[0].length + 1;
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter old) => true;
}

/// Seven-segment display.
class SevenSegFace extends ClockFaceWidget {
  const SevenSegFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SevenSegPainter(frame, palette));
  }
}

class _SevenSegPainter extends CustomPainter {
  _SevenSegPainter(this.frame, this.palette);
  final ClockFrame frame;
  final ClockPalette palette;

  // a b c d e f g
  static const _map = {
    '0': 'abcdef',
    '1': 'bc',
    '2': 'abged',
    '3': 'abgcd',
    '4': 'fgbc',
    '5': 'afgcd',
    '6': 'afgedc',
    '7': 'abc',
    '8': 'abcdefg',
    '9': 'abcdfg',
  };

  void _digit(Canvas canvas, Rect r, String d) {
    final t = r.width * 0.17;
    final on = _map[d]!;
    void seg(String id, Rect rect) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(t / 2)),
        fillPaint(on.contains(id) ? palette.accent : palette.track),
      );
    }

    final hMid = r.top + r.height / 2;
    final g = t * 0.22;
    seg('a', Rect.fromLTWH(r.left + t + g, r.top, r.width - 2 * t - 2 * g, t));
    seg(
        'g',
        Rect.fromLTWH(
            r.left + t + g, hMid - t / 2, r.width - 2 * t - 2 * g, t));
    seg(
        'd',
        Rect.fromLTWH(
            r.left + t + g, r.bottom - t, r.width - 2 * t - 2 * g, t));
    final vh = r.height / 2 - t * 1.1 - 2 * g;
    final upTop = r.top + t * 0.55 + g;
    final lowTop = hMid + t * 0.55 + g;
    seg('f', Rect.fromLTWH(r.left, upTop, t, vh));
    seg('b', Rect.fromLTWH(r.right - t, upTop, t, vh));
    seg('e', Rect.fromLTWH(r.left, lowTop, t, vh));
    seg('c', Rect.fromLTWH(r.right - t, lowTop, t, vh));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const gapU = 0.14;
    const colonU = 0.4;
    final units = 4 + colonU + gapU * 4;
    var dw = size.width / units;
    var dh = dw * 1.9;
    if (dh > size.height) {
      dh = size.height;
      dw = dh / 1.9;
    }
    final total = dw * units;
    var x = (size.width - total) / 2;
    final y = (size.height - dh) / 2;
    final chars = [frame.mm[0], frame.mm[1], ':', frame.ss[0], frame.ss[1]];
    for (final c in chars) {
      if (c == ':') {
        final on = !frame.running || math.sin(frame.time * math.pi * 2) > -0.4;
        final rr = dw * 0.09;
        for (final fy in [0.3, 0.7]) {
          canvas.drawCircle(
            Offset(x + dw * colonU / 2, y + dh * fy),
            rr,
            fillPaint(on ? palette.accent : palette.track),
          );
        }
        x += dw * (colonU + gapU);
      } else {
        _digit(canvas, Rect.fromLTWH(x, y, dw, dh), c);
        x += dw * (1 + gapU);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SevenSegPainter old) => true;
}

/// Split-flap tiles whose digits flip over when they change.
class FlipFace extends ClockFaceWidget {
  const FlipFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      Widget tile(String text, Color bg, Color fg) => Expanded(
            child: CustomPaint(
              painter: _FlipTilePainter(bg, h * 0.2),
              child: Center(
                child: ClipRect(
                  child: DigitSwitcher(
                    text: text,
                    flip: true,
                    child: FitText(text, size: h * 0.62, color: fg),
                  ),
                ),
              ),
            ),
          );
      if (frame.wordMode) {
        return Row(children: [
          tile(frame.phaseWord, palette.accent, palette.onAccent),
        ]);
      }
      return Row(children: [
        tile(frame.mm, palette.container, palette.onContainer),
        SizedBox(width: h * 0.08),
        tile(frame.ss, palette.accent, palette.onAccent),
      ]);
    });
  }
}

class _FlipTilePainter extends CustomPainter {
  _FlipTilePainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final r = Radius.circular(radius);
    const gap = 1.0;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(0, 0, size.width, mid - gap,
          topLeft: r, topRight: r),
      fillPaint(color),
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(0, mid + gap, size.width, size.height,
          bottomLeft: r, bottomRight: r),
      fillPaint(color),
    );
  }

  @override
  bool shouldRepaint(covariant _FlipTilePainter old) =>
      old.color != color || old.radius != radius;
}

/// Ultra-airy time: regular weight, wide tracking.
class FineFace extends ClockFaceWidget {
  const FineFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final base =
          Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            frame.centerText,
            textScaler: TextScaler.noScaling,
            style: base.copyWith(
              fontSize: h * 0.5,
              fontWeight: FontWeight.w400,
              letterSpacing: h * 0.08,
              color: palette.ink,
              height: 1,
            ),
          ),
        ),
      );
    });
  }
}

/// Minutes big with the seconds as a small superscript.
class SuperscriptFace extends ClockFaceWidget {
  const SuperscriptFace(
      {super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final mins = (frame.remainingSeconds ~/ 60).toString();
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaceText(mins, size: h * 0.8, color: palette.ink),
              Padding(
                padding: EdgeInsets.only(left: h * 0.04, top: h * 0.06),
                child: FaceText(frame.ss, size: h * 0.3, color: palette.accent),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Percent of the phase left.
class PercentFace extends ClockFaceWidget {
  const PercentFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final pct = (frame.remainingFraction * 100).ceil().toString();
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DigitSwitcher(
                text: pct,
                child: FaceText(pct, size: h * 0.75, color: palette.ink),
              ),
              Padding(
                padding: EdgeInsets.only(left: h * 0.03, bottom: h * 0.05),
                child: FaceText('%', size: h * 0.3, color: palette.accent),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Clock time at which the phase ends.
class EndTimeFace extends ClockFaceWidget {
  const EndTimeFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final end = DateTime.now().add(Duration(seconds: frame.remainingSeconds));
      final text = '${end.hour.toString().padLeft(2, '0')}:'
          '${end.minute.toString().padLeft(2, '0')}';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaceText(
            frame.labels.ends,
            size: h * 0.13,
            color: palette.accent,
            weight: FontWeight.w600,
          ),
          SizedBox(height: h * 0.06),
          SizedBox(
            width: box.maxWidth,
            child: FitText(text, size: h * 0.55, color: palette.ink),
          ),
        ],
      );
    });
  }
}

/// Remaining time as one big number of seconds.
class SecondsFace extends ClockFaceWidget {
  const SecondsFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final text = frame.remainingSeconds.toString();
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: box.maxWidth,
            child: FitText(text, size: h * 0.62, color: palette.ink),
          ),
          SizedBox(height: h * 0.04),
          FaceText(
            frame.labels.seconds,
            size: h * 0.13,
            color: palette.accent,
            weight: FontWeight.w600,
          ),
        ],
      );
    });
  }
}

/// Digits stretched tall to fill a narrow column.
class TallFace extends ClockFaceWidget {
  const TallFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      Widget line(String t, Color c) => Expanded(
            child: FittedBox(
              fit: BoxFit.fill,
              child: FaceText(t, size: 100, color: c),
            ),
          );
      return Column(children: [
        line(frame.wordMode ? frame.phaseWord : frame.mm, palette.ink),
        SizedBox(height: box.maxHeight * 0.03),
        line(frame.wordMode ? frame.timeText : frame.ss, palette.accent),
      ]);
    });
  }
}

/// Characters bob up and down in a wave.
class WobbleFace extends ClockFaceWidget {
  const WobbleFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final chars = frame.centerText.split('');
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < chars.length; i++)
                Transform.translate(
                  offset: Offset(
                      0, math.sin(frame.time * 3.2 + i * 0.9) * h * 0.09),
                  child: FaceText(
                    chars[i],
                    size: h * 0.6,
                    color: i.isEven ? palette.ink : palette.accent,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Two columns, each number with its own unit label.
class LabeledFace extends ClockFaceWidget {
  const LabeledFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      Widget col(String value, String unit, Color c) => Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: box.maxWidth / 2.3,
                  child: FitText(value, size: h * 0.6, color: c),
                ),
                SizedBox(height: h * 0.04),
                FaceText(
                  unit,
                  size: h * 0.12,
                  color: palette.accent,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          );
      return Row(children: [
        col(frame.mm, frame.labels.minutes, palette.ink),
        col(frame.ss, frame.labels.seconds, palette.ink),
      ]);
    });
  }
}
