import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/clock_prefs.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _screens = <String, Size>{
  'watch': Size(200, 200),
  'watch-tall': Size(192, 240),
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

Future<void> settle(WidgetTester tester) async {
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

  /// Puts each mode into a state that exercises its densest layout.
  Future<void> populate(AppMode mode) async {
    switch (mode) {
      case AppMode.timer:
        TimerController.instance.setTotal(1500);
        TimerController.instance.start();
      case AppMode.stopwatch:
        final sw = StopwatchController.instance;
        var now = DateTime(2026, 9, 28, 21, 0);
        nowProvider = () => now;
        sw.start();
        for (var i = 0; i < 6; i++) {
          now = now.add(Duration(seconds: 20 + i * 7));
          sw.lap();
        }
      case AppMode.alarm:
        for (final h in [6, 7, 22]) {
          await AlarmService.upsert(AlarmService.create(
            hour: h,
            minute: 15,
            days: h == 7 ? {1, 2, 3, 4, 5} : const {},
            label: 'Alarm $h',
          ));
        }
      default:
        break;
    }
  }

  for (final mode in AppMode.values.where((m) => m != AppMode.pomodoro)) {
    for (final size in _screens.entries) {
      for (final full in [false, true]) {
        testWidgets(
            '${mode.name} fits on ${size.key}${full ? ' (full screen)' : ''}',
            (tester) async {
          setScreen(tester, size.value);
          await populate(mode);
          await ModePrefs.setCurrent(mode);
          Fullscreen.active.value = full;

          await tester.pumpWidget(testApp(const ModeHost()));
          await settle(tester);
          expect(tester.takeException(), isNull);

          Fullscreen.active.value = false;
          TimerController.instance.wipe();
          StopwatchController.instance.wipe();
        });
      }
    }
  }

  // Resting states: nothing running, nothing saved.
  for (final mode in [
    AppMode.timer,
    AppMode.stopwatch,
    AppMode.alarm,
    AppMode.world,
  ]) {
    for (final size in _screens.entries) {
      testWidgets('${mode.name} (idle) fits on ${size.key}', (tester) async {
        setScreen(tester, size.value);
        await ModePrefs.setCurrent(mode);
        await tester.pumpWidget(testApp(const ModeHost()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // The clock has five designs: check each on the awkward shapes.
  for (final face in ClockFace.values) {
    for (final size in [
      _screens['watch']!,
      _screens['phone']!,
      _screens['phone-landscape']!,
      _screens['tv']!,
    ]) {
      testWidgets(
          'clock ${face.name} fits ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        setScreen(tester, size);
        await ClockPrefs.setFace(face);
        await ModePrefs.setCurrent(AppMode.clock);
        await tester.pumpWidget(testApp(const ModeHost()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
