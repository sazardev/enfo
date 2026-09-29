import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/locale_controller.dart';
import '../alerts.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../notifier.dart';
import '../tool_history.dart';
import 'alarm.dart';

/// Alarms: storage, "what rings next", ringing, snooze, and the OS
/// notifications that make them work with the app closed.
///
/// Two layers, deliberately redundant:
/// * [check] (called every second by the host) rings in-app. This is what
///   works on desktop, and when the app is open anywhere.
/// * [reschedule] queues OS notifications for the next [_lookAheadDays]
///   days (Android/iOS) so an alarm still fires with the app closed. The
///   window rolls forward every time the app opens.
class AlarmService {
  static const key = 'alarms';
  static const snoozeMinutes = 5;

  /// A missed alarm older than this is logged as missed, not rung late.
  static const ringWindow = Duration(minutes: 10);

  static const _lookAheadDays = 14;

  static final alarms = ValueNotifier<List<Alarm>>([]);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) {
      alarms.value = [];
    } else {
      try {
        alarms.value = [
          for (final item in jsonDecode(raw) as List<dynamic>)
            Alarm.fromJson(item as Map<String, dynamic>),
        ];
      } catch (_) {
        alarms.value = [];
      }
    }
    await rescheduleAll();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final a in alarms.value) a.toJson()]),
    );
  }

  /// Clears the in-memory list (after preferences were wiped).
  static Future<void> wipe() async {
    for (final a in alarms.value) {
      await _cancelNotifications(a);
    }
    alarms.value = [];
  }

  // ---------------------------------------------------------------- CRUD

  static int _newId() {
    final used = alarms.value.map((a) => a.id).toSet();
    var id = 1;
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  /// A fresh alarm never rings for a time that already passed today.
  static Alarm create({
    required int hour,
    required int minute,
    Set<int> days = const {},
    String label = '',
  }) =>
      Alarm(
        id: _newId(),
        hour: hour,
        minute: minute,
        days: days,
        label: label,
        lastHandledMs: nowProvider().millisecondsSinceEpoch,
      );

  static Future<void> upsert(Alarm alarm) async {
    final list = [...alarms.value];
    final i = list.indexWhere((a) => a.id == alarm.id);
    // (Re-)arming: whatever time already passed today stays silent.
    final armed = alarm.copyWith(
      lastHandledMs: nowProvider().millisecondsSinceEpoch,
      snoozedUntilMs: null,
    );
    i < 0 ? list.add(armed) : list[i] = armed;
    list.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    alarms.value = list;
    await _save();
    await reschedule(armed);
  }

  static Future<void> setEnabled(Alarm alarm, bool on) =>
      upsert(alarm.copyWith(enabled: on));

  static Future<void> remove(Alarm alarm) async {
    alarms.value = alarms.value.where((a) => a.id != alarm.id).toList();
    await _save();
    await _cancelNotifications(alarm);
  }

  // ----------------------------------------------------------- scheduling

  static bool _matches(Alarm a, DateTime day) =>
      !a.repeats || a.days.contains(day.weekday);

  static DateTime _at(Alarm a, DateTime day) =>
      DateTime(day.year, day.month, day.day, a.hour, a.minute);

  /// The next time [a] will ring after [now], or null if it won't
  /// (disabled, or a one-shot that already went).
  static DateTime? nextFire(Alarm a, DateTime now) {
    if (!a.enabled) return null;
    final snoozed = a.snoozedUntilMs;
    if (snoozed != null && snoozed > now.millisecondsSinceEpoch) {
      return DateTime.fromMillisecondsSinceEpoch(snoozed);
    }
    for (var d = 0; d <= 7; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final at = _at(a, day);
      if (at.isAfter(now) &&
          at.millisecondsSinceEpoch > a.lastHandledMs &&
          _matches(a, day)) {
        return at;
      }
    }
    return null;
  }

  /// Soonest ring across all alarms.
  static DateTime? nextOverall(DateTime now) {
    DateTime? best;
    for (final a in alarms.value) {
      final t = nextFire(a, now);
      if (t != null && (best == null || t.isBefore(best))) best = t;
    }
    return best;
  }

  /// The most recent scheduled occurrence at or before [now] that hasn't
  /// been handled yet, if any.
  static DateTime? _dueOccurrence(Alarm a, DateTime now) {
    final snoozed = a.snoozedUntilMs;
    if (snoozed != null && snoozed <= now.millisecondsSinceEpoch) {
      return DateTime.fromMillisecondsSinceEpoch(snoozed);
    }
    for (var back = 0; back <= 7; back++) {
      final day = DateTime(now.year, now.month, now.day - back);
      final at = _at(a, day);
      if (!at.isAfter(now) && _matches(a, day)) {
        return at.millisecondsSinceEpoch > a.lastHandledMs ? at : null;
      }
    }
    return null;
  }

  /// Rings whatever is due. Cheap; called every second.
  static Future<void> check([DateTime? nowOverride]) async {
    final now = nowOverride ?? nowProvider();
    for (final a in [...alarms.value]) {
      if (!a.enabled) continue;
      final due = _dueOccurrence(a, now);
      if (due == null) continue;

      final l10n = currentL10n();
      final late = now.difference(due);
      // Handled either way, so it can't ring twice.
      var handled = a.copyWith(
        lastHandledMs: due.millisecondsSinceEpoch,
        snoozedUntilMs: null,
      );
      if (!a.repeats) handled = handled.copyWith(enabled: false);
      _replace(handled);
      await _save();

      if (late > ringWindow) {
        await ToolHistory.add(ToolEvent(
          kind: ToolKind.alarm,
          at: due,
          label: a.label.isEmpty ? null : a.label,
          outcome: 'missed',
        ));
        await reschedule(handled);
        continue;
      }

      // The OS notification for this occurrence would just duplicate the
      // in-app ring.
      await Notifier.cancel(_occurrenceId(a, due));

      final time = '${two(a.hour)}:${two(a.minute)}';
      void log(String outcome) => ToolHistory.add(ToolEvent(
            kind: ToolKind.alarm,
            at: due,
            label: a.label.isEmpty ? null : a.label,
            outcome: outcome,
          ));

      Alerts.ring(RingRequest(
        title: a.label.isEmpty ? l10n.modeAlarm : a.label,
        subtitle: time,
        icon: Icons.alarm_rounded,
        snoozeMinutes: snoozeMinutes,
        onDismiss: () => log('dismissed'),
        onExpire: () => log('missed'),
        onSnooze: () {
          log('snoozed');
          // A one-shot alarm was switched off when it went; snoozing brings
          // it back until the snooze rings.
          snooze(handled.copyWith(enabled: true));
        },
      ));
      await reschedule(handled);
    }
  }

  static void _replace(Alarm alarm) {
    alarms.value = [
      for (final a in alarms.value) a.id == alarm.id ? alarm : a,
    ];
  }

  static Future<void> snooze(Alarm alarm) async {
    final until = nowProvider().add(const Duration(minutes: snoozeMinutes));
    final snoozed =
        alarm.copyWith(snoozedUntilMs: until.millisecondsSinceEpoch);
    _replace(snoozed);
    await _save();
    await reschedule(snoozed);
  }

  // ---------------------------------------------------------- notifications

  static int _base(Alarm a) => 10000 + a.id * 20;

  /// One notification id per calendar day of the look-ahead window.
  static int _occurrenceId(Alarm a, DateTime at) {
    final day = DateTime.utc(at.year, at.month, at.day)
        .difference(DateTime.utc(1970))
        .inDays;
    return _base(a) + day % _lookAheadDays;
  }

  static int _snoozeId(Alarm a) => _base(a) + _lookAheadDays;

  static Future<void> _cancelNotifications(Alarm a) async {
    for (var i = 0; i <= _lookAheadDays; i++) {
      await Notifier.cancel(_base(a) + i);
    }
  }

  static Future<void> reschedule(Alarm a) async {
    await _cancelNotifications(a);
    if (!a.enabled) return;
    final now = nowProvider();
    final l10n = currentL10n();
    final title = a.label.isEmpty ? l10n.modeAlarm : a.label;
    final time = '${two(a.hour)}:${two(a.minute)}';

    final snoozed = a.snoozedUntilMs;
    if (snoozed != null && snoozed > now.millisecondsSinceEpoch) {
      await Notifier.schedule(
        id: _snoozeId(a),
        at: DateTime.fromMillisecondsSinceEpoch(snoozed),
        title: title,
        body: time,
        alarm: true,
      );
    }
    for (var d = 0; d < _lookAheadDays; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final at = _at(a, day);
      if (!_matches(a, day) ||
          !at.isAfter(now) ||
          at.millisecondsSinceEpoch <= a.lastHandledMs) {
        continue;
      }
      await Notifier.schedule(
        id: _occurrenceId(a, at),
        at: at,
        title: title,
        body: time,
        alarm: true,
      );
      if (!a.repeats) break;
    }
  }

  static Future<void> rescheduleAll() async {
    for (final a in alarms.value) {
      await reschedule(a);
    }
  }
}
