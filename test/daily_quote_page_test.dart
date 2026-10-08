import 'package:enfo/daily_quote.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/notifications_page.dart';
import 'package:enfo/ui/atoms/app_switch.dart';
import 'package:enfo/ui/molecules/time_wheels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('notifications page turns the daily quote on and off',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    DailyQuote.debugReset();
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationsPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Daily focus quote'), findsOneWidget);
    expect(find.byType(TimeWheels), findsNothing);

    await tester.tap(find.byType(AppSwitch).last);
    await tester.pumpAndSettle();
    expect(find.byType(TimeWheels), findsOneWidget);
    expect(find.textContaining('Today:'), findsOneWidget);
    expect(DailyQuote.enabled, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('focus_quote_enabled'), isTrue);

    await tester.tap(find.byType(AppSwitch).last);
    await tester.pumpAndSettle();
    expect(find.byType(TimeWheels), findsNothing);
    expect(DailyQuote.enabled, isFalse);
  });
}
