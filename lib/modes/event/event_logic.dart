import 'dart:math' as math;

/// Pure calculations for the countdown mode: no widgets, no storage, and
/// "now" is always passed in so tests can freeze it.

/// Icons an event can wear. Stored by index, so only ever append.
const int eventIconCount = 8;

/// One thing to count down to.
class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.name,
    required this.targetMs,
    required this.createdMs,
    this.icon = 0,
    this.yearly = false,
    this.notify = false,
    this.dayBefore = false,
    this.firedMs = 0,
    this.firedBeforeMs = 0,
  });

  final int id;
  final String name;

  /// Local wall-clock target (for a yearly event: any past or future
  /// occurrence, it only defines month, day and time).
  final int targetMs;
  final int createdMs;
  final int icon;
  final bool yearly;

  /// Notify at the target moment (and [dayBefore] a day earlier).
  final bool notify;
  final bool dayBefore;

  /// The occurrence whose notification was already handled, so it never
  /// fires twice.
  final int firedMs;
  final int firedBeforeMs;

  DateTime get target => DateTime.fromMillisecondsSinceEpoch(targetMs);
  DateTime get created => DateTime.fromMillisecondsSinceEpoch(createdMs);

  CountdownEvent copyWith({
    String? name,
    int? targetMs,
    int? createdMs,
    int? icon,
    bool? yearly,
    bool? notify,
    bool? dayBefore,
    int? firedMs,
    int? firedBeforeMs,
  }) =>
      CountdownEvent(
        id: id,
        name: name ?? this.name,
        targetMs: targetMs ?? this.targetMs,
        createdMs: createdMs ?? this.createdMs,
        icon: icon ?? this.icon,
        yearly: yearly ?? this.yearly,
        notify: notify ?? this.notify,
        dayBefore: dayBefore ?? this.dayBefore,
        firedMs: firedMs ?? this.firedMs,
        firedBeforeMs: firedBeforeMs ?? this.firedBeforeMs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        't': targetMs,
        'c': createdMs,
        'i': icon,
        'y': yearly,
        'no': notify,
        'db': dayBefore,
        'f': firedMs,
        'fb': firedBeforeMs,
      };

  factory CountdownEvent.fromJson(Map<String, dynamic> json) => CountdownEvent(
        id: json['id'] as int,
        name: json['n'] as String? ?? '',
        targetMs: json['t'] as int,
        createdMs: json['c'] as int? ?? json['t'] as int,
        icon: (json['i'] as int? ?? 0).clamp(0, eventIconCount - 1),
        yearly: json['y'] as bool? ?? false,
        notify: json['no'] as bool? ?? false,
        dayBefore: json['db'] as bool? ?? false,
        firedMs: json['f'] as int? ?? 0,
        firedBeforeMs: json['fb'] as int? ?? 0,
      );
}

enum EventPhase {
  /// The moment has not arrived yet.
  upcoming,

  /// It arrived earlier today: "Today!".
  today,

  /// Before today: "X days ago".
  past,
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Whole calendar days from [a] to [b] (DST-safe).
int calendarDaysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

/// The month/day/time of [base] in [year]. 29 February falls back to the
/// 28th in years that have no leap day.
DateTime occurrenceIn(DateTime base, int year) => DateTime(
      year,
      base.month,
      math.min(base.day, daysInMonth(year, base.month)),
      base.hour,
      base.minute,
    );

/// The occurrence a yearly event is currently about: today's if it falls
/// today (even if the time has gone: "Today!"), otherwise the next one.
DateTime yearlyTarget(DateTime base, DateTime now) {
  var t = occurrenceIn(base, math.max(now.year, base.year));
  if (dateOnly(t).isBefore(dateOnly(now))) {
    t = occurrenceIn(base, t.year + 1);
  }
  return t;
}

/// How an event stands at a given instant.
class EventView {
  const EventView({
    required this.event,
    required this.target,
    required this.start,
    required this.phase,
    required this.now,
  });

  final CountdownEvent event;

  /// The occurrence being counted to (rolled forward if yearly).
  final DateTime target;

  /// Where the progress starts: creation, or the previous occurrence.
  final DateTime start;
  final EventPhase phase;
  final DateTime now;

  bool get isUpcoming => phase == EventPhase.upcoming;

  /// Time left, never negative.
  Duration get remaining => isUpcoming ? target.difference(now) : Duration.zero;

  int get days => remaining.inDays;
  int get hours => remaining.inHours % 24;
  int get minutes => remaining.inMinutes % 60;

  /// The target falls on today's date (upcoming or already reached).
  bool get isToday => calendarDaysBetween(now, target) == 0;

  int get daysAgo =>
      phase == EventPhase.past ? calendarDaysBetween(target, now) : 0;

  /// Elapsed fraction between [start] and [target], 0..1.
  double get progress {
    final span = target.difference(start).inMilliseconds;
    if (span <= 0) return isUpcoming ? 0 : 1;
    return (now.difference(start).inMilliseconds / span).clamp(0.0, 1.0);
  }

  /// What a clock face shows for this event.
  FaceReading get face => FaceReading.of(this);
}

EventView viewOf(CountdownEvent e, DateTime now) {
  final base = e.target;
  final DateTime target;
  final DateTime start;
  if (e.yearly) {
    target = yearlyTarget(base, now);
    var s = occurrenceIn(base, target.year - 1);
    if (!s.isBefore(target)) s = target.subtract(const Duration(days: 365));
    start = s;
  } else {
    target = base;
    start = e.created;
  }
  final phase = target.isAfter(now)
      ? EventPhase.upcoming
      : (calendarDaysBetween(target, now) == 0
          ? EventPhase.today
          : EventPhase.past);
  return EventView(
      event: e, target: target, start: start, phase: phase, now: now);
}

/// Today's celebrations first, then what is coming (nearest first), then
/// what is behind us (most recent first).
List<EventView> orderedViews(Iterable<CountdownEvent> events, DateTime now) {
  final views = [for (final e in events) viewOf(e, now)];
  int rank(EventView v) => switch (v.phase) {
        EventPhase.today => 0,
        EventPhase.upcoming => 1,
        EventPhase.past => 2,
      };
  views.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    return a.phase == EventPhase.upcoming
        ? a.target.compareTo(b.target)
        : b.target.compareTo(a.target);
  });
  return views;
}

/// The numbers to feed a clock face, which only knows "mm:ss".
///
/// The face's minutes field carries days and its seconds field carries
/// hours while a day or more remains (`12:05` = 12 days 5 hours); under a
/// day it carries hours and minutes. [totalUnits] and [progress] are chosen
/// so the face's own maths lands exactly on [remainingUnits].
class FaceReading {
  const FaceReading({
    required this.totalUnits,
    required this.progress,
    required this.daysMode,
    required this.remainingUnits,
  });

  final int totalUnits;
  final double progress;
  final bool daysMode;
  final int remainingUnits;

  factory FaceReading.of(EventView v) {
    final daysMode = v.days >= 1;
    final units = daysMode ? v.days * 60 + v.hours : v.hours * 60 + v.minutes;
    final p = v.progress;
    if (units == 0) {
      return FaceReading(
        totalUnits: 1,
        progress: v.isUpcoming ? p : 1,
        daysMode: daysMode,
        remainingUnits: 0,
      );
    }
    final total = math.max(units, (units / math.max(1 - p, 1e-6)).ceil());
    return FaceReading(
      totalUnits: total,
      // A hair under, so the face's ceil() lands on [units], not one above.
      progress: 1 - (units - 0.001) / total,
      daysMode: daysMode,
      remainingUnits: units,
    );
  }
}

/// `3d 4h`, `5h 12m`, `12m`: compact remaining time for list cards.
String shortRemaining(
  Duration d, {
  required String dayUnit,
  required String hourUnit,
  required String minuteUnit,
}) {
  if (d.inDays >= 1) return '${d.inDays}$dayUnit ${d.inHours % 24}$hourUnit';
  if (d.inHours >= 1) {
    return '${d.inHours}$hourUnit ${d.inMinutes % 60}$minuteUnit';
  }
  return '${d.inMinutes}$minuteUnit';
}
