import 'package:enfo/app_preferences.dart';
import 'package:enfo/display_page.dart';
import 'package:enfo/appearance_page.dart';
import 'package:enfo/modes/activity_page.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/modes_page.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/notifications_page.dart';
import 'package:enfo/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Awkward in-between shapes: desktop windows dragged to any size, split
/// screen, foldables, and both orientations of the same device.
const _sizes = <Size>[
  Size(564, 704), // the window that overflowed the action bar
  Size(320, 480),
  Size(360, 640),
  Size(390, 844),
  Size(844, 390),
  Size(480, 320),
  Size(600, 600),
  Size(700, 500),
  Size(768, 1024),
  Size(1024, 768),
  Size(1280, 400),
  Size(400, 1280),
  Size(1920, 1080),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() async {
    await resetTestState({'onboarded': true});
    nowProvider = () => DateTime(2026, 9, 28, 21, 47, 32);
  });

  // Every mode (Pomodoro included) at every shape and UI size.
  for (final ui in UiSize.values) {
    for (final mode in AppMode.values) {
      for (final size in _sizes) {
        testWidgets(
            '${mode.name} @ ${size.width.toInt()}x${size.height.toInt()} '
            '${ui.name}', (tester) async {
          setScreen(tester, size);
          await AppPreferences.setUiSize(ui);
          await ModePrefs.setCurrent(mode);
          await tester.pumpWidget(testApp(const ModeHost()));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          TimerController.instance.wipe();
        });
      }
    }
  }

  // Secondary pages.
  final pages = <String, Widget Function()>{
    'settings': () => const Settings(),
    'modes': () => const ModesPage(),
    'activity': () => const ActivityPage(),
    'display': () => const DisplayPage(),
    'appearance': () => const AppearancePage(),
    'notifications': () => const NotificationsPage(),
  };
  for (final page in pages.entries) {
    for (final ui in [UiSize.normal, UiSize.extraLarge]) {
      for (final size in _sizes) {
        testWidgets(
            '${page.key} @ ${size.width.toInt()}x${size.height.toInt()} '
            '${ui.name}', (tester) async {
          setScreen(tester, size);
          await AppPreferences.setUiSize(ui);
          await tester.pumpWidget(testApp(page.value()));
          await _settle(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  // Rotating / resizing while the app is live must not throw or lose state.
  testWidgets('rotating and resizing live keeps every mode alive',
      (tester) async {
    for (final mode in AppMode.values) {
      await ModePrefs.setCurrent(mode);
      setScreen(tester, _sizes.first);
      await tester.pumpWidget(testApp(const ModeHost()));
      await _settle(tester);
      for (final size in _sizes) {
        tester.view.physicalSize = size;
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull,
            reason: '${mode.name} → ${size.width}x${size.height}');
      }
      await _settle(tester);
      expect(tester.takeException(), isNull);
    }
  });
}
