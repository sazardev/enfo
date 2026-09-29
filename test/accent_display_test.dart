import 'package:enfo/accent_color_page.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/bar_buttons.dart';
import 'package:enfo/display_page.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/live_clock.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/atoms/accent_swatch.dart';
import 'package:enfo/ui/design/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget home) => MaterialApp(
      theme: Themes.light(Themes.defaultAccent),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

Color _previewPrimary(WidgetTester tester) => tester
    .widget<AnimatedTheme>(find.byWidgetPredicate(
      (w) => w is AnimatedTheme && w.duration == Motion.medium,
    ))
    .data
    .colorScheme
    .primary;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('accent', () {
    test('legacy index migrates; new key wins', () async {
      SharedPreferences.setMockInitialValues({'defaultIndex': 3});
      await Themes.loadAccent();
      expect(Themes.accent, Colors.deepPurple);

      SharedPreferences.setMockInitialValues(
          {'defaultIndex': 3, 'accent_color': 0xFF336699});
      await Themes.loadAccent();
      expect(Themes.accent.toARGB32(), 0xFF336699);

      await Themes.saveAccent(Colors.teal);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('accent_color'), Colors.teal.toARGB32());
    });

    testWidgets('preview follows swatches and custom hex; apply returns it',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Color? result;
      await tester.pumpWidget(_wrap(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Navigator.of(context).push(
            MaterialPageRoute<Color>(
              builder: (_) => AccentColorPage(
                colors: Themes.colors,
                selected: Themes.defaultAccent,
              ),
            ),
          ),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final before = _previewPrimary(tester);
      await tester.tap(find.byType(AccentSwatch).first); // red
      await tester.pumpAndSettle();
      expect(_previewPrimary(tester), isNot(before));
      expect(_previewPrimary(tester),
          Themes.light(Themes.colors.first).colorScheme.primary);

      await tester.tap(find.bySemanticsLabel('Custom color'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '336699');
      await tester.pumpAndSettle();
      expect(_previewPrimary(tester),
          Themes.light(const Color(0xFF336699)).colorScheme.primary);

      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result?.toARGB32(), 0xFF336699);
    });
  });

  group('display', () {
    testWidgets('toggle hides the clock and persists', (tester) async {
      await AppPreferences.load();
      await tester.pumpWidget(_wrap(const DisplayPage()));
      await tester.pumpAndSettle();
      expect(AppPreferences.showClock.value, true);

      // The menu-button switches come first; the show-clock one follows them.
      final showClock = find.byType(Switch).at(BarButton.values.length);
      await tester.ensureVisible(showClock);
      await tester.tap(showClock);
      await tester.pumpAndSettle();
      expect(AppPreferences.showClock.value, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_clock'), false);
      AppPreferences.showClock.value = true;
    });

    testWidgets('clock format switches between 12h and 24h', (tester) async {
      Future<String> render(ClockFormat format) async {
        AppPreferences.clockFormat.value = format;
        await tester.pumpWidget(_wrap(const Scaffold(body: LiveClock())));
        await tester.pump();
        return tester.widget<Text>(find.byType(Text)).data!;
      }

      expect(await render(ClockFormat.h12), matches(RegExp(r'(AM|PM)')));
      expect(await render(ClockFormat.h24), isNot(matches(RegExp(r'(AM|PM)'))));
      AppPreferences.clockFormat.value = ClockFormat.system;
    });
  });
}
