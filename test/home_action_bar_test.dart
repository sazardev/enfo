import 'package:enfo/home.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => MaterialApp(
      theme: Themes.light(Themes.defaultAccent),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Home(),
    );

Future<void> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  expect(tester.takeException(), isNull);
}

/// Centers of the always-present home buttons, in tab order.
List<Offset> _centers(WidgetTester tester) => [
      for (final icon in [
        Icons.tune_rounded,
        Icons.bar_chart_rounded,
        Icons.timelapse_rounded,
        Icons.play_arrow_rounded,
      ])
        tester.getCenter(find.byIcon(icon)),
    ];

void main() {
  for (final entry in {
    'tablet portrait': const Size(800, 1280),
    'tablet landscape': const Size(1280, 800),
  }.entries) {
    testWidgets('${entry.key}: buttons stack vertically on the right',
        (tester) async {
      await _pump(tester, entry.value);
      final c = _centers(tester);

      // Same column, top to bottom.
      expect(c[0].dx, closeTo(c[1].dx, 1));
      expect(c[1].dx, closeTo(c[2].dx, 1));
      expect(c[1].dy, greaterThan(c[0].dy));
      expect(c[2].dy, greaterThan(c[1].dy));
      // Play is the last button: bottom of the column.
      expect(c[3].dx, closeTo(c[0].dx, 1));
      expect(c[3].dy, greaterThan(c[2].dy));
      // The clock stays dead centre and big, whatever the bar does.
      final dial = tester.getRect(find.byType(ClockView));
      expect(dial.center.dx, closeTo(entry.value.width / 2, 1));
      expect(dial.center.dy, closeTo(entry.value.height / 2, 1));
      expect(dial.shortestSide, greaterThan(entry.value.shortestSide * 0.5));
      // Hugging the right edge.
      expect(c[0].dx, greaterThan(entry.value.width * 0.85));
      // Big, easy targets: the gap between centers is at least a 56dp button.
      expect(c[1].dy - c[0].dy, greaterThanOrEqualTo(56));
    });
  }

  testWidgets('phone portrait: buttons in a row at the bottom, large',
      (tester) async {
    const size = Size(390, 844);
    await _pump(tester, size);
    final c = _centers(tester);

    expect(c[0].dy, closeTo(c[1].dy, 1));
    expect(c[1].dy, closeTo(c[2].dy, 1));
    expect(c[1].dx, greaterThan(c[0].dx));
    expect(c[2].dx, greaterThan(c[1].dx));
    // Play is the last button: right end of the row.
    expect(c[3].dy, closeTo(c[0].dy, 1));
    expect(c[3].dx, greaterThan(c[2].dx));
    final dial = tester.getRect(find.byType(ClockView));
    expect(dial.center.dx, closeTo(size.width / 2, 1));
    expect(dial.center.dy, closeTo(size.height / 2, 1));
    expect(dial.width, greaterThan(size.width * 0.7));
    expect(c[0].dy, greaterThan(size.height * 0.85));
    // Spacing between centers = button size + gap, so buttons are >= 44dp.
    expect(c[1].dx - c[0].dx, greaterThanOrEqualTo(52));
    // Everything fits on screen.
    for (final p in c) {
      expect(p.dx, inInclusiveRange(0, size.width));
    }
  });

  testWidgets('small phone still fits every button in one row', (tester) async {
    const size = Size(320, 640);
    await _pump(tester, size);
    for (final p in _centers(tester)) {
      expect(p.dx, inInclusiveRange(0, size.width));
    }
  });

  testWidgets('short landscape phone keeps the vertical bar on screen',
      (tester) async {
    const size = Size(740, 340);
    await _pump(tester, size);
    for (final p in _centers(tester)) {
      expect(p.dy, inInclusiveRange(0, size.height));
    }
  });

  testWidgets('play starts the timer and turns into pause', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
