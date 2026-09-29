import 'package:flutter/material.dart';

/// Icons a custom reminder can wear (stored by index, so keep the order).
const breakIcons = <IconData>[
  Icons.notifications_active_rounded,
  Icons.visibility_rounded,
  Icons.self_improvement_rounded,
  Icons.local_drink_rounded,
  Icons.accessibility_new_rounded,
  Icons.directions_walk_rounded,
  Icons.coffee_rounded,
  Icons.air_rounded,
  Icons.medication_rounded,
  Icons.favorite_rounded,
];

/// The four built-in reminders.
enum BuiltinBreak {
  eye('eye', 20, 20, 1),
  stretch('stretch', 50, 90, 2),
  water('water', 75, 10, 3),
  posture('posture', 30, 10, 4);

  const BuiltinBreak(this.id, this.interval, this.seconds, this.iconIndex);
  final String id;

  /// Default interval in minutes.
  final int interval;

  /// How long the break lasts, in seconds.
  final int seconds;
  final int iconIndex;

  static BuiltinBreak? byId(String id) {
    for (final b in values) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// One reminder. Built-ins are identified by [BuiltinBreak.id] and take their
/// name from the localizations; custom ones carry their own [name].
class BreakReminder {
  const BreakReminder({
    required this.id,
    required this.intervalMin,
    required this.durationSec,
    required this.iconIndex,
    this.name = '',
    this.enabled = false,
    this.nextDueMs,
  });

  final String id;
  final String name;
  final int intervalMin;
  final int durationSec;
  final int iconIndex;
  final bool enabled;

  /// When it is next due (absolute). Null while not scheduled or while a
  /// break is on screen waiting for an answer.
  final int? nextDueMs;

  bool get builtin => BuiltinBreak.byId(id) != null;
  BuiltinBreak? get builtinKind => BuiltinBreak.byId(id);

  IconData get icon =>
      breakIcons[iconIndex.clamp(0, breakIcons.length - 1).toInt()];

  /// The eye break is short and gentle (looking away for 20 s), everything
  /// else takes over the screen.
  bool get gentle => durationSec <= 30;

  BreakReminder copyWith({
    String? name,
    int? intervalMin,
    int? durationSec,
    int? iconIndex,
    bool? enabled,
    Object? nextDueMs = _keep,
  }) =>
      BreakReminder(
        id: id,
        name: name ?? this.name,
        intervalMin: intervalMin ?? this.intervalMin,
        durationSec: durationSec ?? this.durationSec,
        iconIndex: iconIndex ?? this.iconIndex,
        enabled: enabled ?? this.enabled,
        nextDueMs:
            identical(nextDueMs, _keep) ? this.nextDueMs : nextDueMs as int?,
      );

  static const _keep = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'interval': intervalMin,
        'duration': durationSec,
        'icon': iconIndex,
        'enabled': enabled,
        'next': nextDueMs,
      };

  static BreakReminder fromJson(Map<String, dynamic> j) => BreakReminder(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        intervalMin: ((j['interval'] as num?) ?? 20).toInt().clamp(1, 480),
        durationSec: ((j['duration'] as num?) ?? 20).toInt().clamp(5, 3600),
        iconIndex: ((j['icon'] as num?) ?? 0).toInt(),
        enabled: (j['enabled'] as bool?) ?? false,
        nextDueMs: (j['next'] as num?)?.toInt(),
      );

  static BreakReminder builtinDefault(BuiltinBreak b) => BreakReminder(
        id: b.id,
        intervalMin: b.interval,
        durationSec: b.seconds,
        iconIndex: b.iconIndex,
        enabled: b == BuiltinBreak.eye,
      );
}

/// The window of the day in which reminders may appear, in minutes since
/// midnight. [start] > [end] means it wraps midnight (22:00-06:00).
class ActiveHours {
  const ActiveHours({this.enabled = true, this.start = 540, this.end = 1080});

  final bool enabled;
  final int start;
  final int end;

  ActiveHours copyWith({bool? enabled, int? start, int? end}) => ActiveHours(
        enabled: enabled ?? this.enabled,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  /// A window with no length means "all day".
  bool get allDay => !enabled || start == end;

  bool contains(DateTime t) {
    if (allDay) return true;
    final m = t.hour * 60 + t.minute;
    return start < end ? (m >= start && m < end) : (m >= start || m < end);
  }

  /// [t] itself when inside the window, otherwise the next moment the window
  /// opens.
  DateTime clamp(DateTime t) {
    if (contains(t)) return t;
    final today = DateTime(t.year, t.month, t.day, start ~/ 60, start % 60);
    if (today.isAfter(t)) return today;
    return DateTime(t.year, t.month, t.day + 1, start ~/ 60, start % 60);
  }
}

/// Breaks taken / skipped on one calendar day.
class BreakCounters {
  const BreakCounters({this.day = '', this.taken = 0, this.skipped = 0});
  final String day;
  final int taken;
  final int skipped;
}

String dayKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
