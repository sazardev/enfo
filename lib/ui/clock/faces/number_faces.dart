import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/motion.dart';
import '../clock_frame.dart';
import '../paint_utils.dart';

/// Digit swap: the new value rises in from below while the old one fades.
Widget _digitTransition(Widget child, Animation<double> animation) {
  final slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: slide, child: child),
  );
}

class DigitSwitcher extends StatelessWidget {
  const DigitSwitcher({
    super.key,
    required this.text,
    required this.child,
    this.flip = false,
  });

  final String text;
  final Widget child;

  /// Flip like a split-flap tile (squash on the Y axis) instead of sliding.
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.medium,
      transitionBuilder: flip ? _flipTransition : _digitTransition,
      child: KeyedSubtree(key: ValueKey(text), child: child),
    );
  }
}

Widget _flipTransition(Widget child, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        1,
        Curves.easeOut.transform(animation.value).clamp(0.02, 1.0),
        1,
      ),
      child: child,
    ),
  );
}

/// Just big mm:ss, with a breathing colon and a small phase caption.
class DigitsFace extends ClockFaceWidget {
  const DigitsFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final blink = frame.running
          ? 0.3 + 0.7 * (0.5 + 0.5 * math.cos(frame.time * 2 * math.pi))
          : 1.0;
      final size = h * 0.55;
      final main = frame.wordMode
          ? FaceText(frame.phaseWord, size: size, color: palette.ink)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaceText(frame.mm, size: size, color: palette.ink),
                Opacity(
                  opacity: blink,
                  child: FaceText(':', size: size, color: palette.accent),
                ),
                FaceText(frame.ss, size: size, color: palette.ink),
              ],
            );
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: box.maxWidth,
            child: FittedBox(fit: BoxFit.scaleDown, child: main),
          ),
          SizedBox(height: h * 0.05),
          FaceText(
            frame.caption,
            size: h * 0.1,
            color: palette.accent,
            weight: FontWeight.w600,
          ),
        ],
      );
    });
  }
}

/// Only the minutes left, huge. Switches to seconds in the last minute.
class MinutesFace extends ClockFaceWidget {
  const MinutesFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      final secs = frame.remainingSeconds;
      final inLastMinute = secs < 60;
      final value = inLastMinute ? secs : (secs / 60).ceil();
      final unit = inLastMinute ? frame.labels.seconds : frame.labels.minutes;
      final text = value.toString();
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: s * 0.95,
            height: s * 0.6,
            child: DigitSwitcher(
              text: text,
              child: FitText(text, size: s * 0.6, color: palette.ink),
            ),
          ),
          SizedBox(height: s * 0.03),
          FaceText(
            frame.paused || frame.wordMode ? frame.caption : unit,
            size: s * 0.11,
            color: palette.accent,
            weight: FontWeight.w600,
          ),
        ],
      );
    });
  }
}

/// Rounded tonal tiles, one per number group, flipping on change.
class TilesFace extends ClockFaceWidget {
  const TilesFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      final radius = BorderRadius.circular(h * 0.24);
      Widget tile(String text, Color bg, Color fg) => Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Center(
                child: ClipRect(
                  child: Padding(
                    padding: EdgeInsets.all(h * 0.1),
                    child: DigitSwitcher(
                      text: text,
                      child: FitText(text, size: h * 0.6, color: fg),
                    ),
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

/// Minutes stacked over seconds, oversized.
class StackFace extends ClockFaceWidget {
  const StackFace({super.key, required super.frame, required super.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = box.biggest.shortestSide;
      final top = frame.wordMode ? frame.phaseWord : frame.mm;
      final bottom = frame.wordMode ? frame.timeText : frame.ss;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: s,
            child: FitText(top, size: s * 0.46, color: palette.ink),
          ),
          SizedBox(height: s * 0.02),
          SizedBox(
            width: s,
            child: FitText(bottom, size: s * 0.46, color: palette.accent),
          ),
        ],
      );
    });
  }
}
