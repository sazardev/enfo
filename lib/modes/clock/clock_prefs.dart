import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/gen/app_localizations.dart';

/// Designs for the Clock mode.
enum ClockFace {
  ring,
  digital,
  analog,
  split,
  day;

  String labelOf(AppLocalizations l) => switch (this) {
        ClockFace.ring => l.faceRing,
        ClockFace.digital => l.faceDigital,
        ClockFace.analog => l.faceAnalog,
        ClockFace.split => l.faceSplit,
        ClockFace.day => l.faceDay,
      };

  ClockFace step(int delta) =>
      ClockFace.values[(index + delta) % ClockFace.values.length];
}

/// How the Clock mode looks. Notifiers so the clock, its settings page and
/// the previews all update the moment something changes.
class ClockPrefs {
  static const _faceKey = 'clock_face';
  static const _secondsKey = 'clock_show_seconds';
  static const _dateKey = 'clock_show_date';
  static const _blinkKey = 'clock_blink_colon';

  static final face = ValueNotifier<ClockFace>(ClockFace.ring);
  static final showSeconds = ValueNotifier<bool>(true);
  static final showDate = ValueNotifier<bool>(true);
  static final blinkColon = ValueNotifier<bool>(true);

  static Listenable get changes =>
      Listenable.merge([face, showSeconds, showDate, blinkColon]);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_faceKey);
    face.value = ClockFace.values.firstWhere(
      (f) => f.name == name,
      orElse: () => ClockFace.ring,
    );
    showSeconds.value = prefs.getBool(_secondsKey) ?? true;
    showDate.value = prefs.getBool(_dateKey) ?? true;
    blinkColon.value = prefs.getBool(_blinkKey) ?? true;
  }

  static Future<void> setFace(ClockFace value) async {
    face.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_faceKey, value.name);
  }

  static Future<void> setShowSeconds(bool value) async {
    showSeconds.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_secondsKey, value);
  }

  static Future<void> setShowDate(bool value) async {
    showDate.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dateKey, value);
  }

  static Future<void> setBlinkColon(bool value) async {
    blinkColon.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blinkKey, value);
  }
}
