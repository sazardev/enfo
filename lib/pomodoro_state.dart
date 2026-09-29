import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroRun { idle, running, paused }

/// Where the Pomodoro dial was, in absolute time, so it can pick up exactly
/// where it left off after the app is closed or killed.
///
/// A running phase stores the instant it ends ([endsAt]) rather than a
/// progress value: however long the app was away, the remaining time is
/// just `endsAt - now`. A paused phase stores the time it had left.
class PomodoroSnapshot {
  const PomodoroSnapshot({
    required this.run,
    required this.rest,
    required this.totalSeconds,
    this.endsAt,
    this.remainingMs = 0,
    this.sessionStart,
    this.pauseStart,
    this.pauseCount = 0,
    this.pausedMs = 0,
  });

  final PomodoroRun run;

  /// Whether the current (or next, when idle) phase is a rest.
  final bool rest;

  /// Length of the phase in progress, including any time added to it.
  final int totalSeconds;

  /// Running only: when the phase ends.
  final DateTime? endsAt;

  /// Paused only: how much of the phase was left.
  final int remainingMs;

  // Bookkeeping for the history record of the phase in progress.
  final DateTime? sessionStart;
  final DateTime? pauseStart;
  final int pauseCount;
  final int pausedMs;

  Map<String, dynamic> toJson() => {
        'run': run.name,
        'rest': rest,
        't': totalSeconds,
        if (endsAt != null) 'e': endsAt!.millisecondsSinceEpoch,
        'r': remainingMs,
        if (sessionStart != null) 's': sessionStart!.millisecondsSinceEpoch,
        if (pauseStart != null) 'ps': pauseStart!.millisecondsSinceEpoch,
        'pc': pauseCount,
        'pm': pausedMs,
      };

  static DateTime? _date(Object? ms) =>
      ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

  factory PomodoroSnapshot.fromJson(Map<String, dynamic> json) {
    final run = PomodoroRun.values.firstWhere((r) => r.name == json['run']);
    final snapshot = PomodoroSnapshot(
      run: run,
      rest: json['rest'] as bool,
      totalSeconds: json['t'] as int,
      endsAt: _date(json['e']),
      remainingMs: json['r'] as int? ?? 0,
      sessionStart: _date(json['s']),
      pauseStart: _date(json['ps']),
      pauseCount: json['pc'] as int? ?? 0,
      pausedMs: json['pm'] as int? ?? 0,
    );
    if (run == PomodoroRun.running && snapshot.endsAt == null) {
      throw const FormatException('running without an end');
    }
    if (snapshot.totalSeconds <= 0) {
      throw const FormatException('empty phase');
    }
    return snapshot;
  }
}

/// Persistence for the Pomodoro dial. Loaded before the app starts so the
/// dial can restore synchronously, without a flash of the idle state.
class PomodoroStore {
  static const key = 'pomodoro_state';

  /// The last saved state; null when there is nothing to resume (idle on a
  /// fresh work phase).
  static PomodoroSnapshot? snapshot;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    snapshot = null;
    if (raw == null) return;
    try {
      snapshot = PomodoroSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Corrupted blob: start from a clean dial rather than crash.
    }
  }

  static Future<void> save(PomodoroSnapshot? next) async {
    snapshot = next;
    final prefs = await SharedPreferences.getInstance();
    if (next == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(next.toJson()));
    }
  }

  /// Forgets the state in memory (after preferences were erased).
  static void wipe() => snapshot = null;
}
