import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ClockFormat { system, h12, h24 }

/// User-chosen interface size, on top of the automatic per-screen scale.
/// Lets a TV or a car display be made bigger, or a small screen denser.
enum UiSize {
  small(0.9),
  normal(1.0),
  large(1.25),
  extraLarge(1.5);

  const UiSize(this.multiplier);
  final double multiplier;
}

/// Simple display/behavior toggles. Each is a [ValueNotifier] so any screen
/// reading it (home, the clock bar, the dial) updates the moment it changes
/// in settings. Loaded once at startup, so reads are synchronous.
class AppPreferences {
  static const _showClockKey = 'show_clock';
  static const _clockFormatKey = 'clock_format';
  static const _autoStartKey = 'auto_start_next';
  static const _uiSizeKey = 'ui_size';

  static final showClock = ValueNotifier<bool>(true);
  static final clockFormat = ValueNotifier<ClockFormat>(ClockFormat.system);
  static final autoStartNext = ValueNotifier<bool>(false);
  static final uiSize = ValueNotifier<UiSize>(UiSize.normal);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    showClock.value = prefs.getBool(_showClockKey) ?? true;
    autoStartNext.value = prefs.getBool(_autoStartKey) ?? false;
    final size = prefs.getString(_uiSizeKey);
    uiSize.value = UiSize.values.firstWhere(
      (u) => u.name == size,
      orElse: () => UiSize.normal,
    );
    final format = prefs.getString(_clockFormatKey);
    clockFormat.value = ClockFormat.values.firstWhere(
      (f) => f.name == format,
      orElse: () => ClockFormat.system,
    );
  }

  static Future<void> setShowClock(bool value) async {
    showClock.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showClockKey, value);
  }

  static Future<void> setClockFormat(ClockFormat value) async {
    clockFormat.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clockFormatKey, value.name);
  }

  static Future<void> setAutoStartNext(bool value) async {
    autoStartNext.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartKey, value);
  }

  static Future<void> setUiSize(UiSize value) async {
    uiSize.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiSizeKey, value.name);
  }
}
