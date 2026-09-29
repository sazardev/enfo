import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/locale_controller.dart';
import '../alerts.dart';
import '../clock/time_builder.dart';
import '../mode_services.dart';
import '../notifier.dart';
import 'breaks_model.dart';

/// Healthy-break reminders (eye rest, stretch, water, posture, your own).
///
/// Timestamp-driven like the timer: every reminder stores the absolute time
/// it is next due, everything is persisted, and [check] (called each second
/// by the host, whichever mode is open) shows the break when it is due.
/// With the app closed on a phone, [_reschedule] keeps a rolling window of OS
/// notifications queued so the reminders still arrive.
class BreaksService extends ChangeNotifier implements ModeService {
  BreaksService._();
  static final BreaksService instance = BreaksService._();

  static const key = 'breaks_state';
  static const snoozeMinutes = 5;

  /// A break more than this late (the app was closed, the device asleep) is
  /// not shown; the schedule just rolls forward.
  static const lateWindow = Duration(minutes: 5);

  /// OS notifications queued per reminder, and how far ahead they may reach.
  static const notificationsPerReminder = 8;
  static const notificationHorizon = Duration(hours: 12);
  static const _idBase = 70000;
  static const _idStride = 20;
  static const maxCustom = 8;

  bool _running = false;
  bool _background = true;
  ActiveHours _hours = const ActiveHours();
  List<BreakReminder> _reminders = [
    for (final b in BuiltinBreak.values) BreakReminder.builtinDefault(b),
  ];
  BreakCounters _counters = const BreakCounters();
  int _nextCustom = 1;

  /// Reminders currently on screen waiting for an answer.
  final Set<String> _pending = {};

  bool get running => _running;
  bool get background => _background;
  ActiveHours get hours => _hours;
  List<BreakReminder> get reminders => List.unmodifiable(_reminders);

  /// Today's counters (zero once the day changes).
  BreakCounters get today {
    final k = dayKey(nowProvider());
    return _counters.day == k ? _counters : BreakCounters(day: k);
  }

  BreakReminder? reminder(String id) {
    for (final r in _reminders) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// The reminder that will come up first, if the service is running.
  BreakReminder? get upcoming {
    if (!_running) return null;
    BreakReminder? best;
    for (final r in _reminders) {
      if (!r.enabled || r.nextDueMs == null) continue;
      if (best == null || r.nextDueMs! < best.nextDueMs!) best = r;
    }
    return best;
  }

  // ------------------------------------------------------------ persistence

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _running = (j['running'] as bool?) ?? false;
        _background = (j['background'] as bool?) ?? true;
        _hours = ActiveHours(
          enabled: (j['hoursOn'] as bool?) ?? true,
          start: ((j['start'] as num?) ?? 540).toInt().clamp(0, 1439),
          end: ((j['end'] as num?) ?? 1080).toInt().clamp(0, 1439),
        );
        _nextCustom = ((j['nextCustom'] as num?) ?? 1).toInt();
        final list = [
          for (final item in (j['reminders'] as List<dynamic>? ?? const []))
            BreakReminder.fromJson(item as Map<String, dynamic>),
        ];
        // Built-ins always exist, in their fixed order, then custom ones.
        _reminders = [
          for (final b in BuiltinBreak.values)
            list.where((r) => r.id == b.id).firstOrNull ??
                BreakReminder.builtinDefault(b),
          ...list.where((r) => !r.builtin),
        ];
        final c = j['counters'] as Map<String, dynamic>?;
        if (c != null) {
          _counters = BreakCounters(
            day: (c['day'] as String?) ?? '',
            taken: ((c['taken'] as num?) ?? 0).toInt(),
            skipped: ((c['skipped'] as num?) ?? 0).toInt(),
          );
        }
      } catch (_) {
        // Corrupt state: start from the defaults.
      }
    }
    _pending.clear();
    if (_running) _resync(nowProvider());
    notifyListeners();
    await _reschedule();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'running': _running,
        'background': _background,
        'hoursOn': _hours.enabled,
        'start': _hours.start,
        'end': _hours.end,
        'nextCustom': _nextCustom,
        'reminders': [for (final r in _reminders) r.toJson()],
        'counters': {
          'day': _counters.day,
          'taken': _counters.taken,
          'skipped': _counters.skipped,
        },
      }),
    );
  }

  /// Back to factory state (after preferences were wiped). Also used by tests.
  Future<void> wipe() async {
    await _cancelAll();
    _running = false;
    _background = true;
    _hours = const ActiveHours();
    _reminders = [
      for (final b in BuiltinBreak.values) BreakReminder.builtinDefault(b),
    ];
    _counters = const BreakCounters();
    _nextCustom = 1;
    _pending.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------- control

  /// When a reminder that starts counting at [from] is next due.
  DateTime _dueAfter(BreakReminder r, DateTime from) =>
      _hours.clamp(from.add(Duration(minutes: r.intervalMin)));

  /// Gives every enabled reminder a sensible due time. Ones already due
  /// within the late window are kept (they ring on the next tick); ones that
  /// are missing or long overdue restart their interval from [now].
  void _resync(DateTime now, {bool restart = false}) {
    _reminders = [
      for (final r in _reminders)
        if (!r.enabled)
          r.copyWith(nextDueMs: null)
        else if (!restart &&
            r.nextDueMs != null &&
            now.millisecondsSinceEpoch - r.nextDueMs! <=
                lateWindow.inMilliseconds)
          r
        else
          r.copyWith(nextDueMs: _dueAfter(r, now).millisecondsSinceEpoch),
    ];
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _resync(nowProvider(), restart: true);
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> stop() async {
    _running = false;
    _pending.clear();
    _reminders = [for (final r in _reminders) r.copyWith(nextDueMs: null)];
    notifyListeners();
    await _save();
    await _cancelAll();
  }

  Future<void> toggle() => _running ? stop() : start();

  /// Restarts every interval from now.
  Future<void> restart() async {
    if (!_running) return;
    _resync(nowProvider(), restart: true);
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> setBackground(bool on) async {
    _background = on;
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> setHours(ActiveHours h) async {
    _hours = h;
    if (_running) _resync(nowProvider(), restart: true);
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> update(BreakReminder next) async {
    final old = reminder(next.id);
    if (old == null) return;
    var r = next;
    final changed =
        r.enabled != old.enabled || r.intervalMin != old.intervalMin;
    if (_running && r.enabled && (changed || r.nextDueMs == null)) {
      r = r.copyWith(
          nextDueMs: _dueAfter(r, nowProvider()).millisecondsSinceEpoch);
    } else if (!r.enabled || !_running) {
      r = r.copyWith(nextDueMs: null);
    }
    _reminders = [for (final x in _reminders) x.id == r.id ? r : x];
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> setEnabled(String id, bool on) async {
    final r = reminder(id);
    if (r != null) await update(r.copyWith(enabled: on));
  }

  /// Adds a custom reminder (enabled) and returns it.
  Future<BreakReminder?> addCustom({
    required String name,
    int intervalMin = 30,
    int durationSec = 30,
    int iconIndex = 0,
  }) async {
    if (_reminders.where((r) => !r.builtin).length >= maxCustom) return null;
    final r = BreakReminder(
      id: 'c${_nextCustom++}',
      name: name,
      intervalMin: intervalMin,
      durationSec: durationSec,
      iconIndex: iconIndex,
      enabled: true,
    );
    _reminders = [..._reminders, r];
    notifyListeners();
    await update(r);
    return reminder(r.id);
  }

  Future<void> removeCustom(String id) async {
    final r = reminder(id);
    if (r == null || r.builtin) return;
    await _cancelSlot(r);
    _reminders = _reminders.where((x) => x.id != id).toList();
    _pending.remove(id);
    notifyListeners();
    await _save();
  }

  // ---------------------------------------------------------------- counters

  void _count({bool taken = false, bool skipped = false}) {
    final t = today;
    _counters = BreakCounters(
      day: t.day,
      taken: t.taken + (taken ? 1 : 0),
      skipped: t.skipped + (skipped ? 1 : 0),
    );
  }

  // ------------------------------------------------------------------ ticking

  @override
  void check() => checkAt(nowProvider());

  /// Shows whatever is due at [now]. Cheap; runs every second.
  void checkAt(DateTime now) {
    if (!_running) return;
    final nowMs = now.millisecondsSinceEpoch;
    for (final r in [..._reminders]) {
      final due = r.nextDueMs;
      if (!r.enabled || due == null || due > nowMs) continue;
      if (nowMs - due > lateWindow.inMilliseconds) {
        // Missed while the app was closed: silently roll forward.
        _setNext(r.id, _dueAfter(r, now));
        continue;
      }
      _ring(r, now);
    }
  }

  void _setNext(String id, DateTime? at) {
    _reminders = [
      for (final r in _reminders)
        r.id == id ? r.copyWith(nextDueMs: at?.millisecondsSinceEpoch) : r,
    ];
    notifyListeners();
    _save();
    _reschedule();
  }

  static String durationText(int seconds) {
    if (seconds < 120) return '$seconds s';
    return '${seconds ~/ 60} min';
  }

  String titleOf(BreakReminder r) {
    final l = currentL10n();
    return switch (r.builtinKind) {
      BuiltinBreak.eye => l.breaksEyeName,
      BuiltinBreak.stretch => l.breaksStretchName,
      BuiltinBreak.water => l.breaksWaterName,
      BuiltinBreak.posture => l.breaksPostureName,
      null => r.name.isEmpty ? l.breaksCustomDefault : r.name,
    };
  }

  String hintOf(BreakReminder r) {
    final l = currentL10n();
    return switch (r.builtinKind) {
      BuiltinBreak.eye => l.breaksEyeHint,
      BuiltinBreak.stretch => l.breaksStretchHint,
      BuiltinBreak.water => l.breaksWaterHint,
      BuiltinBreak.posture => l.breaksPostureHint,
      null => l.breaksForDuration(durationText(r.durationSec)),
    };
  }

  void _ring(BreakReminder r, DateTime now) {
    if (!_pending.add(r.id)) return;
    // Nothing more to fire for it until the user answers.
    _reminders = [
      for (final x in _reminders)
        x.id == r.id ? x.copyWith(nextDueMs: null) : x,
    ];
    notifyListeners();
    _cancelSlot(r);

    final l = currentL10n();
    final title = titleOf(r);
    final hint = hintOf(r);

    void answer({bool taken = false, bool skipped = false, int? snooze}) {
      _pending.remove(r.id);
      final current = reminder(r.id);
      if (current == null) return;
      if (taken || skipped) _count(taken: taken, skipped: skipped);
      if (_running && current.enabled) {
        final at = snooze != null
            ? _hours.clamp(nowProvider().add(Duration(minutes: snooze)))
            : _dueAfter(current, nowProvider());
        _reminders = [
          for (final x in _reminders)
            x.id == r.id ? x.copyWith(nextDueMs: at.millisecondsSinceEpoch) : x,
        ];
      }
      notifyListeners();
      _save();
      _reschedule();
    }

    Alerts.ring(RingRequest(
      title: title,
      subtitle: hint,
      icon: r.icon,
      gentle: r.gentle,
      // A short eye break dismisses itself once the 20 s are over.
      giveUpAfter: r.gentle
          ? Duration(seconds: r.durationSec)
          : const Duration(minutes: 3),
      dismissLabel: l.breaksDone,
      snoozeMinutes: snoozeMinutes,
      extraLabel: l.breaksSkip,
      onDismiss: () => answer(taken: true),
      onSnooze: () => answer(snooze: snoozeMinutes),
      onExtra: () => answer(skipped: true),
      // Nobody answered: a long break counts as skipped, the short one was
      // on screen for its whole length, so it counts as taken.
      onExpire: () => r.gentle ? answer(taken: true) : answer(skipped: true),
    ));

    // On desktop the window may be minimized or behind others.
    if (Platform.isWindows || Platform.isLinux) {
      Notifier.show(id: _idBase, title: title, body: hint);
    }
  }

  // ------------------------------------------------------------ notifications

  int _slot(BreakReminder r) {
    final b = r.builtinKind;
    if (b != null) return b.index;
    final n = int.tryParse(r.id.substring(1)) ?? 0;
    return BuiltinBreak.values.length + (n % 32);
  }

  int _notificationId(BreakReminder r, int k) =>
      _idBase + 100 + _slot(r) * _idStride + k;

  Future<void> _cancelSlot(BreakReminder r) async {
    for (var k = 0; k < notificationsPerReminder; k++) {
      await Notifier.cancel(_notificationId(r, k));
    }
  }

  Future<void> _cancelAll() async {
    for (final r in _reminders) {
      await _cancelSlot(r);
    }
  }

  /// The future due times to hand to the OS for [r], in order.
  @visibleForTesting
  List<DateTime> upcomingTimes(BreakReminder r, DateTime now) {
    final first = r.nextDueMs;
    if (first == null) return const [];
    final out = <DateTime>[];
    var t = DateTime.fromMillisecondsSinceEpoch(first);
    final limit = now.add(notificationHorizon);
    while (out.length < notificationsPerReminder && !t.isAfter(limit)) {
      if (t.isAfter(now)) out.add(t);
      t = _dueAfter(r, t);
    }
    return out;
  }

  Future<void> _reschedule() async {
    await _cancelAll();
    if (!_running || !_background) return;
    final now = nowProvider();
    for (final r in _reminders) {
      if (!r.enabled || _pending.contains(r.id)) continue;
      final times = upcomingTimes(r, now);
      for (var k = 0; k < times.length; k++) {
        await Notifier.schedule(
          id: _notificationId(r, k),
          at: times[k],
          title: titleOf(r),
          body: hintOf(r),
        );
      }
    }
  }
}
