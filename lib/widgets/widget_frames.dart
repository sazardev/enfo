import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui/clock/clock_frame.dart';
import '../ui/clock/clock_style.dart';
import '../ui/clock/clock_view.dart';
import 'offscreen_render.dart';
import 'widget_bridge.dart';

/// One rendered timeline of a face widget: pictures of the chosen clock
/// style at successive instants, in a light and a dark palette. The native
/// side shows whichever frame matches the wall clock, so a running timer
/// keeps moving on the home screen with the app closed.
class FrameSet {
  const FrameSet({
    required this.kind,
    required this.prefix,
    required this.dir,
    required this.width,
    required this.height,
    required this.times,
  });

  final WidgetKind kind;

  /// File name stem; frames are `<prefix>_l_<i>.png` and `<prefix>_d_<i>.png`.
  final String prefix;
  final String dir;
  final int width;
  final int height;

  /// Wall-clock ms at which frame `i` becomes the one to show.
  final List<int> times;

  Map<String, Object?> toJson() => {
        'prefix': prefix,
        'dir': dir,
        'w': width,
        'h': height,
        'times': times,
      };
}

/// The instants worth drawing for a countdown.
class FramePlan {
  const FramePlan(this.times, this.progress);

  final List<int> times;

  /// Elapsed fraction (0..1) at each instant.
  final List<double> progress;

  /// A running countdown gets at most this many pictures: enough that the
  /// ring visibly advances, few enough to render in about a second.
  static const maxFrames = 30;

  static FramePlan of({
    required int nowMs,
    required bool running,
    required int totalSeconds,
    required int remainingMs,
  }) {
    final total = math.max(1, totalSeconds) * 1000;
    double at(int remaining) => (1 - remaining / total).clamp(0.0, 1.0);

    if (!running || remainingMs <= 0) {
      return FramePlan([nowMs], [at(remainingMs)]);
    }

    // Whole-second steps, so number faces land on clean values.
    final stepMs = math.max(
      1000,
      ((remainingMs / (maxFrames - 1)) / 1000).ceil() * 1000,
    );
    final times = <int>[];
    final progress = <double>[];
    for (var t = 0; t < remainingMs; t += stepMs) {
      times.add(nowMs + t);
      progress.add(at(remainingMs - t));
    }
    // The last picture is the finished state, at the exact end.
    times.add(nowMs + remainingMs);
    progress.add(1);
    return FramePlan(times, progress);
  }
}

class WidgetFrames {
  const WidgetFrames._();

  /// Long side of the picture in logical pixels (drawn at 2x). Big enough to
  /// stay crisp in a 4x2 widget, small enough for the launcher's bitmap
  /// budget (two variants of ~0.7 MB each).
  static const _longSide = 210.0;
  static const _ratio = 2.0;

  static Size sizeFor(ClockStyle style) {
    final a = style.aspectRatio;
    return a >= 1
        ? Size(_longSide, (_longSide / a).roundToDouble())
        : Size((_longSide * a).roundToDouble(), _longSide);
  }

  /// Renders the timeline for [kind]. Returns null when it could not (no
  /// view, or [isCurrent] said a newer request superseded this one).
  static Future<FrameSet?> render({
    required WidgetKind kind,
    required String dir,
    required ClockStyle style,
    required bool rest,
    required ClockPhase phase,
    required int totalSeconds,
    required int remainingMs,
    required int nowMs,
    required ColorScheme light,
    required ColorScheme dark,
    required ClockLabels labels,
    required bool Function() isCurrent,
  }) async {
    final plan = FramePlan.of(
      nowMs: nowMs,
      running: phase == ClockPhase.running,
      totalSeconds: totalSeconds,
      remainingMs: remainingMs,
    );
    final size = sizeFor(style);
    final prefix = '${kind.name}_$nowMs';
    await Directory(dir).create(recursive: true);

    for (var i = 0; i < plan.times.length; i++) {
      final frame = ClockFrame(
        progress: plan.progress[i],
        totalSeconds: totalSeconds,
        isRest: rest,
        phase: phase,
        // Ambient motion advances with the timeline, like the running app.
        time: (plan.times[i] - nowMs) / 1000,
        labels: labels,
      );
      for (final variant in const ['l', 'd']) {
        if (!isCurrent()) return null;
        final scheme = variant == 'l' ? light : dark;
        final bytes = await OffscreenRenderer.png(
          ClockView(
            style: style,
            frame: frame,
            fill: 0.94,
            palette: ClockPalette.of(
              scheme,
              rest: rest,
              paused: phase == ClockPhase.paused,
            ),
          ),
          size: size,
          pixelRatio: _ratio,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            fontFamily: Themes.fontFamily,
          ),
        );
        if (bytes == null) return null;
        await File('$dir/${prefix}_${variant}_$i.png').writeAsBytes(bytes);
      }
      // Let the UI breathe between pictures.
      await Future<void>.delayed(Duration.zero);
    }

    return FrameSet(
      kind: kind,
      prefix: prefix,
      dir: dir,
      width: (size.width * _ratio).round(),
      height: (size.height * _ratio).round(),
      times: plan.times,
    );
  }

  /// Deletes every picture of [kind] except those of [keep].
  static Future<void> prune(String dir, WidgetKind kind, String? keep) async {
    final directory = Directory(dir);
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      final name = entity.uri.pathSegments.last;
      if (!name.startsWith('${kind.name}_')) continue;
      if (keep != null && name.startsWith('${keep}_')) continue;
      try {
        await entity.delete();
      } on FileSystemException {
        // Native may be reading it; the next prune gets it.
      }
    }
  }
}
