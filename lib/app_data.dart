import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'history.dart';
import 'l10n/locale_controller.dart';
import 'modes/alarm/alarm_service.dart';
import 'modes/clock/clock_prefs.dart';
import 'modes/fullscreen.dart';
import 'modes/mode_prefs.dart';
import 'modes/stopwatch/stopwatch_controller.dart';
import 'modes/timer/timer_controller.dart';
import 'modes/tool_history.dart';
import 'modes/world/world_prefs.dart';
import 'theme.dart';

/// Everything Enfo stores lives in shared preferences: the session history,
/// the settings, and the "already onboarded" flag. There is no other cache.
/// This is the one place that wipes them.
class AppData {
  /// Kept when only the settings are reset.
  /// Content the user made, as opposed to preferences: history, alarms,
  /// timers and the cities they follow survive a settings reset.
  static const _keptOnSettingsReset = {
    'session_history',
    ToolHistory.key,
    'onboarded',
    AlarmService.key,
    TimerController.presetsKey,
    'timer_state',
    'stopwatch_state',
    WorldPrefs.key,
  };

  /// Pomodoro sessions and everything the other modes logged.
  static Future<void> clearHistory() async {
    await SessionHistory.clear();
    await ToolHistory.clear();
  }

  /// Restores every setting to its default, keeping history and the
  /// onboarded flag. Removes all other keys rather than a hard-coded list,
  /// so settings added later are covered too.
  static Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!_keptOnSettingsReset.contains(key)) await prefs.remove(key);
    }
    await _reloadInMemoryState();
  }

  /// Deletes history and settings, including the onboarded flag: the next
  /// launch (or the caller) starts from the welcome screen.
  static Future<void> eraseAll() async {
    // Marks the clear time first, so a timer closing afterwards can't
    // re-save its session.
    await SessionHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Live tools hold state in memory too.
    await AlarmService.wipe();
    TimerController.instance.wipe();
    StopwatchController.instance.wipe();
    await _reloadInMemoryState();
  }

  /// Re-reads defaults into the notifiers/statics the running app holds.
  static Future<void> _reloadInMemoryState() async {
    Themes.resetAccent();
    await AppPreferences.load();
    await ModePrefs.load();
    await Fullscreen.load();
    await ClockPrefs.load();
    await WorldPrefs.load();
    await LocaleController.load();
  }
}
