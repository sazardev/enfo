import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/locale_controller.dart';
import '../clock/time_builder.dart';
import '../mode_services.dart';
import '../notifier.dart';
import 'event_logic.dart';

/// Stores the events and notifies for them.
///
/// Two layers, like alarms: on Android/iOS the OS is handed the
/// notifications ahead of time ([reschedule]) so they arrive with Enfo
/// closed; on desktop [check] (the host's one-second heartbeat) shows them
/// while the app runs.
class EventService implements ModeService {
  EventService._();
  static final EventService instance = EventService._();

  static const key = 'events';

  /// A notification more than this late is dropped, not shown.
  static const window = Duration(minutes: 10);

  /// Yearly events get this many occurrences scheduled ahead, so they keep
  /// notifying for years without the app being opened.
  static const _yearsAhead = 3;

  final ValueNotifier<List<CountdownEvent>> events = ValueNotifier([]);

  static bool get _mobile => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    try {
      events.value = raw == null
          ? []
          : [
              for (final item in jsonDecode(raw) as List<dynamic>)
                CountdownEvent.fromJson(item as Map<String, dynamic>),
            ];
    } catch (_) {
      events.value = [];
    }
    for (final e in events.value) {
      await reschedule(e);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode([for (final e in events.value) e.toJson()]),
    );
  }

  /// Clears memory after preferences were wiped.
  Future<void> wipe() async {
    for (final e in events.value) {
      await _cancel(e);
    }
    events.value = [];
  }

  // ---------------------------------------------------------------- CRUD

  int _newId() {
    final used = events.value.map((e) => e.id).toSet();
    var id = 1;
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  CountdownEvent create({
    required String name,
    required DateTime target,
    int icon = 0,
    bool yearly = false,
    bool notify = false,
    bool dayBefore = false,
  }) =>
      CountdownEvent(
        id: _newId(),
        name: name,
        targetMs: target.millisecondsSinceEpoch,
        createdMs: nowProvider().millisecondsSinceEpoch,
        icon: icon,
        yearly: yearly,
        notify: notify,
        dayBefore: dayBefore,
      );

  /// Adds or replaces [event]. Whatever notification moment already passed
  /// is marked handled so saving never fires it immediately.
  Future<void> upsert(CountdownEvent event) async {
    final now = nowProvider();
    final view = viewOf(event, now);
    final t = view.target.millisecondsSinceEpoch;
    final armed = event.copyWith(
      firedMs: view.isUpcoming ? 0 : t,
      firedBeforeMs:
          view.target.subtract(const Duration(days: 1)).isAfter(now) ? 0 : t,
    );
    final list = [...events.value];
    final i = list.indexWhere((e) => e.id == armed.id);
    i < 0 ? list.add(armed) : list[i] = armed;
    events.value = list;
    await _save();
    await reschedule(armed);
  }

  Future<void> remove(CountdownEvent event) async {
    events.value = events.value.where((e) => e.id != event.id).toList();
    await _save();
    await _cancel(event);
  }

  // -------------------------------------------------------- notifications

  static int _base(CountdownEvent e) => 700000 + e.id * 8;

  Future<void> _cancel(CountdownEvent e) async {
    for (var i = 0; i < _yearsAhead * 2; i++) {
      await Notifier.cancel(_base(e) + i);
    }
  }

  /// The instants an event should notify at, oldest first, with whether
  /// each is the "day before" one.
  @visibleForTesting
  static List<({DateTime at, bool before})> notificationTimes(
    CountdownEvent e,
    DateTime now,
  ) {
    if (!e.notify) return const [];
    final first = viewOf(e, now).target;
    final occurrences = e.yearly
        ? [
            for (var k = 0; k < _yearsAhead; k++)
              occurrenceIn(e.target, first.year + k),
          ]
        : [first];
    return [
      for (final t in occurrences) ...[
        if (e.dayBefore)
          (at: t.subtract(const Duration(days: 1)), before: true),
        (at: t, before: false),
      ],
    ].where((n) => n.at.isAfter(now)).toList();
  }

  Future<void> reschedule(CountdownEvent e) async {
    await _cancel(e);
    if (!_mobile) return;
    final l10n = currentL10n();
    var slot = 0;
    for (final n in notificationTimes(e, nowProvider())) {
      await Notifier.schedule(
        id: _base(e) + (slot++ % (_yearsAhead * 2)),
        at: n.at,
        title: e.name,
        body: n.before ? l10n.eventNotifyTomorrow : l10n.eventNotifyNow,
      );
    }
  }

  /// Marks due notifications handled, and shows them on desktop (mobile
  /// already has the OS doing it). Cheap; called every second.
  @override
  void check() => checkAt(nowProvider());

  @visibleForTesting
  void checkAt(DateTime now) {
    var changed = false;
    final list = [...events.value];
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (!e.notify) continue;
      final v = viewOf(e, now);
      final t = v.target;
      var updated = e;

      if (!v.isUpcoming && e.firedMs < t.millisecondsSinceEpoch) {
        updated = updated.copyWith(firedMs: t.millisecondsSinceEpoch);
        if (now.difference(t) <= window) _show(e, before: false);
      }
      final b = t.subtract(const Duration(days: 1));
      if (e.dayBefore &&
          v.isUpcoming &&
          !now.isBefore(b) &&
          e.firedBeforeMs < t.millisecondsSinceEpoch) {
        updated = updated.copyWith(firedBeforeMs: t.millisecondsSinceEpoch);
        if (now.difference(b) <= window) _show(e, before: true);
      }
      if (!identical(updated, e)) {
        list[i] = updated;
        changed = true;
      }
    }
    if (changed) {
      events.value = list;
      _save();
    }
  }

  void _show(CountdownEvent e, {required bool before}) {
    if (_mobile) return;
    final l10n = currentL10n();
    Notifier.show(
      id: _base(e) + (before ? 1 : 0),
      title: e.name,
      body: before ? l10n.eventNotifyTomorrow : l10n.eventNotifyNow,
    );
  }
}
