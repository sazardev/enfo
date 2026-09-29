import '../tool_history.dart';

/// Seconds of one activity per calendar day, oldest first. The last entry is
/// [today]. A session counts on the day it started. Pure, so it is easy to
/// test with a frozen date.
List<int> dailyTotals(
  Iterable<ToolEvent> events, {
  required String label,
  required DateTime today,
  int days = 7,
}) {
  final start = DateTime(today.year, today.month, today.day - (days - 1));
  final totals = List<int>.filled(days, 0);
  for (final e in events) {
    if (e.kind != ToolKind.tracker || e.label != label) continue;
    final day = DateTime(e.at.year, e.at.month, e.at.day);
    final index = _daysBetween(start, day);
    if (index < 0 || index >= days) continue;
    totals[index] += e.seconds;
  }
  return totals;
}

/// Total seconds on [day] over every activity, or only [label]'s.
int totalOnDay(
  Iterable<ToolEvent> events,
  DateTime day, {
  String? label,
}) {
  var sum = 0;
  for (final e in events) {
    if (e.kind != ToolKind.tracker) continue;
    if (label != null && e.label != label) continue;
    if (e.at.year == day.year &&
        e.at.month == day.month &&
        e.at.day == day.day) {
      sum += e.seconds;
    }
  }
  return sum;
}

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;
