import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/modes/clock/clock_prefs.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/modes/world/world_prefs.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/design/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Loads the app's real font: the test default (Ahem) is far wider than
/// Geist Mono and would report overflows that don't exist.
Future<void> loadAppFonts() async {
  final loader = FontLoader('GeistMono');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/GeistMono-$w.ttf'));
  }
  await loader.load();
}

/// Fresh preferences + in-memory state for every test.
Future<void> resetTestState([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  await AppPreferences.load();
  await ModePrefs.load();
  await Fullscreen.load();
  await ClockPrefs.load();
  tzdata.initializeTimeZones();
  await WorldPrefs.load();
  await AlarmService.load();
  TimerController.instance.wipe();
  StopwatchController.instance.wipe();
  Alerts.reset();
  Fullscreen.active.value = false;
  Themes.resetAccent();
  LocaleController.locale.value = const Locale('en');
  nowProvider = DateTime.now;
}

/// A MaterialApp wired like main(): theme, locale and text scaling react.
Widget testApp(Widget home) => AdaptiveTheme(
      light: Themes.light(Themes.accent),
      dark: Themes.dark(Themes.accent),
      initial: AdaptiveThemeMode.light,
      builder: (theme, dark) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: dark,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => ValueListenableBuilder<UiSize>(
            valueListenable: AppPreferences.uiSize,
            builder: (context, _, __) {
              final media = MediaQuery.of(context);
              final scale = Responsive.of(context).scale;
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(scale)),
                child: IconTheme.merge(
                  data: IconThemeData(size: 24 * scale),
                  child: child!,
                ),
              );
            },
          ),
          home: home,
        ),
      ),
    );

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
