import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The four beats of one breath. A pattern may skip either hold (length 0).
enum BreathePhase { inhale, holdFull, exhale, holdEmpty }

/// A breathing rhythm: seconds of inhale, hold (lungs full), exhale and hold
/// (lungs empty).
class BreathePattern {
  const BreathePattern(
      this.id, this.inhale, this.holdFull, this.exhale, this.holdEmpty);

  final String id;
  final int inhale;
  final int holdFull;
  final int exhale;
  final int holdEmpty;

  static const box = BreathePattern('box', 4, 4, 4, 4);
  static const relax478 = BreathePattern('478', 4, 7, 8, 0);
  static const coherent = BreathePattern('coherent', 5, 0, 5, 0);
  static const calm = BreathePattern('calm', 4, 0, 6, 0);
  static const custom = BreathePattern('custom', 4, 4, 6, 2);

  static const presets = [box, relax478, coherent, calm];

  static BreathePattern byId(String? id) => switch (id) {
        'box' => box,
        '478' => relax478,
        'coherent' => coherent,
        'calm' => calm,
        'custom' => custom,
        _ => box,
      };

  /// The same rhythm with other timings (used by the custom pattern).
  BreathePattern copyWith(
          {int? inhale, int? holdFull, int? exhale, int? holdEmpty}) =>
      BreathePattern(id, inhale ?? this.inhale, holdFull ?? this.holdFull,
          exhale ?? this.exhale, holdEmpty ?? this.holdEmpty);

  int lengthOf(BreathePhase phase) => switch (phase) {
        BreathePhase.inhale => inhale,
        BreathePhase.holdFull => holdFull,
        BreathePhase.exhale => exhale,
        BreathePhase.holdEmpty => holdEmpty,
      };

  /// `4-7-8`, `4-4-4-4`: the non-zero beats, in order.
  String get timings =>
      [inhale, holdFull, exhale, holdEmpty].where((n) => n > 0).join('-');

  /// Seconds for one whole breath.
  int get cycleSeconds => inhale + holdFull + exhale + holdEmpty;

  @override
  bool operator ==(Object other) =>
      other is BreathePattern &&
      other.id == id &&
      other.inhale == inhale &&
      other.holdFull == holdFull &&
      other.exhale == exhale &&
      other.holdEmpty == holdEmpty;

  @override
  int get hashCode => Object.hash(id, inhale, holdFull, exhale, holdEmpty);
}

/// Where a session is at one instant.
class BreathePoint {
  const BreathePoint({
    required this.phase,
    required this.breath,
    required this.phaseElapsedMs,
    required this.phaseLengthMs,
    required this.fill,
  });

  final BreathePhase phase;

  /// Which breath (0-based).
  final int breath;
  final int phaseElapsedMs;
  final int phaseLengthMs;

  /// How full the lungs are, 0..1 (drives the shape).
  final double fill;

  /// Whole seconds left in this phase, counting down (4, 3, 2, 1).
  int get secondsLeft =>
      math.max(1, ((phaseLengthMs - phaseElapsedMs) / 1000).ceil());

  @override
  bool operator ==(Object other) =>
      other is BreathePoint &&
      other.phase == phase &&
      other.breath == breath &&
      other.phaseElapsedMs == phaseElapsedMs &&
      other.fill == fill;

  @override
  int get hashCode => Object.hash(phase, breath, phaseElapsedMs, fill);
}

/// Pure phase computation: the point of [pattern] [elapsedMs] after the
/// session started. Timestamp-driven, so it is exact however often (or
/// rarely) it is asked.
BreathePoint breatheAt(BreathePattern pattern, int elapsedMs) {
  final cycleMs = pattern.cycleSeconds * 1000;
  if (cycleMs <= 0) {
    return const BreathePoint(
      phase: BreathePhase.inhale,
      breath: 0,
      phaseElapsedMs: 0,
      phaseLengthMs: 1000,
      fill: 0,
    );
  }
  final t = math.max(0, elapsedMs);
  final breath = t ~/ cycleMs;
  var within = t % cycleMs;
  for (final phase in BreathePhase.values) {
    final len = pattern.lengthOf(phase) * 1000;
    if (len == 0) continue;
    if (within < len) {
      final f = within / len;
      final fill = switch (phase) {
        BreathePhase.inhale => Curves.easeInOutSine.transform(f),
        BreathePhase.holdFull => 1.0,
        BreathePhase.exhale => 1 - Curves.easeInOutSine.transform(f),
        BreathePhase.holdEmpty => 0.0,
      };
      return BreathePoint(
        phase: phase,
        breath: breath,
        phaseElapsedMs: within,
        phaseLengthMs: len,
        fill: fill,
      );
    }
    within -= len;
  }
  // Unreachable (within < cycleMs), but keep the compiler honest.
  return BreathePoint(
    phase: BreathePhase.holdEmpty,
    breath: breath,
    phaseElapsedMs: 0,
    phaseLengthMs: 1000,
    fill: 0,
  );
}

enum BreatheState { idle, running, paused, done }

/// One guided session. All time comes from the [now] the caller passes
/// (normally `nowProvider()`), never from a counter.
class BreatheSession {
  BreatheSession({required this.pattern, required this.plannedSeconds});

  final BreathePattern pattern;

  /// Null for an endless session.
  final int? plannedSeconds;

  BreatheState state = BreatheState.idle;
  DateTime? _startedAt;
  DateTime? _lastResume;
  int _bankedMs = 0;

  /// When the first start happened (for the history entry).
  DateTime? get startedAt => _startedAt;

  int elapsedMs(DateTime now) {
    var ms = _bankedMs;
    if (state == BreatheState.running && _lastResume != null) {
      ms += now.difference(_lastResume!).inMilliseconds;
    }
    final cap = plannedSeconds == null ? null : plannedSeconds! * 1000;
    return cap == null ? ms : math.min(ms, cap);
  }

  bool finishedAt(DateTime now) =>
      plannedSeconds != null && elapsedMs(now) >= plannedSeconds! * 1000;

  double progress(DateTime now) => plannedSeconds == null
      ? 0
      : (elapsedMs(now) / (plannedSeconds! * 1000)).clamp(0.0, 1.0);

  int remainingSeconds(DateTime now) => plannedSeconds == null
      ? 0
      : math.max(0, ((plannedSeconds! * 1000 - elapsedMs(now)) / 1000).ceil());

  BreathePoint pointAt(DateTime now) => breatheAt(pattern, elapsedMs(now));

  void start(DateTime now) {
    if (state == BreatheState.running) return;
    _startedAt ??= now;
    _lastResume = now;
    state = BreatheState.running;
  }

  void pause(DateTime now) {
    if (state != BreatheState.running) return;
    _bankedMs = elapsedMs(now);
    _lastResume = null;
    state = BreatheState.paused;
  }

  /// Marks the session done if the plan has run out; true on that change.
  bool completeIfDue(DateTime now) {
    if (state == BreatheState.running && finishedAt(now)) {
      _bankedMs = plannedSeconds! * 1000;
      _lastResume = null;
      state = BreatheState.done;
      return true;
    }
    return false;
  }
}
