import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:window_manager/window_manager.dart';

import 'app_preferences.dart';
import 'haptics/haptics.dart';
import 'modes/alarm/alarm_service.dart';
import 'modes/app_shortcuts.dart';
import 'modes/clock/clock_prefs.dart';
import 'modes/fullscreen.dart';
import 'modes/stopwatch/stopwatch_controller.dart';
import 'modes/timer/timer_controller.dart';
import 'modes/world/world_prefs.dart';
import 'modes/mode_host.dart';
import 'modes/mode_prefs.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'modes/mode_services.dart';
import 'bar_buttons.dart';
import 'onboarding.dart';
import 'pomodoro_state.dart';
import 'presets.dart';
import 'splash.dart';
import 'ui/design/responsive.dart';
import 'widgets/widget_prefs.dart';
import 'widgets/widget_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final onboarded = await Presets.isOnboarded();
  await LocaleController.load();

  await Themes.loadAccent();
  await AppPreferences.load();
  await Haptics.load();
  await ModePrefs.load();
  await BarButtons.load();
  await Fullscreen.load();
  await ClockPrefs.load();
  await TimerController.instance.load();
  await StopwatchController.instance.load();
  await PomodoroStore.load();
  tzdata.initializeTimeZones();
  await WorldPrefs.load();
  await AlarmService.load();
  await loadModeServices();
  await WidgetPrefs.load();

  if (Platform.isAndroid) {
    MobileAds.instance.initialize();
  }

  runApp(
    Main(
      savedThemeMode: savedThemeMode,
      onboarded: onboarded,
    ),
  );

  // Android home-screen widgets: keep them in step with the app.
  WidgetSync.start();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(450, 450),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      center: true,
      title: 'Enfo',
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(310, 280),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }
}

/// Lets a mouse or trackpad drag-scroll, not just touch.
class _AnyDeviceScroll extends MaterialScrollBehavior {
  const _AnyDeviceScroll();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class Main extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final bool onboarded;

  const Main({
    super.key,
    this.savedThemeMode,
    required this.onboarded,
  });

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: Themes.light(Themes.accent),
        dark: Themes.dark(Themes.accent),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) {
          return ValueListenableBuilder<Locale?>(
            valueListenable: LocaleController.locale,
            builder: (context, locale, _) => MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              navigatorKey: appNavigatorKey,
              // Mouse and trackpad drag-scroll like a finger (wheels, lists).
              scrollBehavior: const _AnyDeviceScroll(),
              theme: theme,
              darkTheme: darkTheme,
              locale: locale,
              // Scales text and icons for the screen (bigger on tablets/TVs,
              // plus the user's UI-size choice). Layout code reads the same
              // factor through Responsive.of.
              builder: (context, child) => ValueListenableBuilder<UiSize>(
                valueListenable: AppPreferences.uiSize,
                builder: (context, _, __) {
                  final media = MediaQuery.of(context);
                  final scale = Responsive.of(context).scale;
                  final systemScale = media.textScaler.scale(14) / 14;
                  return MediaQuery(
                    data: media.copyWith(
                      textScaler: TextScaler.linear(systemScale * scale),
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 24 * scale),
                      child: AppShortcuts(child: child!),
                    ),
                  );
                },
              ),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Anything we don't translate falls back to English.
              localeResolutionCallback: (deviceLocale, supported) {
                return Locale(resolveLanguage(deviceLocale?.languageCode));
              },
              // Returning users get the short logo splash; first run goes straight
              // to the onboarding, whose welcome step builds the logo itself.
              home: widget.onboarded
                  ? const SplashScreen(next: ModeHost())
                  : const Onboarding(),
            ),
          );
        });
  }
}
