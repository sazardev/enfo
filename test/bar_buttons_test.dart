import 'package:enfo/bar_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BarButtons.hidden.value = <BarButton>{};
  });

  test('hiding a button is saved and restored', () async {
    await BarButtons.setVisible(BarButton.fullscreen, false);
    await BarButtons.setVisible(BarButton.stats, false);
    expect(BarButtons.hidden.value, {BarButton.fullscreen, BarButton.stats});

    BarButtons.hidden.value = <BarButton>{};
    await BarButtons.load();
    expect(BarButtons.hidden.value, {BarButton.fullscreen, BarButton.stats});

    await BarButtons.setVisible(BarButton.stats, true);
    expect(BarButtons.hidden.value, {BarButton.fullscreen});
  });

  testWidgets('BarButtonVisibility follows the setting', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: BarButtonVisibility(
        button: BarButton.modes,
        child: Text('modes button'),
      ),
    ));
    expect(find.text('modes button'), findsOneWidget);
    await BarButtons.setVisible(BarButton.modes, false);
    await tester.pump();
    expect(find.text('modes button'), findsNothing);
  });
}
