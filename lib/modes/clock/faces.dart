import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app_preferences.dart';
import '../format.dart';
import '../../l10n/locale_controller.dart';
import 'clock_prefs.dart';

/// What every face needs to draw one instant.
class FaceData {
  const FaceData({
    required this.now,
    required this.use24h,
    required this.showSeconds,
    required this.showDate,
    required this.blinkColon,
    required this.dateText,
    this.compact = false,
  });

  final DateTime now;
  final bool use24h;
  final bool showSeconds;
  final bool showDate;
  final bool blinkColon;
  final String dateText;

  /// Miniature (settings previews): no date / seconds text.
  final bool compact;

  int get hour12 => now.hour % 12 == 0 ? 12 : now.hour % 12;
  String get hourText => use24h ? two(now.hour) : '$hour12';
  String get minuteText => two(now.minute);
  String get secondText => two(now.second);
  String get suffix => use24h ? '' : (now.hour < 12 ? 'AM' : 'PM');

  /// Colon color: dimmed on odd seconds when blinking.
  bool get colonOn => !blinkColon || now.second.isEven;

  /// Fraction of the day elapsed, 0..1.
  double get dayFraction =>
      (now.hour * 3600 + now.minute * 60 + now.second) / 86400;

  factory FaceData.of(
    BuildContext context,
    DateTime now, {
    bool compact = false,
    bool? showSeconds,
    bool? showDate,
  }) {
    final use24h = switch (AppPreferences.clockFormat.value) {
      ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };
    final locale = Localizations.localeOf(context).toString();
    return FaceData(
      now: now,
      use24h: use24h,
      showSeconds: !compact && (showSeconds ?? ClockPrefs.showSeconds.value),
      showDate: !compact && (showDate ?? ClockPrefs.showDate.value),
      blinkColon: ClockPrefs.blinkColon.value,
      dateText: DateFormat.MMMMEEEEd(locale).format(now),
      compact: compact,
    );
  }
}

/// Draws [face] for [data], filling whatever box it is given.
class ClockFaceView extends StatelessWidget {
  const ClockFaceView({super.key, required this.face, required this.data});

  final ClockFace face;
  final FaceData data;

  @override
  Widget build(BuildContext context) => switch (face) {
        ClockFace.ring => _RingFace(data: data),
        ClockFace.digital => _DigitalFace(data: data),
        ClockFace.analog => _AnalogFace(data: data),
        ClockFace.split => _SplitFace(data: data),
        ClockFace.day => _DayFace(data: data),
      };
}

TextStyle _digits(BuildContext context, {Color? color, double size = 200}) =>
    (Theme.of(context).textTheme.displayLarge ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: -size * 0.03,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );

/// "HH:MM" with a coloured (optionally blinking) colon. Monospaced, so the
/// blink never shifts the layout.
Widget _timeText(BuildContext context, FaceData d, {double size = 200}) {
  final scheme = Theme.of(context).colorScheme;
  final style = _digits(context, size: size);
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        TextSpan(text: d.hourText),
        TextSpan(
          text: ':',
          style: style.copyWith(
            color: scheme.primary.withValues(alpha: d.colonOn ? 1 : 0.2),
          ),
        ),
        TextSpan(text: d.minuteText),
      ],
    ),
    maxLines: 1,
    textScaler: TextScaler.noScaling,
  );
}

Widget _small(BuildContext context, String text,
    {Color? color, double size = 44}) {
  final scheme = Theme.of(context).colorScheme;
  return Text(
    text,
    maxLines: 1,
    textScaler: TextScaler.noScaling,
    style:
        (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? scheme.onSurfaceVariant,
    ),
  );
}

// ---------------------------------------------------------------- digital

class _DigitalFace extends StatelessWidget {
  const _DigitalFace({required this.data});

  final FaceData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _timeText(context, data),
                if (data.showSeconds || data.suffix.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.suffix.isNotEmpty && !data.compact)
                          _small(context, data.suffix),
                        if (data.showSeconds)
                          _small(
                            context,
                            data.secondText,
                            color: scheme.primary,
                            size: 72,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (data.showDate) ...[
              const SizedBox(height: 8),
              _small(context, data.dateText),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ split

class _SplitFace extends StatelessWidget {
  const _SplitFace({required this.data});

  final FaceData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget block(String text, Color color) => FittedBox(
          fit: BoxFit.contain,
          child: Text(
            text,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: _digits(context, color: color, size: 400),
          ),
        );

    final info = <String>[
      if (data.showSeconds) data.secondText,
      if (data.suffix.isNotEmpty && !data.compact) data.suffix,
      if (data.showDate) data.dateText,
    ].join('   ·   ');

    return LayoutBuilder(builder: (context, c) {
      final landscape = c.maxWidth > c.maxHeight * 1.15;
      final hours = block(data.hourText, scheme.onSurface);
      final minutes = block(data.minuteText, scheme.primary);
      return Column(
        children: [
          Expanded(
            child: landscape
                ? Row(children: [
                    Expanded(child: hours),
                    const SizedBox(width: 24),
                    Expanded(child: minutes),
                  ])
                : Column(children: [
                    Expanded(child: hours),
                    Expanded(child: minutes),
                  ]),
          ),
          if (info.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _small(context, info, size: 28),
              ),
            ),
        ],
      );
    });
  }
}

// -------------------------------------------------------------------- day

class _DayFace extends StatelessWidget {
  const _DayFace({required this.data});

  final FaceData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (data.dayFraction * 100).floor();

    return LayoutBuilder(builder: (context, c) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(c.maxWidth, 900)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _timeText(context, data),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: scheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: data.dayFraction.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: ColoredBox(color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!data.compact) ...[
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _small(
                    context,
                    [
                      context.l10n.clockDayPercent(percent),
                      if (data.showDate) data.dateText,
                    ].join('   ·   '),
                    size: 28,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// ------------------------------------------------------------------- ring

class _RingFace extends StatelessWidget {
  const _RingFace({required this.data});

  final FaceData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondsMode = data.showSeconds || data.compact;
    // Progress around the ring: seconds if shown, else minutes.
    final fraction = secondsMode
        ? (data.now.second + data.now.millisecond / 1000) / 60
        : data.now.minute / 60 + data.now.second / 3600;

    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, c.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: CustomPaint(
            painter: TickRingPainter(
              fraction: fraction.clamp(0.0, 1.0),
              lit: scheme.primary,
              dim: scheme.onSurface.withValues(alpha: 0.12),
            ),
            child: Center(
              child: SizedBox(
                width: side * 0.66,
                height: side * 0.5,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _timeText(context, data),
                      if (data.suffix.isNotEmpty && !data.compact)
                        _small(context, data.suffix, size: 44),
                      if (data.showDate) ...[
                        const SizedBox(height: 10),
                        _small(context, data.dateText, size: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// 60 rounded ticks around a circle that light up as [fraction] fills.
class TickRingPainter extends CustomPainter {
  TickRingPainter({
    required this.fraction,
    required this.lit,
    required this.dim,
  });

  final double fraction;
  final Color lit;
  final Color dim;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.032;

    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + i / 60 * 2 * math.pi;
      final major = i % 5 == 0;
      final inner = r * (major ? 0.84 : 0.88);
      final outer = r * 0.97;
      // Ticks light up as the ring fills; the leading one fades in.
      final progress = fraction * 60 - i;
      paint.color = progress >= 1
          ? lit
          : progress > 0
              ? Color.lerp(dim, lit, progress)!
              : dim;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TickRingPainter old) =>
      old.fraction != fraction || old.lit != lit || old.dim != dim;
}

// ----------------------------------------------------------------- analog

class _AnalogFace extends StatelessWidget {
  const _AnalogFace({required this.data});

  final FaceData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, c.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: CustomPaint(
            painter: _AnalogPainter(
              now: data.now,
              showSeconds: data.showSeconds || data.compact,
              dayNumber: data.showDate ? data.now.day : null,
              face: scheme.surfaceContainerHigh,
              ink: scheme.onSurface,
              muted: scheme.onSurface.withValues(alpha: 0.28),
              accent: scheme.primary,
              textStyle: _digits(context, size: 20)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    });
  }
}

class _AnalogPainter extends CustomPainter {
  _AnalogPainter({
    required this.now,
    required this.showSeconds,
    required this.dayNumber,
    required this.face,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.textStyle,
  });

  final DateTime now;
  final bool showSeconds;
  final int? dayNumber;
  final Color face;
  final Color ink;
  final Color muted;
  final Color accent;
  final TextStyle textStyle;

  Offset _at(Offset c, double angle, double len) =>
      c + Offset(math.sin(angle), -math.cos(angle)) * len;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(c, r, Paint()..color = face);

    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * 2 * math.pi;
      final major = i % 5 == 0;
      tick
        ..color = major ? ink : muted
        ..strokeWidth = r * (major ? 0.034 : 0.014);
      canvas.drawLine(
        _at(c, a, r * (major ? 0.80 : 0.87)),
        _at(c, a, r * 0.94),
        tick,
      );
    }

    // Day-of-month window at 3 o'clock.
    if (dayNumber != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$dayNumber',
          style: textStyle.copyWith(fontSize: r * 0.12),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      final w = tp.width + r * 0.09;
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(r * 0.52, 0),
          width: w,
          height: r * 0.18,
        ),
        Radius.circular(r * 0.04),
      );
      canvas.drawRRect(box, Paint()..color = muted.withValues(alpha: 0.18));
      tp.paint(canvas, box.center - Offset(tp.width / 2, tp.height / 2));
    }

    final sec = now.second + now.millisecond / 1000;
    final min = now.minute + sec / 60;
    final hour = (now.hour % 12) + min / 60;

    final hand = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c,
      _at(c, hour / 12 * 2 * math.pi, r * 0.5),
      hand
        ..color = ink
        ..strokeWidth = r * 0.06,
    );
    canvas.drawLine(
      c,
      _at(c, min / 60 * 2 * math.pi, r * 0.76),
      hand
        ..color = ink
        ..strokeWidth = r * 0.04,
    );

    if (showSeconds) {
      final a = sec / 60 * 2 * math.pi;
      canvas.drawLine(
        _at(c, a + math.pi, r * 0.16),
        _at(c, a, r * 0.86),
        hand
          ..color = accent
          ..strokeWidth = r * 0.018,
      );
    }
    canvas.drawCircle(c, r * 0.055, Paint()..color = accent);
    canvas.drawCircle(c, r * 0.02, Paint()..color = face);
  }

  @override
  bool shouldRepaint(_AnalogPainter old) =>
      old.now != now ||
      old.showSeconds != showSeconds ||
      old.dayNumber != dayNumber ||
      old.accent != accent ||
      old.face != face;
}
