import 'package:enfo/clock_style_page.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_frame.dart';
import 'package:enfo/ui/clock/clock_style.dart';
import 'package:enfo/ui/clock/clock_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(ClockStyle style, ClockFrame frame,
    {Size size = const Size(300, 300)}) {
  final cs = Themes.light(Colors.lime).colorScheme;
  return MaterialApp(
    theme: Themes.light(Colors.lime),
    home: Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          size: size,
          child: ClockView(
            style: style,
            frame: frame,
            palette:
                ClockPalette.of(cs, rest: frame.isRest, paused: frame.paused),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('every clock style renders', () {
    for (final style in ClockStyle.values) {
      testWidgets(style.name, (tester) async {
        for (final progress in [0.0, 0.37, 0.999, 1.0]) {
          for (final phase in ClockPhase.values) {
            for (final rest in [false, true]) {
              for (final word in [false, true]) {
                await tester.pumpWidget(_host(
                  style,
                  ClockFrame(
                    progress: progress,
                    totalSeconds: 25 * 60,
                    isRest: rest,
                    phase: phase,
                    wordMode: word,
                    time: 4.2,
                  ),
                ));
                expect(tester.takeException(), isNull);
              }
            }
          }
        }
      });

      testWidgets('${style.name} survives tiny and wide boxes', (tester) async {
        final frame = ClockFrame(progress: 0.5, totalSeconds: 90 * 60, time: 1);
        for (final size in const [
          Size(60, 60),
          Size(400, 120),
          Size(120, 400)
        ]) {
          await tester.pumpWidget(_host(style, frame, size: size));
          expect(tester.takeException(), isNull);
        }
      });
    }
  });

  test('styles round-trip through their persisted name', () {
    for (final s in ClockStyle.values) {
      expect(ClockStyle.values.byName(s.name), s);
    }
    expect(ClockStyle.ring.step(-1), ClockStyle.values.last);
    expect(ClockStyle.values.last.step(1), ClockStyle.ring);
  });

  testWidgets('picker lists styles and saves the tapped one', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: Themes.light(Colors.lime),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ClockStylePage(selected: ClockStyle.ring),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Estilo de reloj'), findsOneWidget);
    expect(find.text('Solo animación'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);

    await tester.ensureVisible(find.text('Tomate'));
    await tester.tap(find.text('Tomate'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(await ClockStyle.load(), ClockStyle.tomato);
  });

  testWidgets('picker sections collapse and combos apply style + accent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: Themes.light(Colors.lime),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ClockStylePage(selected: ClockStyle.ring),
    ));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Deep focus'), findsOneWidget);
    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byTooltip('Expand all'), findsOneWidget);
    expect(find.text('Tomato'), findsNothing);
    await tester.tap(find.byTooltip('Expand all'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Tomato'), findsOneWidget);

    await tester.tap(find.text('Deep focus'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(await ClockStyle.load(), ClockStyle.orbit);
    expect(Themes.accent.toARGB32(), Colors.indigo.toARGB32());
  });

  testWidgets('picker app bar stays slim on a watch and normal on a phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Future<double> barHeight(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(MaterialApp(
        theme: Themes.light(Colors.lime),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ClockStylePage(selected: ClockStyle.ring),
      ));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull);
      return tester.getSize(find.byType(AppBar)).height;
    }

    addTearDown(tester.view.reset);
    expect(await barHeight(const Size(200, 200)), 40);
    expect(await barHeight(const Size(400, 800)), kToolbarHeight);
  });
}
