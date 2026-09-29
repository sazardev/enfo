import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What kind of thing happened. Pomodoro sessions keep their own richer
/// history ([SessionHistory]); everything else lands here.
enum ToolKind { timer, stopwatch, alarm, display }

/// One entry in the tools history: a timer that ran, a stopwatch with its
/// laps, an alarm that rang, or a stretch of time the clock was on display.
class ToolEvent {
  const ToolEvent({
    required this.kind,
    required this.at,
    this.seconds = 0,
    this.planned,
    this.completed = true,
    this.label,
    this.laps = const [],
    this.outcome,
  });

  final ToolKind kind;

  /// When it started (timer, stopwatch, display) or fired (alarm).
  final DateTime at;

  /// How long it ran. 0 for alarms.
  final int seconds;

  /// Timer: the length it was set for.
  final int? planned;

  /// Timer: ran to zero. Stopwatch/display: always true.
  final bool completed;
  final String? label;

  /// Stopwatch lap times in milliseconds, in order.
  final List<int> laps;

  /// Alarm: 'dismissed', 'snoozed' or 'missed'. Display: the mode name.
  final String? outcome;

  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'a': at.millisecondsSinceEpoch,
        's': seconds,
        if (planned != null) 'p': planned,
        'c': completed,
        if (label != null) 'l': label,
        if (laps.isNotEmpty) 'lp': laps,
        if (outcome != null) 'o': outcome,
      };

  factory ToolEvent.fromJson(Map<String, dynamic> json) {
    return ToolEvent(
      kind: ToolKind.values.firstWhere((k) => k.name == json['k']),
      at: DateTime.fromMillisecondsSinceEpoch(json['a'] as int),
      seconds: json['s'] as int? ?? 0,
      planned: json['p'] as int?,
      completed: json['c'] as bool? ?? true,
      label: json['l'] as String?,
      laps: (json['lp'] as List<dynamic>?)?.cast<int>() ?? const [],
      outcome: json['o'] as String?,
    );
  }
}

/// Persistence for [ToolEvent]s, oldest first.
class ToolHistory {
  static const key = 'tool_history';
  static const _maxEvents = 2000;

  static Future<List<ToolEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          ToolEvent.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // A corrupted blob shouldn't take the history screen down with it.
      return [];
    }
  }

  static Future<void> add(ToolEvent event) async {
    final events = await load();
    events.add(event);
    final kept = events.length > _maxEvents
        ? events.sublist(events.length - _maxEvents)
        : events;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final e in kept) e.toJson()]));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
