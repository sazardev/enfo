import 'dart:convert';

import 'package:enfo/accent_color_page.dart';
import 'package:enfo/clock_style_page.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/data_page.dart';
import 'package:enfo/history.dart';
import 'package:enfo/home.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/onboarding.dart';
import 'package:enfo/settings.dart';
import 'package:enfo/stats.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_style.dart';
import 'package:enfo/ui/design/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical sizes of the screens the app is meant to look good on.
const _screens = <String, Size>{
  'watch': Size(200, 200),
  'watch-tall': Size(192, 240),
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tablet-landscape': Size(1280, 800),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

Widget _app(Widget home, {UiSize uiSize = UiSize.normal}) {
  AppPreferences.uiSize.value = uiSize;
  return MaterialApp(
    theme: Themes.light(Themes.defaultAccent),
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    // Same text/icon scaling as main().
    builder: (context, child) {
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
    home: home,
  );
}

Map<String, Object> _seed() {
  final now = DateTime.now();
  final sessions = [
    for (var i = 0; i < 14; i++)
      PomodoroSession(
        isWork: i.isEven,
        startedAt: now.subtract(Duration(hours: 30 - i * 2)),
        endedAt: now.subtract(Duration(hours: 30 - i * 2, minutes: -25)),
        plannedSeconds: 1500,
        focusedSeconds: 1500 - (i % 3) * 300,
        pauseCount: i % 3,
        pausedSeconds: (i % 3) * 40,
        completed: i % 4 != 3,
      ),
  ];
  return {
    'onboarded': true,
    'session_history': jsonEncode([for (final s in sessions) s.toJson()]),
  };
}

void main() {
  setUpAll(() async {
    // Real glyph metrics: Ahem (the test default) is far wider than the
    // app's Geist Mono and would report overflows that don't exist.
    final loader = FontLoader('GeistMono');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/GeistMono-$w.ttf'));
    }
    await loader.load();
  });

  setUp(() => SharedPreferences.setMockInitialValues(_seed()));

  final screens = <String, Widget Function()>{
    'home': () => const Home(),
    'settings': () => const Settings(),
    'stats': () => const Stats(),
    'data': () => const DataPage(),
    'onboarding': () => const Onboarding(),
    'clock styles': () => const ClockStylePage(selected: ClockStyle.ring),
    'accent': () => AccentColorPage(
          colors: Themes.colors,
          selected: Themes.defaultAccent,
        ),
  };

  for (final screen in screens.entries) {
    for (final size in _screens.entries) {
      testWidgets('${screen.key} fits on ${size.key}', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(screen.value()));
        // Home has a ticking clock, so settle by time, not by idleness.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });
    }
  }

  test('form factor thresholds', () {
    FormFactor of(double w, double h) => Responsive.fromSize(Size(w, h)).factor;
    expect(of(200, 200), FormFactor.watch);
    expect(of(310, 280), FormFactor.compact); // smallest Windows window
    expect(of(390, 844), FormFactor.compact);
    expect(of(700, 500), FormFactor.medium);
    expect(of(1280, 800), FormFactor.expanded);
    expect(Responsive.fromSize(const Size(844, 390)).isWide, true);
    expect(Responsive.fromSize(const Size(390, 844)).isWide, false);
  });

  testWidgets('settings is master-detail on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Settings()));
    await tester.pump(const Duration(milliseconds: 600));

    // List and the first section's page are on screen at once.
    expect(find.text('Tiempos'), findsWidgets);
    expect(find.text('Ritmo de enfoque'), findsNothing);
    expect(find.text('Manual'), findsOneWidget);

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsNothing);
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watch home keeps only the timer and two buttons',
      (tester) async {
    tester.view.physicalSize = const Size(200, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Home()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.timelapse_rounded), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}
