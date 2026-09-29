import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_mode.dart';
import '../haptics/haptics.dart';

/// Which modes exist for the user, in what order, and which one is showing.
/// Order is also the order the quick-switch button cycles through.
class ModePrefs {
  static const _orderKey = 'mode_order';
  static const _disabledKey = 'mode_disabled';
  static const _currentKey = 'mode_current';
  static const _startKey = 'mode_start';
  static const _seenKey = 'mode_seen';

  static final order = ValueNotifier<List<AppMode>>(List.of(AppMode.values));
  static final disabled = ValueNotifier<Set<AppMode>>(<AppMode>{});
  static final current = ValueNotifier<AppMode>(AppMode.pomodoro);

  /// null = reopen on whatever mode was showing last.
  static final startMode = ValueNotifier<AppMode?>(null);

  static Listenable get changes => Listenable.merge([order, disabled, current]);

  /// Visible modes in user order. Never empty.
  static List<AppMode> get enabled {
    final list = order.value.where((m) => !disabled.value.contains(m)).toList();
    return list.isEmpty ? [AppMode.pomodoro] : list;
  }

  static AppMode? _parse(String? name) {
    for (final m in AppMode.values) {
      if (m.name == name) return m;
    }
    return null;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Stored order may be missing modes added later: append them.
    final stored = (prefs.getString(_orderKey) ?? '')
        .split(',')
        .map(_parse)
        .whereType<AppMode>()
        .toList();
    order.value = [
      ...{...stored, ...AppMode.values},
    ];
    disabled.value = (prefs.getString(_disabledKey) ?? '')
        .split(',')
        .map(_parse)
        .whereType<AppMode>()
        .toSet();
    // A mode the user has never been offered starts off unless it is core,
    // so an update does not bury the quick-switch under new tools.
    final seen = (prefs.getString(_seenKey) ?? '')
        .split(',')
        .map(_parse)
        .whereType<AppMode>()
        .toSet();
    if (prefs.getString(_seenKey) == null &&
        prefs.getString(_orderKey) != null) {
      // Existing install from before the seen list: the original modes.
      seen.addAll(AppMode.values.where((m) => m.core));
    }
    final fresh = AppMode.values.where((m) => !seen.contains(m));
    disabled.value = {
      ...disabled.value,
      ...fresh.where((m) => !m.core),
    };
    await prefs.setString(
        _seenKey, AppMode.values.map((m) => m.name).join(','));
    await prefs.setString(
        _disabledKey, disabled.value.map((m) => m.name).join(','));
    // Never leave the user with nothing.
    if (enabled.isEmpty || disabled.value.length >= AppMode.values.length) {
      disabled.value = <AppMode>{};
    }

    final start = prefs.getString(_startKey);
    startMode.value = start == null ? null : _parse(start);

    final last = _parse(prefs.getString(_currentKey));
    final wanted = startMode.value ?? last ?? AppMode.pomodoro;
    current.value = enabled.contains(wanted) ? wanted : enabled.first;
  }

  static Future<void> setCurrent(AppMode mode) async {
    if (!enabled.contains(mode)) return;
    if (current.value != mode) Haptics.transition();
    current.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, mode.name);
  }

  /// Cycles through the visible modes (wraps around).
  static Future<void> step([int delta = 1]) async {
    final list = enabled;
    final i = list.indexOf(current.value);
    final next = list[((i < 0 ? 0 : i) + delta) % list.length];
    await setCurrent(next);
  }

  static Future<void> setOrder(List<AppMode> value) async {
    order.value = List.of(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, value.map((m) => m.name).join(','));
  }

  /// Returns false (and changes nothing) if it would hide the last mode.
  static Future<bool> setEnabled(AppMode mode, bool on) async {
    final next = {...disabled.value};
    on ? next.remove(mode) : next.add(mode);
    if (next.length >= AppMode.values.length) return false;
    disabled.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_disabledKey, next.map((m) => m.name).join(','));
    if (!enabled.contains(current.value)) await setCurrent(enabled.first);
    return true;
  }

  static Future<void> setStartMode(AppMode? mode) async {
    startMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == null) {
      await prefs.remove(_startKey);
    } else {
      await prefs.setString(_startKey, mode.name);
    }
  }
}
