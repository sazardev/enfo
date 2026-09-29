import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One work or rest phase, from the first tap on start until it either ran
/// to the end ([completed]) or was abandoned (reset, preset change, app
/// closed).
class PomodoroSession {
  const PomodoroSession({
    required this.isWork,
    required this.startedAt,
    required this.endedAt,
    required this.plannedSeconds,
    required this.focusedSeconds,
    required this.pauseCount,
    required this.pausedSeconds,
    required this.completed,
  });

  final bool isWork;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Length the phase was configured for.
  final int plannedSeconds;

  /// Time the timer actually ran (excludes pauses).
  final int focusedSeconds;
  final int pauseCount;
  final int pausedSeconds;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'w': isWork,
        's': startedAt.millisecondsSinceEpoch,
        'e': endedAt.millisecondsSinceEpoch,
        'p': plannedSeconds,
        'f': focusedSeconds,
        'pc': pauseCount,
        'ps': pausedSeconds,
        'c': completed,
      };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      isWork: json['w'] as bool,
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['s'] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(json['e'] as int),
      plannedSeconds: json['p'] as int,
      focusedSeconds: json['f'] as int,
      pauseCount: json['pc'] as int,
      pausedSeconds: json['ps'] as int,
      completed: json['c'] as bool,
    );
  }
}

/// Persistence for [PomodoroSession]s, oldest first.
class SessionHistory {
  static const _key = 'session_history';

  /// Oldest sessions are dropped beyond this so the prefs blob stays small.
  static const _maxSessions = 2000;

  static Future<List<PomodoroSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          PomodoroSession.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Corrupted blob: start fresh rather than crash the stats screen.
      return [];
    }
  }

  /// When the history was last cleared in this run. A timer that was still
  /// running then saves itself when its screen closes; that record must not
  /// resurrect the history that was just erased.
  static DateTime? _clearedAt;

  static Future<void> add(PomodoroSession session) async {
    final clearedAt = _clearedAt;
    if (clearedAt != null && session.startedAt.isBefore(clearedAt)) return;
    final sessions = await load();
    sessions.add(session);
    final kept = sessions.length > _maxSessions
        ? sessions.sublist(sessions.length - _maxSessions)
        : sessions;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final s in kept) s.toJson()]),
    );
  }

  static Future<void> clear() async {
    _clearedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Aggregated metrics derived from a list of sessions (oldest first).
class SessionStats {
  SessionStats(this.sessions, {DateTime? now}) : now = now ?? DateTime.now();

  final List<PomodoroSession> sessions;
  final DateTime now;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  Iterable<PomodoroSession> get _work => sessions.where((s) => s.isWork);
  Iterable<PomodoroSession> get _completedWork =>
      _work.where((s) => s.completed);

  int get completedPomodoros => _completedWork.length;
  int get abandonedPomodoros => _work.length - completedPomodoros;

  /// Fraction of started work phases that ran to the end, or null if none.
  double? get completionRate =>
      _work.isEmpty ? null : completedPomodoros / _work.length;

  int get totalFocusSeconds =>
      _work.fold(0, (sum, s) => sum + s.focusedSeconds);
  int get totalRestSeconds => sessions
      .where((s) => !s.isWork)
      .fold(0, (sum, s) => sum + s.focusedSeconds);

  int get totalPauses => sessions.fold(0, (sum, s) => sum + s.pauseCount);
  int get totalPausedSeconds =>
      sessions.fold(0, (sum, s) => sum + s.pausedSeconds);

  int get averageFocusSeconds =>
      _work.isEmpty ? 0 : totalFocusSeconds ~/ _work.length;

  int get longestFocusSeconds => _work.fold(
      0, (max, s) => s.focusedSeconds > max ? s.focusedSeconds : max);

  int get todayPomodoros =>
      _completedWork.where((s) => _day(s.startedAt) == _day(now)).length;

  int get todayFocusSeconds => _work
      .where((s) => _day(s.startedAt) == _day(now))
      .fold(0, (sum, s) => sum + s.focusedSeconds);

  /// Consecutive days, ending today (or yesterday if nothing is done yet
  /// today), with at least one completed pomodoro.
  int get currentStreakDays {
    final days = _completedWork.map((s) => _day(s.startedAt)).toSet();
    var cursor = _day(now);
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  /// Completed pomodoros per day for the last [days] days, oldest first.
  List<({DateTime day, int count})> lastDays(int days) {
    final today = _day(now);
    return [
      for (var i = days - 1; i >= 0; i--)
        (
          day: DateTime(today.year, today.month, today.day - i),
          count: _completedWork
              .where((s) =>
                  _day(s.startedAt) ==
                  DateTime(today.year, today.month, today.day - i))
              .length,
        ),
    ];
  }

  /// Idle time between the end of one session and the start of the next.
  /// Keyed by the later session's index in [sessions].
  Duration? gapBefore(int index) {
    if (index <= 0) return null;
    final gap =
        sessions[index].startedAt.difference(sessions[index - 1].endedAt);
    return gap.isNegative ? Duration.zero : gap;
  }

  /// Gaps longer than this are treated as "came back another day", not as
  /// a break, so they don't skew the average.
  static const _sameSittingGap = Duration(hours: 3);

  Duration? get averageGap {
    final gaps = [
      for (var i = 1; i < sessions.length; i++) gapBefore(i)!,
    ].where((g) => g <= _sameSittingGap).toList();
    if (gaps.isEmpty) return null;
    final total = gaps.fold(Duration.zero, (sum, g) => sum + g);
    return total ~/ gaps.length;
  }

  Duration? get longestGap {
    if (sessions.length < 2) return null;
    return [for (var i = 1; i < sessions.length; i++) gapBefore(i)!]
        .reduce((a, b) => a > b ? a : b);
  }

  /// Time since the last session ended, or null if there is no history.
  Duration? get sinceLastSession =>
      sessions.isEmpty ? null : now.difference(sessions.last.endedAt);
}
