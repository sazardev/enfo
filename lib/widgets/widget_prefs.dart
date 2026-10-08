import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for the home-screen widgets.
class WidgetPrefs {
  static const _dynamicKey = 'widgets_dynamic_color';
  static const _quoteStyleKey = 'widgets_quote_style';

  /// true = follow the system's Material You colors (Android 12+); false =
  /// use Enfo's own accent, like the app does. Widgets on older Android
  /// always use the accent.
  static final dynamicColor = ValueNotifier<bool>(true);

  /// Decoration of the quote widget: 0 = classic (surface card, big quote
  /// mark), 1 = accent (filled with the container color).
  static final quoteStyle = ValueNotifier<int>(0);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dynamicColor.value = prefs.getBool(_dynamicKey) ?? true;
    quoteStyle.value = (prefs.getInt(_quoteStyleKey) ?? 0).clamp(0, 1);
  }

  static Future<void> setDynamicColor(bool value) async {
    dynamicColor.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dynamicKey, value);
  }

  static Future<void> setQuoteStyle(int value) async {
    quoteStyle.value = value.clamp(0, 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quoteStyleKey, quoteStyle.value);
  }
}
