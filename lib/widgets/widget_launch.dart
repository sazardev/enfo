import '../modes/app_mode.dart';
import '../modes/mode_prefs.dart';
import '../modes/stopwatch/stopwatch_controller.dart';
import '../modes/timer/timer_controller.dart';
import 'pomodoro_live.dart';

/// Turns a tap on a home-screen widget into what the user meant: open the
/// right mode and, for the quick buttons, do the thing.
///
/// The widget only knows a mode name and an optional action string, so the
/// behavior lives here, next to the controllers, and stays testable.
class WidgetLaunch {
  const WidgetLaunch._();

  /// Actions the native side may send.
  static const timerToggle = 'timer_toggle';
  static const timerStartPrefix = 'timer_start:';
  static const stopwatchToggle = 'stopwatch_toggle';
  static const stopwatchLap = 'stopwatch_lap';
  static const pomodoroToggle = 'pomodoro_toggle';

  static Future<void> apply(Map<String, String> launch) async {
    final mode =
        AppMode.values.where((m) => m.name == launch['mode']).firstOrNull;
    if (mode == null) return;

    // A widget for a mode the user hid must still open it.
    if (ModePrefs.disabled.value.contains(mode)) {
      await ModePrefs.setEnabled(mode, true);
    }
    await ModePrefs.setCurrent(mode);

    final action = launch['action'];
    if (action == null) return;
    if (action == timerToggle) {
      final timer = TimerController.instance;
      timer.running ? timer.pause() : timer.start();
    } else if (action.startsWith(timerStartPrefix)) {
      final seconds = int.tryParse(action.substring(timerStartPrefix.length));
      final timer = TimerController.instance;
      if (seconds != null && seconds > 0 && timer.phase == TimerPhase.idle) {
        timer.setTotal(seconds);
      }
      timer.start();
    } else if (action == stopwatchToggle) {
      final stopwatch = StopwatchController.instance;
      stopwatch.running ? stopwatch.stop() : stopwatch.start();
    } else if (action == stopwatchLap) {
      StopwatchController.instance.lap();
    } else if (action == pomodoroToggle) {
      PomodoroLive.requestToggle();
    }
  }
}
