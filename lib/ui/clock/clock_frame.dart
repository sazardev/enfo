import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

enum ClockPhase { idle, running, paused }

/// Localized words faces may show. Defaults are English so faces can render
/// without a localization context (tests, previews).
@immutable
class ClockLabels {
  const ClockLabels({
    this.focus = 'Focus',
    this.relax = 'Relax',
    this.paused = 'Paused',
    this.minutes = 'min',
    this.seconds = 'sec',
    this.ends = 'Ends',
  });

  factory ClockLabels.of(AppLocalizations l10n) => ClockLabels(
        focus: l10n.phaseFocus,
        relax: l10n.phaseRelax,
        paused: l10n.phasePaused,
        minutes: l10n.clockUnitMinutes,
        seconds: l10n.clockUnitSeconds,
        ends: l10n.clockEndsAt,
      );

  final String focus;
  final String relax;
  final String paused;
  final String minutes;
  final String seconds;
  final String ends;
}

/// Everything a clock face needs to draw one instant of the countdown. Faces
/// are pure functions of a frame + palette, so the same widget renders the
/// live timer and the animated previews in the style picker.
@immutable
class ClockFrame {
  const ClockFrame({
    required this.progress,
    required this.totalSeconds,
    this.isRest = false,
    this.phase = ClockPhase.running,
    this.wordMode = false,
    this.time = 0,
    this.labels = const ClockLabels(),
  });

  /// Elapsed fraction of the current phase, 0..1.
  final double progress;
  final int totalSeconds;
  final bool isRest;
  final ClockPhase phase;

  /// Show "Focus"/"Relax" instead of mm:ss where a face has a main label.
  final bool wordMode;

  /// Monotonic ambient-animation clock in seconds. Only advances while the
  /// timer runs, so waves/rotations freeze on pause.
  final double time;
  final ClockLabels labels;

  bool get running => phase == ClockPhase.running;
  bool get paused => phase == ClockPhase.paused;

  double get p => progress.clamp(0.0, 1.0);
  double get remainingFraction => 1 - p;
  double get remainingExact => totalSeconds * remainingFraction;
  int get remainingSeconds => remainingExact.ceil().clamp(0, totalSeconds);

  /// Seconds left in the current minute, as a 0..1 fraction (smooth).
  double get minuteFraction => (remainingExact % 60) / 60;

  String get mm => (remainingSeconds ~/ 60).toString().padLeft(2, '0');
  String get ss => (remainingSeconds % 60).toString().padLeft(2, '0');
  String get timeText => '$mm:$ss';
  String get phaseWord => isRest ? labels.relax : labels.focus;

  /// Main readout: mm:ss, or the phase word in word mode.
  String get centerText => wordMode ? phaseWord : timeText;

  /// Readout for ring-style faces, which (like the original dial) say
  /// "Paused" in their center while paused.
  String get ringText => paused ? labels.paused : centerText;

  /// Small line under number-only readouts.
  String get caption =>
      paused ? labels.paused : (wordMode ? timeText : phaseWord);

  ClockFrame copyWith({double? time}) => ClockFrame(
        progress: progress,
        totalSeconds: totalSeconds,
        isRest: isRest,
        phase: phase,
        wordMode: wordMode,
        time: time ?? this.time,
        labels: labels,
      );
}

/// Flat Material 3 colors for a face. Work uses the primary tonal set, rest
/// switches to tertiary so the phase change is visible at a glance.
@immutable
class ClockPalette {
  const ClockPalette({
    required this.accent,
    required this.onAccent,
    required this.container,
    required this.onContainer,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.track,
    required this.alert,
  });

  factory ClockPalette.of(
    ColorScheme cs, {
    required bool rest,
    required bool paused,
  }) {
    final accent = rest ? cs.tertiary : cs.primary;
    return ClockPalette(
      accent: accent,
      onAccent: rest ? cs.onTertiary : cs.onPrimary,
      container: rest ? cs.tertiaryContainer : cs.primaryContainer,
      onContainer: rest ? cs.onTertiaryContainer : cs.onPrimaryContainer,
      surface: cs.surfaceContainerHigh,
      ink: paused ? cs.onSurfaceVariant : cs.onSurface,
      muted: cs.onSurfaceVariant,
      track: accent.withValues(alpha: 0.14),
      alert: cs.error,
    );
  }

  final Color accent;
  final Color onAccent;
  final Color container;
  final Color onContainer;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color track;
  final Color alert;
}

/// Base class so every face shares the same two inputs.
abstract class ClockFaceWidget extends StatelessWidget {
  const ClockFaceWidget({
    super.key,
    required this.frame,
    required this.palette,
  });

  final ClockFrame frame;
  final ClockPalette palette;
}
