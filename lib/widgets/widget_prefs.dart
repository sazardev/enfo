import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for the home-screen widgets.
class WidgetPrefs {
  static const _dynamicKey = 'widgets_dynamic_color';

  /// true = follow the system's Material You colors (Android 12+); false =
  /// use Enfo's own accent, like the app does. Widgets on older Android
  /// always use the accent.
  static final dynamicColor = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dynamicColor.value = prefs.getBool(_dynamicKey) ?? true;
  }

  static Future<void> setDynamicColor(bool value) async {
    dynamicColor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicKey, value);
  }
}
