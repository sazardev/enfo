/// Pure logic of the meeting planner (no Flutter, no tz database), so it is
/// easy to test: a zone is just an id plus "what is your UTC offset at this
/// instant?".
library;

typedef OffsetAt = Duration Function(DateTime utc);

const planStep = Duration(minutes: 15);
const planSteps = 96; // 24 h in quarter hours
const workStartMin = 9 * 60;
const workEndMin = 18 * 60;
const nightStartMin = 22 * 60;
const nightEndMin = 6 * 60;

class PlanZone {
  const PlanZone(this.id, this.offsetAt);
  final String id;
  final OffsetAt offsetAt;

  /// Wall-clock time in this zone at [utc], as a UTC-flagged DateTime whose
  /// fields are the local fields (never use it as an instant).
  DateTime wall(DateTime utc) => utc.toUtc().add(offsetAt(utc.toUtc()));

  int minuteOfDay(DateTime utc) {
    final w = wall(utc);
    return w.hour * 60 + w.minute;
  }

  bool working(DateTime utc) {
    final m = minuteOfDay(utc);
    return m >= workStartMin && m < workEndMin;
  }

  bool night(DateTime utc) {
    final m = minuteOfDay(utc);
    return m >= nightStartMin || m < nightEndMin;
  }

  /// Minutes between this instant and the nearest working time (0 inside).
  int minutesFromWork(DateTime utc) {
    final m = minuteOfDay(utc);
    if (m < workStartMin) return workStartMin - m;
    if (m >= workEndMin) {
      final after = m - workEndMin;
      final untilNext = 1440 - m + workStartMin;
      return after < untilNext ? after : untilNext;
    }
    return 0;
  }
}

/// Calendar-day difference of [zone]'s date at [utc] versus [ref]'s date.
int dayOffset(PlanZone zone, PlanZone ref, DateTime utc) {
  final a = zone.wall(utc);
  final b = ref.wall(utc);
  return DateTime.utc(a.year, a.month, a.day)
      .difference(DateTime.utc(b.year, b.month, b.day))
      .inDays;
}

class OverlapWindow {
  const OverlapWindow(this.start, this.end);
  final DateTime start;
  final DateTime end;
  Duration get length => end.difference(start);
}

class PlanResult {
  const PlanResult({required this.windows, this.leastBad, this.leastBadAtWork});

  /// Times when every zone is in working hours, longest first (ties by
  /// earliest). Empty when there are none.
  final List<OverlapWindow> windows;

  /// Only when [windows] is empty: the instant with the most zones at work
  /// (ties: the smallest total distance from working hours).
  final DateTime? leastBad;
  final int? leastBadAtWork;

  bool get hasOverlap => windows.isNotEmpty;
}

/// Best meeting windows across [zones] in the [planSteps] quarter hours
/// starting at [from] (a multiple of 15 min).
PlanResult planMeeting(List<PlanZone> zones, DateTime from) {
  final start = from.toUtc();
  if (zones.isEmpty) return const PlanResult(windows: []);
  final windows = <OverlapWindow>[];
  DateTime? runStart;
  DateTime? bestT;
  var bestAtWork = -1;
  var bestDistance = 1 << 30;

  for (var i = 0; i < planSteps; i++) {
    final t = start.add(planStep * i);
    var atWork = 0;
    var distance = 0;
    for (final z in zones) {
      if (z.working(t)) {
        atWork++;
      } else {
        distance += z.minutesFromWork(t);
      }
    }
    if (atWork == zones.length) {
      runStart ??= t;
    } else if (runStart != null) {
      windows.add(OverlapWindow(runStart, t));
      runStart = null;
    }
    if (atWork > bestAtWork ||
        (atWork == bestAtWork && distance < bestDistance)) {
      bestAtWork = atWork;
      bestDistance = distance;
      bestT = t;
    }
  }
  if (runStart != null) {
    windows.add(OverlapWindow(runStart, start.add(planStep * planSteps)));
  }
  windows.sort((a, b) {
    final c = b.length.compareTo(a.length);
    return c != 0 ? c : a.start.compareTo(b.start);
  });
  return windows.isNotEmpty
      ? PlanResult(windows: windows)
      : PlanResult(
          windows: const [], leastBad: bestT, leastBadAtWork: bestAtWork);
}

/// The quarter hour at or before [t].
DateTime floorToQuarter(DateTime t) {
  final ms = t.millisecondsSinceEpoch;
  const q = 15 * 60 * 1000;
  return DateTime.fromMillisecondsSinceEpoch(ms - ms % q, isUtc: t.isUtc);
}
