import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gen/app_localizations.dart';

/// Languages the app is translated into, each named in its own language
/// (so it's readable even when the app is in a language you can't read).
const languageNames = <String, String>{
  'en': 'English',
  'es': 'Español',
  'ja': '日本語',
  'fr': 'Français',
  'pt': 'Português',
  'de': 'Deutsch',
  'hi': 'हिन्दी',
  'ko': '한국어',
  'zh': '中文',
};

/// The supported language code for [code], English when unsupported.
String resolveLanguage(String? code) =>
    languageNames.containsKey(code) ? code! : 'en';

/// The user's language choice. A null [locale] means "follow the system",
/// which falls back to English when the system language isn't supported.
class LocaleController {
  static const _key = 'locale';

  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    locale.value = code == null ? null : Locale(code);
  }

  static Future<void> set(Locale? value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value.languageCode);
    }
  }
}

extension AppL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Translations without a BuildContext, for code that talks to the user
/// outside the widget tree (notifications). Follows the same rule as the
/// app: the chosen language (or the system's, if supported), else English.
AppLocalizations currentL10n() {
  final chosen = LocaleController.locale.value?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(resolveLanguage(chosen)));
}
