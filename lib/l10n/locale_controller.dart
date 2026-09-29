import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gen/app_localizations.dart';

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
/// app: Spanish if chosen (or the system is Spanish), otherwise English.
AppLocalizations currentL10n() {
  final chosen = LocaleController.locale.value?.languageCode ??
      PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(chosen == 'es' ? 'es' : 'en'));
}
