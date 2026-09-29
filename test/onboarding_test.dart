import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/home.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/onboarding.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/atoms/accent_swatch.dart';
import 'package:enfo/ui/clock/clock_combo.dart';
import 'package:enfo/ui/design/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _screens = <String, Size>{
  'watch': Size(200, 200),
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

/// Mirrors main(): theme, locale and text scaling all react to the wizard.
Widget _app() => AdaptiveTheme(
      light: Themes.light(Themes.accent),
      dark: Themes.dark(Themes.accent),
      initial: AdaptiveThemeMode.system,
      builder: (theme, dark) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        builder: (context, locale, _) => MaterialApp(
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
                child: child!,
              );
            },
          ),
          home: const Onboarding(),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  // The clock step runs a 1h animation, so pumpAndSettle would never end.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('GeistMono');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/GeistMono-$w.ttf'));
    }
    await loader.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await AppPreferences.load();
    await LocaleController.load();
    Themes.resetAccent();
    ModePrefs.disabled.value = {
      for (final m in AppMode.values)
        if (!m.core) m,
    };
    LocaleController.locale.value = const Locale('en');
  });

  testWidgets('every choice is applied and saved, then Start opens home',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await _settle(tester);

    // 1. Language re-translates the wizard on the spot.
    expect(find.text('Welcome to Enfo'), findsOneWidget);
    await _tap(tester, find.text('Español'));
    expect(find.text('Bienvenido a Enfo'), findsOneWidget);
    await _tap(tester, find.text('English'));
    expect(find.text('Welcome to Enfo'), findsOneWidget);
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en');
    await _tap(tester, find.text('Next'));

    // 2. Modes: turning one off is applied at once and shortens the flow.
    expect(find.text('Your tools'), findsOneWidget);
    expect(find.text('More tools'), findsOneWidget);
    await _tap(tester, find.byType(Switch).at(5)); // world clock
    expect(ModePrefs.disabled.value, contains(AppMode.world));
    await _tap(tester, find.byType(Switch).at(6)); // events: turn a new one on
    expect(ModePrefs.disabled.value, isNot(contains(AppMode.event)));
    await _tap(tester, find.text('Next'));

    // 3. Rhythm.
    expect(find.text('Your rhythm'), findsOneWidget);
    await _tap(tester, find.text('Extended'));
    await _tap(tester, find.text('Next'));

    // 4. Theme (System by default) + accent, with the preview below.
    expect(find.text('Make it yours'), findsOneWidget);
    expect(AdaptiveTheme.of(tester.element(find.text('Dark'))).mode.isSystem,
        true);
    expect(find.text('Preview'), findsOneWidget);
    await _tap(tester, find.text('Dark'));
    expect(
        AdaptiveTheme.of(tester.element(find.text('Dark'))).mode.isDark, true);
    await _tap(tester, find.byType(AccentSwatch).first); // red
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('accent_color'), Themes.colors.first.toARGB32());

    // 5. A combo sets clock style AND accent together (same step).
    final combo = ClockCombo.deepFocus;
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await _tap(tester, find.text(combo.labelOf(l10n)));
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('clock_style'), combo.style.name);
    expect(prefs.getInt('accent_color'), combo.color.toARGB32());
    await _tap(tester, find.text('Next'));

    // 6. Display.
    expect(find.text('Display'), findsOneWidget);
    await _tap(tester, find.text('Next'));

    // 7. Options.
    expect(find.text('Final touches'), findsOneWidget);
    expect(AppPreferences.autoStartNext.value, false);
    await _tap(tester, find.byType(Switch).first);
    expect(AppPreferences.autoStartNext.value, true);
    await _tap(tester, find.text('Start'));

    expect(find.byType(Home), findsOneWidget);
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('work_minutes'), 50);
    expect(prefs.getInt('rest_minutes'), 10);
    expect(prefs.getBool('onboarded'), true);
    expect(prefs.getBool('auto_start_next'), true);
  });

  testWidgets('Skip finishes with what was chosen so far', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await _settle(tester);

    await _tap(tester, find.text('Next'));
    await _tap(tester, find.text('Next'));
    await _tap(tester, find.text('Deep'));
    await _tap(tester, find.text('Skip'));

    expect(find.byType(Home), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('work_minutes'), 90);
    expect(prefs.getBool('onboarded'), true);
  });

  testWidgets('Back returns to the previous step; hidden on the first',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(tester.widget<Visibility>(find.byType(Visibility)).visible, false);
    await _tap(tester, find.text('Next'));
    expect(find.text('Your tools'), findsOneWidget);
    await _tap(tester, find.text('Back'));
    expect(find.text('Welcome to Enfo'), findsOneWidget);
  });

  for (final size in _screens.entries) {
    testWidgets('all steps fit on ${size.key}', (tester) async {
      tester.view.physicalSize = size.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await _settle(tester);

      var steps = 1;
      while (find.text('Next').evaluate().isNotEmpty) {
        expect(tester.takeException(), isNull);
        await _tap(tester, find.text('Next'));
        steps++;
      }
      expect(tester.takeException(), isNull);
      // Watch keeps two steps (language, rhythm); the rest six (the
      // permissions step only exists on Android).
      expect(steps, size.key == 'watch' ? 2 : 6);
      expect(find.text('Start'), findsOneWidget);
    });
  }
}
