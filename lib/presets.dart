import 'package:shared_preferences/shared_preferences.dart';

class PomodoroPreset {
  final String label;
  final int workMinutes;
  final int restMinutes;

  const PomodoroPreset({
    required this.label,
    required this.workMinutes,
    required this.restMinutes,
  });
}

class Presets {
  static const PomodoroPreset classic = PomodoroPreset(
    label: 'Clásico',
    workMinutes: 25,
    restMinutes: 5,
  );

  static const PomodoroPreset extended = PomodoroPreset(
    label: 'Extendido',
    workMinutes: 50,
    restMinutes: 10,
  );

  static const PomodoroPreset deepWork = PomodoroPreset(
    label: 'Profundo',
    workMinutes: 90,
    restMinutes: 20,
  );

  static const List<PomodoroPreset> all = [classic, extended, deepWork];

  static const _onboardedKey = 'onboarded';
  static const _workMinutesKey = 'work_minutes';
  static const _restMinutesKey = 'rest_minutes';
  static const _notificationsKey = 'notifications_enabled';

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  static Future<({int workMinutes, int restMinutes})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      workMinutes: prefs.getInt(_workMinutesKey) ?? classic.workMinutes,
      restMinutes: prefs.getInt(_restMinutesKey) ?? classic.restMinutes,
    );
  }

  static Future<void> save({
    required int workMinutes,
    required int restMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
    await prefs.setInt(_workMinutesKey, workMinutes);
    await prefs.setInt(_restMinutesKey, restMinutes);
  }

  static Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
