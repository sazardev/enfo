import 'package:enfo/splash.dart';
import 'package:enfo/ui/brand/enfo_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const SplashScreen(next: Scaffold(body: Text('home'))),
    );

void main() {
  testWidgets('builds the logo, then fades into the app', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.byType(EnfoMark), findsOneWidget);
    expect(find.text('home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('home'), findsNothing);

    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a tap skips it', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(EnfoMark));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('reduced motion goes straight to the finished logo',
      (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
