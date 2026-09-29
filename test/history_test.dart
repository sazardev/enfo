import 'package:enfo/history.dart';
import 'package:flutter_test/flutter_test.dart';

PomodoroSession _s(
  DateTime start, {
  int minutes = 25,
  bool work = true,
  bool completed = true,
  int pauses = 0,
}) {
  return PomodoroSession(
    isWork: work,
    startedAt: start,
    endedAt: start.add(Duration(minutes: minutes)),
    plannedSeconds: 25 * 60,
    focusedSeconds: minutes * 60,
    pauseCount: pauses,
    pausedSeconds: pauses * 30,
    completed: completed,
  );
}

void main() {
  final now = DateTime(2026, 9, 28, 15);

  test('json round trip', () {
    final s = _s(DateTime(2026, 9, 28, 9), pauses: 2);
    final back = PomodoroSession.fromJson(s.toJson());
    expect(back.startedAt, s.startedAt);
    expect(back.pauseCount, 2);
    expect(back.completed, true);
  });

  test('counts, completion rate, pauses', () {
    final stats = SessionStats([
      _s(DateTime(2026, 9, 28, 9), pauses: 1),
      _s(DateTime(2026, 9, 28, 10), work: false, minutes: 5),
      _s(DateTime(2026, 9, 28, 11), minutes: 10, completed: false),
    ], now: now);
    expect(stats.completedPomodoros, 1);
    expect(stats.abandonedPomodoros, 1);
    expect(stats.completionRate, 0.5);
    expect(stats.totalPauses, 1);
    expect(stats.todayPomodoros, 1);
    expect(stats.totalRestSeconds, 300);
  });

  test('streak counts back from yesterday when today is empty', () {
    final stats = SessionStats([
      _s(DateTime(2026, 9, 26, 9)),
      _s(DateTime(2026, 9, 27, 9)),
    ], now: now);
    expect(stats.currentStreakDays, 2);
    expect(
        SessionStats([_s(DateTime(2026, 9, 20, 9))], now: now)
            .currentStreakDays,
        0);
  });

  test('gaps between sessions', () {
    final stats = SessionStats([
      _s(DateTime(2026, 9, 28, 9)), // ends 9:25
      _s(DateTime(2026, 9, 28, 9, 35)), // gap 10m
      _s(DateTime(2026, 9, 28, 10, 40)), // prev ends 10:00 -> gap 40m
    ], now: now);
    expect(stats.gapBefore(0), isNull);
    expect(stats.gapBefore(1), const Duration(minutes: 10));
    expect(stats.longestGap, const Duration(minutes: 40));
    expect(stats.averageGap, const Duration(minutes: 25));
  });

  test('empty history has no derived values', () {
    final stats = SessionStats(const [], now: now);
    expect(stats.completionRate, isNull);
    expect(stats.averageGap, isNull);
    expect(stats.sinceLastSession, isNull);
    expect(stats.currentStreakDays, 0);
  });
}
