import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../alerts.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_services.dart';
import '../notifier.dart';
import '../tool_history.dart';

/// One kitchen timer. Timestamp-driven: a running timer stores when it ends,
/// a paused one how much is left.
class KitchenTimer {
  KitchenTimer({
    required this.id,
    required this.name,
    required this.plannedSeconds,
    required this.startedAt,
    this.endsAt,
    this.pausedRemainingMs = 0,
  });

  /// Slot 0..[KitchenService.maxTimers): also picks the notification id.
  final int id;
  final String name;

  /// Length it was set for, including any "+1 min" added since.
  int plannedSeconds;
  final DateTime startedAt;
  DateTime? endsAt;
  int pausedRemainingMs;

  bool get running => endsAt != null;

  int get remainingMs => running
      ? math.max(0, endsAt!.difference(nowProvider()).inMilliseconds)
      : pausedRemainingMs;

  /// Elapsed fraction, 0..1.
  double get progress => plannedSeconds <= 0
      ? 1
      : (1 - remainingMs / (plannedSeconds * 1000)).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'p': plannedSeconds,
        's': startedAt.millisecondsSinceEpoch,
        if (endsAt != null) 'e': endsAt!.millisecondsSinceEpoch,
        'r': pausedRemainingMs,
      };

  factory KitchenTimer.fromJson(Map<String, dynamic> j) {
    final e = j['e'] as int?;
    return KitchenTimer(
      id: j['i'] as int,
      name: j['n'] as String,
      plannedSeconds: j['p'] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(j['s'] as int),
      endsAt: e == null ? null : DateTime.fromMillisecondsSinceEpoch(e),
      pausedRemainingMs: j['r'] as int? ?? 0,
    );
  }
}

/// Several named timers at once. App-wide, persisted, checked every second
/// by the host so they ring whichever mode is open.
class KitchenService extends ChangeNotifier implements ModeService {
  KitchenService._();
  static final KitchenService instance = KitchenService._();

  static const _key = 'kitchen_timers';

  /// Notification ids are [notificationBase] + slot: 9200..9299, clear of the
  /// timer (9001), intervals (9100) and the alarms (10000 and up).
  static const notificationBase = 9200;
  static const maxTimers = 20;
  static const maxSeconds = 99 * 3600 + 59 * 60 + 59;

  /// A timer that ran out more than this long ago (app was closed) is logged
  /// but no longer rings.
  static const _staleRing = Duration(minutes: 10);

  final List<KitchenTimer> _timers = [];

  /// Soonest end first: running timers by end time, then the paused ones by
  /// time left.
  List<KitchenTimer> get timers {
    final list = List.of(_timers);
    list.sort((a, b) {
      if (a.running != b.running) return a.running ? -1 : 1;
      return a.remainingMs.compareTo(b.remainingMs);
    });
    return list;
  }

  KitchenTimer? get soonest {
    final t = timers;
    return t.isEmpty ? null : t.first;
  }

  bool get isFull => _timers.length >= maxTimers;

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _timers.clear();
    if (raw != null) {
      try {
        for (final j in jsonDecode(raw) as List<dynamic>) {
          _timers.add(KitchenTimer.fromJson(j as Map<String, dynamic>));
        }
      } catch (_) {
        _timers.clear();
      }
    }
    notifyListeners();
    check(); // some may have finished while the app was closed
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode([for (final t in _timers) t.toJson()]));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  int _freeSlot() {
    final used = _timers.map((t) => t.id).toSet();
    var i = 0;
    while (used.contains(i)) {
      i++;
    }
    return i;
  }

  KitchenTimer? byId(int id) {
    for (final t in _timers) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Starts a new timer. Null when [seconds] is 0 or the list is full.
  KitchenTimer? add(String name, int seconds) {
    if (seconds <= 0 || isFull) return null;
    final now = nowProvider();
    final clean =
        name.trim().isEmpty ? currentL10n().kitchenDefaultName : name.trim();
    final t = KitchenTimer(
      id: _freeSlot(),
      name: clean,
      plannedSeconds: math.min(seconds, maxSeconds),
      startedAt: now,
      endsAt: now.add(Duration(seconds: math.min(seconds, maxSeconds))),
    );
    _timers.add(t);
    Haptics.confirm();
    _schedule(t);
    _changed();
    return t;
  }

  void addMinute(int id) {
    final t = byId(id);
    if (t == null) return;
    Haptics.select();
    t.plannedSeconds = math.min(t.plannedSeconds + 60, maxSeconds);
    if (t.running) {
      t.endsAt = t.endsAt!.add(const Duration(minutes: 1));
      _schedule(t);
    } else {
      t.pausedRemainingMs += 60000;
    }
    _changed();
  }

  void pause(int id) {
    final t = byId(id);
    if (t == null || !t.running) return;
    Haptics.tap();
    t.pausedRemainingMs = t.remainingMs;
    t.endsAt = null;
    Notifier.cancel(notificationBase + t.id);
    _changed();
  }

  void resume(int id) {
    final t = byId(id);
    if (t == null || t.running) return;
    Haptics.tap();
    t.endsAt = nowProvider().add(Duration(milliseconds: t.pausedRemainingMs));
    _schedule(t);
    _changed();
  }

  void toggle(int id) {
    final t = byId(id);
    if (t == null) return;
    t.running ? pause(id) : resume(id);
  }

  /// Removes a timer. One that ran a while is logged as not completed.
  void remove(int id) {
    final t = byId(id);
    if (t == null) return;
    Haptics.warning();
    final ran = t.plannedSeconds - (t.remainingMs / 1000).ceil();
    if (ran >= 5) _log(t, seconds: ran, completed: false);
    Notifier.cancel(notificationBase + t.id);
    _timers.remove(t);
    _changed();
  }

  /// Back to factory state, in memory (after preferences were erased).
  void wipe() {
    for (final t in _timers) {
      Notifier.cancel(notificationBase + t.id);
    }
    _timers.clear();
    notifyListeners();
  }

  @override
  void check() {
    final now = nowProvider();
    final due = [
      for (final t in _timers)
        if (t.running && !t.endsAt!.isAfter(now)) t,
    ]..sort((a, b) => a.endsAt!.compareTo(b.endsAt!));
    if (due.isEmpty) return;
    for (final t in due) {
      _timers.remove(t);
      _log(t, seconds: t.plannedSeconds, completed: true);
      final late = now.difference(t.endsAt!);
      final l10n = currentL10n();
      final title = l10n.kitchenDoneTitle(t.name);
      final body = l10n.kitchenDoneBody(formatDuration(t.plannedSeconds));
      Notifier.show(id: notificationBase + t.id, title: title, body: body);
      if (late <= _staleRing) {
        Alerts.ring(RingRequest(
          title: title,
          subtitle: body,
          icon: Icons.soup_kitchen_rounded,
          timer: true,
          onDismiss: () {},
        ));
      }
    }
    _changed();
  }

  /// ToolHistory.add is read-modify-write: timers finishing in the same tick
  /// must not race each other, so their entries are written one at a time.
  Future<void> _logQueue = Future.value();

  void _log(KitchenTimer t, {required int seconds, required bool completed}) {
    final event = ToolEvent(
      kind: ToolKind.kitchen,
      at: t.startedAt,
      seconds: seconds,
      planned: t.plannedSeconds,
      completed: completed,
      label: t.name,
    );
    _logQueue = _logQueue.then((_) => ToolHistory.add(event));
  }

  void _schedule(KitchenTimer t) {
    if (!t.running) return;
    final l10n = currentL10n();
    Notifier.schedule(
      id: notificationBase + t.id,
      at: t.endsAt!,
      title: l10n.kitchenDoneTitle(t.name),
      body: l10n.kitchenDoneBody(formatDuration(t.plannedSeconds)),
    );
  }
}
