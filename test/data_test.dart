import 'dart:convert';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/app_data.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/data_page.dart';
import 'package:enfo/history.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

PomodoroSession _session(DateTime start) => PomodoroSession(
      isWork: true,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 25)),
      plannedSeconds: 1500,
      focusedSeconds: 1500,
      pauseCount: 0,
      pausedSeconds: 0,
      completed: true,
    );

Map<String, Object> _populated() => {
      'onboarded': true,
      'work_minutes': 50,
      'rest_minutes': 10,
      'notifications_enabled': false,
      'accent_color': 0xFF336699,
      'show_clock': false,
      'auto_start_next': true,
      'ui_size': 'large',
      'clock_style': 'ring',
      'locale': 'es',
      'session_history': jsonEncode([_session(DateTime(2026, 9, 1)).toJson()]),
    };

const _modeKeys = {'mode_seen', 'mode_disabled'};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(_populated());
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await AppPreferences.load();
    await LocaleController.load();
    await Themes.loadAccent();
  });

  group('AppData', () {
    test('resetSettings restores defaults but keeps history + onboarded',
        () async {
      expect(AppPreferences.autoStartNext.value, true);
      expect(Themes.accent.toARGB32(), 0xFF336699);

      await AppData.resetSettings();

      final prefs = await SharedPreferences.getInstance();
      // Reloading the mode list re-records its own defaults.
      expect(prefs.getKeys().difference(_modeKeys),
          {'onboarded', 'session_history'});
      expect(AppPreferences.autoStartNext.value, false);
      expect(AppPreferences.showClock.value, true);
      expect(AppPreferences.uiSize.value, UiSize.normal);
      expect(LocaleController.locale.value, isNull);
      expect(Themes.accent, Themes.defaultAccent);
      expect(await SessionHistory.load(), hasLength(1));
    });

    test('eraseAll removes everything, including the onboarded flag', () async {
      await AppData.eraseAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().difference(_modeKeys), isEmpty);
      expect(await _isOnboarded(), false);
      expect(await SessionHistory.load(), isEmpty);
      expect(Themes.accent, Themes.defaultAccent);
    });

    test('a timer closing after a clear cannot resurrect the history',
        () async {
      final runningSince = DateTime.now().subtract(const Duration(minutes: 5));
      await AppData.clearHistory();

      // Started before the clear -> dropped (this is the dial's dispose save).
      await SessionHistory.add(_session(runningSince));
      expect(await SessionHistory.load(), isEmpty);

      // Started after the clear -> kept.
      await SessionHistory.add(_session(DateTime.now()));
      expect(await SessionHistory.load(), hasLength(1));
    });
  });

  group('DataPage', () {
    Widget host() => AdaptiveTheme(
          light: Themes.light(Themes.defaultAccent),
          dark: Themes.dark(Themes.defaultAccent),
          initial: AdaptiveThemeMode.light,
          builder: (theme, dark) => MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const DataPage(),
          ),
        );

    testWidgets('nothing changes until the confirm row is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.text('1 saved entry'), findsOneWidget);

      await tester.tap(find.text('Reset settings'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm: reset settings'), findsOneWidget);
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('work_minutes'), 50); // untouched so far

      // Cancel backs out.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm: reset settings'), findsNothing);

      await tester.tap(find.text('Reset settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm: reset settings'));
      await tester.pumpAndSettle();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('work_minutes'), isNull);
      expect(find.text('Settings restored to defaults.'), findsOneWidget);
      expect(find.text('1 saved entry'), findsOneWidget); // history kept
    });

    testWidgets('clear history empties the count', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm: clear history'));
      await tester.pumpAndSettle();

      expect(find.text('No saved activity'), findsOneWidget);
      expect(find.text('History cleared.'), findsOneWidget);
    });

    testWidgets('erase everything lands on the welcome screen', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erase everything'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm: erase everything'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Enfo'), findsOneWidget); // onboarding
      expect(find.byType(DataPage), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      // Only what the freshly opened onboarding wrote itself may remain.
      expect(prefs.containsKey('session_history'), false);
      expect(prefs.containsKey('onboarded'), false);
    });

    testWidgets('replaying the intro deletes nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show the intro again'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Enfo'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('work_minutes'), 50);
      expect(prefs.getBool('onboarded'), true);
      expect(await SessionHistory.load(), hasLength(1));
      // The intro starts from the rhythm in use, not the classic preset.
      await tester.tap(find.text('Next')); // past the welcome step
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // past the language step
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // past the modes step
      await tester.pumpAndSettle();
      expect(find.text('50/10 min'), findsWidgets);
    });
  });
}

Future<bool> _isOnboarded() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarded') ?? false;
}
