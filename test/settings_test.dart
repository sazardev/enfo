import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/settings.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() {
  return ValueListenableBuilder<Locale?>(
    valueListenable: LocaleController.locale,
    builder: (context, locale, _) => MaterialApp(
      theme: Themes.light(Themes.accent),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Settings(),
    ),
  );
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('settings hub opens every page and switches language',
      (tester) async {
    LocaleController.locale.value = const Locale('en');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Timers'), findsOneWidget);
    expect(find.text('25 min focus · 5 min rest'), findsOneWidget);

    for (final title in ['Timers', 'Appearance', 'Notifications', 'Language']) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
      await _back(tester);
    }

    // Switch to Spanish from the language page; hub updates on return.
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    await _back(tester);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Tiempos'), findsOneWidget);
  });

  testWidgets('manual timer +1 button changes minutes', (tester) async {
    LocaleController.locale.value = const Locale('en');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('+1').first);
    await tester.pumpAndSettle();
    expect(find.text('26 min'), findsOneWidget);
    expect(find.text('One full cycle: 31 min'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('work_minutes'), 26);
  });
}
