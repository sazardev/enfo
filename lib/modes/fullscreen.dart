import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app_mode.dart';
import 'mode_prefs.dart';
import 'tool_history.dart';
import '../haptics/haptics.dart';

/// Full-screen "display" state: hides all chrome, keeps the screen on, and
/// (optionally) dims it — Enfo as a desk / nightstand clock.
///
/// Also owns the screen-awake decision: awake while in full screen, and
/// while the Clock mode is showing when [keepClockAwake] is on.
class Fullscreen {
  static const _dimKey = 'fullscreen_dim';
  static const _clockAwakeKey = 'clock_keep_awake';

  static final active = ValueNotifier<bool>(false);

  /// Index into [dimLevels]; 0 = no dimming.
  static final dimStep = ValueNotifier<int>(0);
  static const dimLevels = [0.0, 0.35, 0.6, 0.8];
  static double get dimOpacity => dimLevels[dimStep.value];

  static final keepClockAwake = ValueNotifier<bool>(true);

  static bool _awake = false;
  static DateTime? _since;
  static bool _wired = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dimStep.value = (prefs.getInt(_dimKey) ?? 0).clamp(0, dimLevels.length - 1);
    keepClockAwake.value = prefs.getBool(_clockAwakeKey) ?? true;
  }

  /// Hooks the awake logic to the state it depends on. Idempotent.
  static void wire() {
    if (_wired) return;
    _wired = true;
    active.addListener(_syncAwake);
    ModePrefs.current.addListener(_syncAwake);
    keepClockAwake.addListener(_syncAwake);
    _syncAwake();
  }

  static Future<void> setKeepClockAwake(bool value) async {
    keepClockAwake.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clockAwakeKey, value);
  }

  static Future<void> cycleDim() async {
    Haptics.select();
    dimStep.value = (dimStep.value + 1) % dimLevels.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dimKey, dimStep.value);
  }

  static bool get _wantAwake =>
      active.value ||
      (ModePrefs.current.value == AppMode.clock && keepClockAwake.value);

  static Future<void> _syncAwake() async {
    final want = _wantAwake;
    if (want == _awake) return;
    _awake = want;
    try {
      await WakelockPlus.toggle(enable: want);
    } catch (_) {
      // No wakelock plugin on this platform (or in tests): nothing to do.
    }
  }

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static Future<void> enter() async {
    if (active.value) return;
    Haptics.transition();
    active.value = true;
    _since = DateTime.now();
    try {
      if (_isDesktop) {
        await windowManager.ensureInitialized();
        await windowManager.setFullScreen(true);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (_) {
      // Chrome couldn't be hidden (unsupported platform / test): the app
      // still shows its immersive layout.
    }
  }

  static Future<void> exit() async {
    if (!active.value) return;
    Haptics.transition();
    active.value = false;
    try {
      if (_isDesktop) {
        await windowManager.setFullScreen(false);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}

    // Time spent as a display counts in the history (ignore accidental taps).
    final since = _since;
    _since = null;
    if (since != null) {
      final seconds = DateTime.now().difference(since).inSeconds;
      if (seconds >= 60) {
        await ToolHistory.add(ToolEvent(
          kind: ToolKind.display,
          at: since,
          seconds: seconds,
          outcome: ModePrefs.current.value.name,
        ));
      }
    }
  }

  static Future<void> toggle() => active.value ? exit() : enter();
}
