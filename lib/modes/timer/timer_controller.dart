import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/locale_controller.dart';
import '../alerts.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../notifier.dart';
import '../tool_history.dart';

enum TimerPhase { idle, running, paused }

/// The countdown timer. A single app-wide instance, driven by absolute
/// timestamps rather than a ticking counter, so it keeps exact time while
/// you use other modes, and survives the app being closed.
class TimerController extends ChangeNotifier {
  TimerController._();
  static final TimerController instance = TimerController._();

  static const _stateKey = 'timer_state';
  static const presetsKey = 'timer_presets';
  static const _notificationId = 9001;
  static const defaultPresets = [60, 180, 300, 600, 900, 1800];
  static const maxSeconds = 99 * 3600 + 59 * 60 + 59;

  int totalSeconds = 300;
  TimerPhase phase = TimerPhase.idle;
  List<int> presets = List.of(defaultPresets);

  DateTime? _endsAt;
  int _pausedRemainingMs = 0;
  DateTime? _startedAt;

  bool get running => phase == TimerPhase.running;

  int get remainingMs {
    switch (phase) {
      case TimerPhase.idle:
        return totalSeconds * 1000;
      case TimerPhase.paused:
        return _pausedRemainingMs;
      case TimerPhase.running:
        return math.max(0, _endsAt!.difference(nowProvider()).inMilliseconds);
    }
  }

  /// Elapsed fraction, 0..1 (what the clock faces draw).
  double get progress {
    if (totalSeconds <= 0) return 0;
    return (1 - remainingMs / (totalSeconds * 1000)).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPresets = prefs.getStringList(presetsKey);
    if (storedPresets != null) {
      presets = storedPresets.map(int.tryParse).whereType<int>().toList();
    }
    final raw = prefs.getString(_stateKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        totalSeconds = (json['t'] as int).clamp(1, maxSeconds);
        phase = TimerPhase.values.firstWhere((p) => p.name == json['p']);
        _pausedRemainingMs = json['r'] as int? ?? 0;
        final ends = json['e'] as int?;
        _endsAt =
            ends == null ? null : DateTime.fromMillisecondsSinceEpoch(ends);
        final started = json['s'] as int?;
        _startedAt = started == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(started);
      } catch (_) {
        phase = TimerPhase.idle;
      }
    }
    notifyListeners();
    // It may have run out while the app was closed.
    check();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stateKey,
      jsonEncode({
        't': totalSeconds,
        'p': phase.name,
        'r': _pausedRemainingMs,
        if (_endsAt != null) 'e': _endsAt!.millisecondsSinceEpoch,
        if (_startedAt != null) 's': _startedAt!.millisecondsSinceEpoch,
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  /// Sets the duration; only while idle.
  void setTotal(int seconds) {
    if (phase != TimerPhase.idle) return;
    totalSeconds = seconds.clamp(0, maxSeconds);
    _changed();
  }

  void start() {
    if (totalSeconds <= 0) return;
    final now = nowProvider();
    if (phase == TimerPhase.idle) {
      _startedAt = now;
      _endsAt = now.add(Duration(seconds: totalSeconds));
    } else if (phase == TimerPhase.paused) {
      _endsAt = now.add(Duration(milliseconds: _pausedRemainingMs));
    } else {
      return;
    }
    phase = TimerPhase.running;
    _scheduleNotification();
    _changed();
  }

  void pause() {
    if (!running) return;
    _pausedRemainingMs = remainingMs;
    phase = TimerPhase.paused;
    _endsAt = null;
    Notifier.cancel(_notificationId);
    _changed();
  }

  /// Adds time to a running/paused timer.
  void addSeconds(int seconds) {
    if (phase == TimerPhase.idle) return;
    totalSeconds = math.min(totalSeconds + seconds, maxSeconds);
    if (running) {
      _endsAt = _endsAt!.add(Duration(seconds: seconds));
      _scheduleNotification();
    } else {
      _pausedRemainingMs += seconds * 1000;
    }
    _changed();
  }

  /// Back to idle. A run that got somewhere is logged as not completed.
  void reset() {
    if (phase != TimerPhase.idle) {
      final ran = totalSeconds - (remainingMs / 1000).ceil();
      if (ran >= 5 && _startedAt != null) {
        ToolHistory.add(ToolEvent(
          kind: ToolKind.timer,
          at: _startedAt!,
          seconds: ran,
          planned: totalSeconds,
          completed: false,
        ));
      }
    }
    Notifier.cancel(_notificationId);
    _idle();
    _changed();
  }

  void _idle() {
    phase = TimerPhase.idle;
    _endsAt = null;
    _startedAt = null;
    _pausedRemainingMs = 0;
  }

  /// Called every second by the host: fires the timer if it ran out.
  void check() {
    if (!running || _endsAt == null) return;
    if (nowProvider().isBefore(_endsAt!)) return;
    _finish();
  }

  void _finish() {
    final started = _startedAt ?? nowProvider();
    final total = totalSeconds;
    _idle();
    _changed();

    ToolHistory.add(ToolEvent(
      kind: ToolKind.timer,
      at: started,
      seconds: total,
      planned: total,
    ));

    final l10n = currentL10n();
    final title = l10n.timerUpTitle;
    final body = l10n.timerUpBody(formatDuration(total));
    // The OS notification (if scheduled) already fired while closed; this
    // covers desktop and the app being open.
    Notifier.show(id: _notificationId, title: title, body: body);
    Alerts.ring(RingRequest(
      title: title,
      subtitle: body,
      icon: Icons.timer_rounded,
      onDismiss: () {},
    ));
  }

  void _scheduleNotification() {
    if (_endsAt == null) return;
    final l10n = currentL10n();
    Notifier.schedule(
      id: _notificationId,
      at: _endsAt!,
      title: l10n.timerUpTitle,
      body: l10n.timerUpBody(formatDuration(totalSeconds)),
    );
  }

  /// Back to factory state, in memory (after preferences were erased).
  void wipe() {
    Notifier.cancel(_notificationId);
    _idle();
    totalSeconds = 300;
    presets = List.of(defaultPresets);
    notifyListeners();
  }

  // ------------------------------------------------------------- presets

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(presetsKey, presets.map((p) => '$p').toList());
  }

  void addPreset(int seconds) {
    if (seconds <= 0 || presets.contains(seconds)) return;
    presets = [...presets, seconds]..sort();
    notifyListeners();
    _savePresets();
  }

  void removePreset(int seconds) {
    presets = presets.where((p) => p != seconds).toList();
    notifyListeners();
    _savePresets();
  }
}
