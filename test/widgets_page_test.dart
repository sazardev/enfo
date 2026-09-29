import 'package:enfo/widgets/widget_bridge.dart';
import 'package:enfo/widgets/widget_prefs.dart';
import 'package:enfo/widgets/widgets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  const channel = MethodChannel('com.sazarcode.enfo/widgets');
  final calls = <MethodCall>[];

  setUpAll(loadAppFonts);
  setUp(() async {
    await resetTestState();
    await WidgetPrefs.load();
    calls.clear();
    WidgetBridge.debugSupported = true;
  });
  tearDown(() {
    WidgetBridge.debugSupported = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockLauncher({required bool canPin, int? seed}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'canPin' => canPin,
        'systemSeed' => seed,
        'pin' => true,
        _ => null,
      };
    });
  }

  testWidgets('lists every widget and asks the launcher to pin one',
      (tester) async {
    setScreen(tester, const Size(420, 1400));
    mockLauncher(canPin: true, seed: 0xFF336699);
    await tester.pumpWidget(testApp(const WidgetsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Widgets'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded),
        findsNWidgets(WidgetKind.values.length));
    expect(find.text('Material You colors'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    final pin = calls.singleWhere((c) => c.method == 'pin');
    expect(pin.arguments, WidgetKind.values.first.name);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Material You switch is remembered', (tester) async {
    setScreen(tester, const Size(420, 1400));
    mockLauncher(canPin: true, seed: 0xFF336699);
    await tester.pumpWidget(testApp(const WidgetsPage()));
    await tester.pumpAndSettle();

    expect(WidgetPrefs.dynamicColor.value, true);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(WidgetPrefs.dynamicColor.value, false);
  });

  testWidgets(
      'before Android 12 there is no color choice; a launcher without pinning gets instructions',
      (tester) async {
    setScreen(tester, const Size(420, 1400));
    mockLauncher(canPin: false, seed: null);
    await tester.pumpWidget(testApp(const WidgetsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Material You colors'), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.textContaining('Long-press the home screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
