import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../alerts.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_services.dart';
import '../notifier.dart';
import '../tool_history.dart';
import 'interval_plan.dart';

enum IntervalStatus { idle, running, paused }

/// The interval trainer. One app-wide instance, driven by absolute
/// timestamps: the current phase and round are *computed* from the elapsed
/// time and the plan, so it keeps exact time while another mode is open and
/// survives the app closing. Pausing shifts the start time on resume.
class IntervalsService extends ChangeNotifier implements ModeService {
  IntervalsService._();
  static final IntervalsService instance = IntervalsService._();

  static const _stateKey = 'intervals_state';
  static const _customKey = 'intervals_custom';
  static const _presetKey = 'intervals_preset';

  /// Below the alarms' range (10000+), above the timer's 9001.
  static const notificationId = 9100;

  /// A workout that ended more than this long ago (app was closed) is logged
  /// but no longer rings.
  static const _staleRing = Duration(minutes: 10);

  IntervalPreset preset = IntervalPreset.tabata;
  IntervalPlan _custom = IntervalPreset.custom.plan;
  IntervalStatus status = IntervalStatus.idle;

  DateTime? _startedAt; // effective start (shifted by pauses); running only
  int _pausedElapsedMs = 0;
  DateTime? _firstStart; // when the user first pressed start (for the log)
  IntervalPlan? _runPlan; // the plan being run (frozen at start)
  int _lastSegment = -1;
  int _lastCountdown = 0;

  IntervalPlan get plan =>
      preset == IntervalPreset.custom ? _custom : preset.plan;

  /// The plan of the current run, or the selected one when idle.
  IntervalPlan get activePlan => _runPlan ?? plan;

  bool get running => status == IntervalStatus.running;

  String get planName => preset.label(currentL10n());

  int get elapsedMs {
    switch (status) {
      case IntervalStatus.idle:
        return 0;
      case IntervalStatus.paused:
        return _pausedElapsedMs;
      case IntervalStatus.running:
        return math.max(
            0, nowProvider().difference(_startedAt!).inMilliseconds);
    }
  }

  /// The timeline position right now (null when idle or finished).
  IntervalSegment? get segment {
    if (status == IntervalStatus.idle) return null;
    final segs = activePlan.segments;
    final i = activePlan.indexAt(segs, elapsedMs);
    return i < 0 ? null : segs[i];
  }

  int get segmentRemainingMs {
    final s = segment;
    return s == null ? 0 : math.max(0, s.endMs - elapsedMs);
  }

  /// Elapsed fraction of the current phase, 0..1.
  double get phaseProgress {
    final s = segment;
    if (s == null) return 0;
    return ((elapsedMs - s.startMs) / s.durationMs).clamp(0.0, 1.0);
  }

  double get overallProgress {
    final total = activePlan.totalMs;
    if (total <= 0) return 0;
    return (elapsedMs / total).clamp(0.0, 1.0);
  }

  // ------------------------------------------------------------- lifecycle

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString(_presetKey);
    preset = IntervalPreset.values.firstWhere(
      (e) => e.name == p,
      orElse: () => IntervalPreset.tabata,
    );
    try {
      final c = prefs.getString(_customKey);
      if (c != null) {
        _custom = IntervalPlan.fromJson(jsonDecode(c) as Map<String, dynamic>);
      }
    } catch (_) {}
    final raw = prefs.getString(_stateKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _runPlan = IntervalPlan.fromJson(j['plan'] as Map<String, dynamic>);
        status = IntervalStatus.values.firstWhere((e) => e.name == j['st']);
        _pausedElapsedMs = j['pe'] as int? ?? 0;
        final s = j['s'] as int?;
        _startedAt = s == null ? null : DateTime.fromMillisecondsSinceEpoch(s);
        final f = j['f'] as int?;
        _firstStart = f == null ? null : DateTime.fromMillisecondsSinceEpoch(f);
        if (status == IntervalStatus.running && _startedAt == null) {
          throw StateError('running without a start');
        }
        // No phase-change buzz for the phase we resume inside.
        _lastSegment = _currentIndex();
      } catch (_) {
        _clearRun();
      }
    }
    notifyListeners();
    check(); // it may have ended while the app was closed
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, preset.name);
    await prefs.setString(_customKey, jsonEncode(_custom.toJson()));
    if (status == IntervalStatus.idle || _runPlan == null) {
      await prefs.remove(_stateKey);
    } else {
      await prefs.setString(
        _stateKey,
        jsonEncode({
          'plan': _runPlan!.toJson(),
          'st': status.name,
          'pe': _pausedElapsedMs,
          if (_startedAt != null) 's': _startedAt!.millisecondsSinceEpoch,
          if (_firstStart != null) 'f': _firstStart!.millisecondsSinceEpoch,
        }),
      );
    }
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  int _currentIndex() {
    final p = activePlan;
    return p.indexAt(p.segments, elapsedMs);
  }

  void _clearRun() {
    status = IntervalStatus.idle;
    _startedAt = null;
    _firstStart = null;
    _runPlan = null;
    _pausedElapsedMs = 0;
    _lastSegment = -1;
    _lastCountdown = 0;
  }

  // -------------------------------------------------------------- editing

  void selectPreset(IntervalPreset p) {
    if (status != IntervalStatus.idle) return;
    preset = p;
    _changed();
  }

  /// Any edit turns the plan into the saved Custom one.
  void edit(IntervalPlan next) {
    if (status != IntervalStatus.idle) return;
    if (next == plan) return;
    _custom = next;
    preset = IntervalPreset.custom;
    _changed();
  }

  // -------------------------------------------------------------- control

  void start() {
    final now = nowProvider();
    if (status == IntervalStatus.idle) {
      if (!plan.isValid) return;
      _runPlan = plan;
      _firstStart = now;
      _startedAt = now;
      _pausedElapsedMs = 0;
      _lastSegment = -1;
      Haptics.confirm();
    } else if (status == IntervalStatus.paused) {
      _startedAt = now.subtract(Duration(milliseconds: _pausedElapsedMs));
      Haptics.tap();
    } else {
      return;
    }
    _lastCountdown = 0;
    status = IntervalStatus.running;
    _scheduleEnd();
    _changed();
    check(); // announce the first phase right away
  }

  void pause() {
    if (!running) return;
    Haptics.tap();
    _pausedElapsedMs = elapsedMs;
    _startedAt = null;
    status = IntervalStatus.paused;
    _lastCountdown = 0;
    Notifier.cancel(notificationId);
    _changed();
  }

  void toggle() => running ? pause() : start();

  /// Jump to the start of the next phase (finishes the workout on the last).
  void skip() {
    if (status == IntervalStatus.idle) return;
    final s = segment;
    if (s == null) return;
    Haptics.select();
    final shift = s.endMs - elapsedMs;
    if (running) {
      _startedAt = _startedAt!.subtract(Duration(milliseconds: shift));
      _scheduleEnd();
    } else {
      _pausedElapsedMs += shift;
    }
    _lastCountdown = 0;
    _changed();
    check();
  }

  /// Stop and go back to the editor. A run that got somewhere is logged as
  /// not completed.
  void reset() {
    if (status == IntervalStatus.idle) return;
    Haptics.warning();
    final ran = (elapsedMs / 1000).floor();
    if (ran >= 5 && _firstStart != null) {
      _log(completed: false, seconds: ran);
    }
    Notifier.cancel(notificationId);
    _clearRun();
    _changed();
  }

  /// Back to factory state, in memory (after preferences were erased).
  void wipe() {
    Notifier.cancel(notificationId);
    _clearRun();
    preset = IntervalPreset.tabata;
    _custom = IntervalPreset.custom.plan;
    notifyListeners();
  }

  // -------------------------------------------------------------- ticking

  @override
  void check() {
    if (!running) return;
    final p = _runPlan!;
    final segs = p.segments;
    final elapsed = elapsedMs;
    final i = p.indexAt(segs, elapsed);
    if (i < 0) {
      _finish(overrunMs: elapsed - p.totalMs);
      return;
    }
    if (i != _lastSegment) {
      final first = _lastSegment == -1;
      _lastSegment = i;
      _lastCountdown = 0;
      _announce(segs[i], first: first);
      notifyListeners();
    }
    // The last three seconds of a phase tick, firming up.
    final left = segs[i].endMs - elapsed;
    final secs = (left / 1000).ceil();
    if (secs > 3 || segs[i].durationMs <= 3000) {
      _lastCountdown = 0;
    } else if (secs != _lastCountdown) {
      _lastCountdown = secs;
      Haptics.countdown(secs);
      _sound(SystemSoundType.click);
    }
  }

  void _announce(IntervalSegment s, {required bool first}) {
    switch (s.kind) {
      case IntervalKind.work:
        Haptics.go();
      case IntervalKind.rest:
        Haptics.phaseComplete(toRest: true);
      case IntervalKind.warmUp:
      case IntervalKind.coolDown:
        if (!first) Haptics.transition();
    }
    _sound(SystemSoundType.alert);
  }

  void _sound(SystemSoundType type) {
    try {
      SystemSound.play(type).catchError((_) {});
    } catch (_) {}
  }

  void _finish({int overrunMs = 0}) {
    final p = _runPlan!;
    _log(completed: true, seconds: p.totalSeconds);
    Notifier.cancel(notificationId);
    _clearRun();
    _changed();

    if (overrunMs > _staleRing.inMilliseconds) return;
    final l10n = currentL10n();
    final title = l10n.intervalsDoneTitle;
    final body = l10n.intervalsDoneBody(
      planName,
      formatDuration(p.totalSeconds),
    );
    Notifier.show(id: notificationId, title: title, body: body);
    Alerts.ring(RingRequest(
      title: title,
      subtitle: body,
      icon: Icons.fitness_center_rounded,
      timer: true,
      onDismiss: () {},
    ));
  }

  void _log({required bool completed, required int seconds}) {
    ToolHistory.add(ToolEvent(
      kind: ToolKind.intervals,
      at: _firstStart ?? nowProvider(),
      seconds: seconds,
      planned: (_runPlan ?? plan).totalSeconds,
      completed: completed,
      label: planName,
    ));
  }

  void _scheduleEnd() {
    final p = _runPlan;
    if (p == null || _startedAt == null) return;
    final l10n = currentL10n();
    Notifier.schedule(
      id: notificationId,
      at: _startedAt!.add(Duration(milliseconds: p.totalMs)),
      title: l10n.intervalsDoneTitle,
      body: l10n.intervalsDoneBody(planName, formatDuration(p.totalSeconds)),
    );
  }
}
