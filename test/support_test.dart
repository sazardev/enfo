import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/support_page.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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
      home: const SupportPage(),
    ),
  );
}

void main() {
  testWidgets('support page offers rate, share and coffee', (tester) async {
    LocaleController.locale.value = const Locale('en');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Rate Enfo'), findsOneWidget);
    expect(find.text('Share Enfo'), findsOneWidget);
    expect(find.text('Buy me a coffee'), findsOneWidget);
  });

  testWidgets('rate and share taps survive missing platform plugins',
      (tester) async {
    LocaleController.locale.value = const Locale('en');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rate Enfo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share Enfo'));
    await tester.pumpAndSettle();
  });
}
