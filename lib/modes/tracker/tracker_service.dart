import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/locale_controller.dart';
import '../clock/time_builder.dart';
import '../mode_services.dart';
import '../tool_history.dart';

/// The small icon set an activity can wear.
const List<IconData> trackerIcons = [
  Icons.menu_book_rounded,
  Icons.auto_stories_rounded,
  Icons.code_rounded,
  Icons.fitness_center_rounded,
  Icons.brush_rounded,
  Icons.music_note_rounded,
  Icons.work_rounded,
  Icons.spa_rounded,
  Icons.translate_rounded,
  Icons.home_rounded,
  Icons.sports_esports_rounded,
  Icons.star_rounded,
];

class TrackerActivity {
  const TrackerActivity({
    required this.id,
    this.name,
    this.builtin,
    required this.color,
    required this.icon,
  });

  final String id;

  /// The user's name; null for a default activity that was never renamed
  /// (it then follows the app language through [builtin]).
  final String? name;
  final String? builtin;
  final int color;
  final int icon;

  IconData get iconData => trackerIcons[icon.clamp(0, trackerIcons.length - 1)];

  String get displayName {
    if (name != null) return name!;
    final l10n = currentL10n();
    return switch (builtin) {
      'study' => l10n.trackerStudy,
      'reading' => l10n.trackerReading,
      'code' => l10n.trackerCode,
      'exercise' => l10n.trackerExercise,
      _ => l10n.trackerAddActivity,
    };
  }

  TrackerActivity copyWith({String? name, int? color, int? icon}) =>
      TrackerActivity(
        id: id,
        name: name ?? this.name,
        builtin: builtin,
        color: color ?? this.color,
        icon: icon ?? this.icon,
      );

  Map<String, dynamic> toJson() => {
        'i': id,
        if (name != null) 'n': name,
        if (builtin != null) 'b': builtin,
        'c': color,
        'ic': icon,
      };

  factory TrackerActivity.fromJson(Map<String, dynamic> j) => TrackerActivity(
        id: j['i'] as String,
        name: j['n'] as String?,
        builtin: j['b'] as String?,
        color: j['c'] as int,
        icon: j['ic'] as int? ?? 0,
      );
}

/// The time tracker. One activity runs at a time; the running activity and
/// its start time are absolute timestamps persisted in prefs, so it keeps
/// counting while another mode is open and across app restarts.
class TrackerService extends ChangeNotifier implements ModeService {
  TrackerService._();
  static final TrackerService instance = TrackerService._();

  static const _key = 'tracker_state';

  /// Sessions shorter than this are dropped (an accidental tap).
  static const minSeconds = 10;

  List<TrackerActivity> activities = _defaults();
  String? runningId;
  DateTime? startedAt;
  String? lastId;

  /// The tracker events in the history, oldest first (for the stats).
  List<ToolEvent> events = const [];

  static List<TrackerActivity> _defaults() => [
        TrackerActivity(
            id: 'd-study',
            builtin: 'study',
            color: Colors.indigo.toARGB32(),
            icon: 0),
        TrackerActivity(
            id: 'd-reading',
            builtin: 'reading',
            color: Colors.orange.toARGB32(),
            icon: 1),
        TrackerActivity(
            id: 'd-code',
            builtin: 'code',
            color: Colors.teal.toARGB32(),
            icon: 2),
        TrackerActivity(
            id: 'd-exercise',
            builtin: 'exercise',
            color: Colors.red.toARGB32(),
            icon: 3),
      ];

  bool get running => runningId != null;

  TrackerActivity? byId(String? id) {
    for (final a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  TrackerActivity? get runningActivity => byId(runningId);

  /// Seconds the running activity has been timed.
  int get elapsedSeconds => startedAt == null
      ? 0
      : nowProvider().difference(startedAt!).inSeconds.clamp(0, 1 << 30);

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        activities = [
          for (final a in j['a'] as List<dynamic>)
            TrackerActivity.fromJson(a as Map<String, dynamic>),
        ];
        runningId = j['r'] as String?;
        lastId = j['l'] as String?;
        final s = j['s'] as int?;
        startedAt = s == null ? null : DateTime.fromMillisecondsSinceEpoch(s);
        if (byId(runningId) == null || startedAt == null) {
          runningId = null;
          startedAt = null;
        }
      } catch (_) {
        activities = _defaults();
        runningId = null;
        startedAt = null;
      }
    } else {
      activities = _defaults();
      runningId = null;
      startedAt = null;
    }
    await reloadEvents();
  }

  Future<void> reloadEvents() async {
    events = [
      for (final e in await ToolHistory.load())
        if (e.kind == ToolKind.tracker) e,
    ];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'a': [for (final a in activities) a.toJson()],
        if (runningId != null) 'r': runningId,
        if (lastId != null) 'l': lastId,
        if (startedAt != null) 's': startedAt!.millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> _changed() async {
    notifyListeners();
    await _save();
  }

  /// Starts [id], first stopping (and saving) whatever was running.
  Future<void> start(String id) async {
    if (byId(id) == null || runningId == id) return;
    await stop();
    runningId = id;
    lastId = id;
    startedAt = nowProvider();
    await _changed();
  }

  /// Stops the running activity and saves the session.
  Future<void> stop() async {
    final a = runningActivity;
    final began = startedAt;
    if (a == null || began == null) return;
    final seconds = nowProvider().difference(began).inSeconds;
    runningId = null;
    startedAt = null;
    await _changed();
    if (seconds >= minSeconds) {
      await ToolHistory.add(ToolEvent(
        kind: ToolKind.tracker,
        at: began,
        seconds: seconds,
        label: a.displayName,
      ));
      await reloadEvents();
    }
  }

  /// Space: stop what runs, or resume the last activity.
  Future<void> toggleLast() async {
    if (running) return stop();
    final id =
        byId(lastId)?.id ?? (activities.isEmpty ? null : activities.first.id);
    if (id != null) await start(id);
  }

  /// Logs [minutes] done earlier today without running the clock.
  Future<void> addManual(String id, int minutes) async {
    final a = byId(id);
    if (a == null || minutes <= 0) return;
    final now = nowProvider();
    await ToolHistory.add(ToolEvent(
      kind: ToolKind.tracker,
      at: now.subtract(Duration(minutes: minutes)),
      seconds: minutes * 60,
      label: a.displayName,
    ));
    await reloadEvents();
  }

  Future<TrackerActivity> create(int color) async {
    final a = TrackerActivity(
      id: 'a-${nowProvider().microsecondsSinceEpoch}',
      color: color,
      icon: activities.length % trackerIcons.length,
    );
    activities = [...activities, a];
    await _changed();
    return a;
  }

  Future<void> update(TrackerActivity a) async {
    activities = [for (final x in activities) x.id == a.id ? a : x];
    await _changed();
  }

  Future<void> delete(String id) async {
    if (runningId == id) await stop();
    activities = [
      for (final a in activities)
        if (a.id != id) a
    ];
    if (lastId == id) lastId = null;
    await _changed();
  }

  /// Test hook: back to a fresh install.
  Future<void> wipe() async {
    activities = _defaults();
    runningId = null;
    startedAt = null;
    lastId = null;
    events = const [];
    notifyListeners();
  }

  @override
  void check() {}
}
