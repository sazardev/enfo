import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/sleep/sleep_logic.dart';
import 'package:enfo/modes/sleep/sleep_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  final now = DateTime(2026, 9, 28, 22, 40, 15);

  group('logic', () {
    test('bedtimes for a 07:00 wake', () {
      final wake = DateTime(2026, 9, 29, 7);
      final o = bedtimesFor(wake);
      expect(o.map((e) => e.cycles), [6, 5, 4]);
      // 6 cycles = 9 h + 15 min to fall asleep.
      expect(o[0].time, DateTime(2026, 9, 28, 21, 45));
      expect(o[1].time, DateTime(2026, 9, 28, 23, 15));
      expect(o[2].time, DateTime(2026, 9, 29, 0, 45));
      expect(o[0].sleep, const Duration(hours: 9));
    });

    test('wake-ups for bedtime 23:00', () {
      final o = wakeTimesFor(DateTime(2026, 9, 28, 23));
      expect(o.map((e) => e.cycles), [4, 5, 6]);
      expect(o[0].time, DateTime(2026, 9, 29, 5, 15));
      expect(o[1].time, DateTime(2026, 9, 29, 6, 45));
      expect(o[2].time, DateTime(2026, 9, 29, 8, 15));
    });

    test('5 and 6 cycles are the recommended ones', () {
      expect([4, 5, 6].map(isRecommended), [false, true, true]);
    });

    test('nextOccurrence rolls to tomorrow', () {
      expect(nextOccurrence(now, 23, 0), DateTime(2026, 9, 28, 23));
      expect(nextOccurrence(now, 7, 0), DateTime(2026, 9, 29, 7));
      expect(nextOccurrence(now, 22, 40), DateTime(2026, 9, 29, 22, 40));
    });

    test('planFor wakeAt', () {
      final r = planFor(
        plan: SleepPlan.wakeAt,
        now: now,
        wakeHour: 7,
        wakeMinute: 0,
        bedHour: 23,
        bedMinute: 0,
      );
      final five = r.options.firstWhere((o) => o.cycles == 5);
      expect(r.wakeOf(five), DateTime(2026, 9, 29, 7));
      expect(r.bedtimeOf(five), DateTime(2026, 9, 28, 23, 15));
      expect(windDownFor(r.bedtimeOf(five)), DateTime(2026, 9, 28, 22, 45));
    });

    test('planFor sleepNow starts from the current minute', () {
      final r = planFor(
        plan: SleepPlan.sleepNow,
        now: now,
        wakeHour: 7,
        wakeMinute: 0,
        bedHour: 23,
        bedMinute: 0,
      );
      expect(r.bedtimeOf(r.options.first), DateTime(2026, 9, 28, 22, 40));
      // 22:40 + 15 min + 4 * 90 min = 04:55.
      expect(r.options.first.time, DateTime(2026, 9, 29, 4, 55));
    });

    test('planFor sleepAt uses the chosen bedtime', () {
      final r = planFor(
        plan: SleepPlan.sleepAt,
        now: now,
        wakeHour: 7,
        wakeMinute: 0,
        bedHour: 23,
        bedMinute: 30,
      );
      expect(r.options[1].time, DateTime(2026, 9, 29, 7, 15));
    });
  });

  group('widgets', () {
    const screens = <String, Size>{
      'watch': Size(200, 200),
      'phone': Size(390, 844),
      'landscape': Size(844, 390),
      'tablet': Size(800, 1280),
      'tv': Size(960, 540),
      'desktop': Size(1920, 1080),
    };

    setUpAll(loadAppFonts);
    setUp(() async {
      await resetTestState({'onboarded': true});
      nowProvider = () => now;
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    for (final size in screens.entries) {
      testWidgets('fits on ${size.key}', (tester) async {
        setScreen(tester, size.value);
        await tester.pumpWidget(testApp(const SleepModePage()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('switching plans keeps fitting on a phone', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const SleepModePage()));
      await settle(tester);
      for (final label in ['Sleep at', 'Sleep now', 'Wake at']) {
        await tester.tap(find.text(label));
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('set alarm creates a real alarm, remove deletes it',
        (tester) async {
      setScreen(tester, const Size(390, 1200));
      await tester.pumpWidget(testApp(const SleepModePage()));
      await settle(tester);
      // Default: wake 07:00, 5 cycles selected.
      await tester.ensureVisible(find.text('Set alarm'));
      await tester.pump();
      await tester.tap(find.text('Set alarm'));
      await settle(tester);
      final alarms = AlarmService.alarms.value;
      expect(alarms.single.hour, 7);
      expect(alarms.single.minute, 0);
      expect(alarms.single.label, 'Wake up');
      expect(alarms.single.repeats, isFalse);
      expect(find.text('Remove alarm'), findsOneWidget);

      await tester.tap(find.text('Remove alarm'));
      await settle(tester);
      expect(AlarmService.alarms.value, isEmpty);
    });

    testWidgets('wind-down adds a second alarm 30 min before bed',
        (tester) async {
      setScreen(tester, const Size(390, 1200));
      await tester.pumpWidget(testApp(const SleepModePage()));
      await settle(tester);
      await tester.tap(find.text('Wind-down reminder'));
      await settle(tester);
      await tester.tap(find.text('Set alarm'));
      await settle(tester);
      final alarms = AlarmService.alarms.value;
      expect(alarms.length, 2);
      // 5 cycles for 07:00 -> bed 23:15 -> wind down 22:45.
      final wind = alarms.firstWhere((a) => a.label == 'Time to wind down');
      expect((wind.hour, wind.minute), (22, 45));
    });

    testWidgets('remembers the last wake time', (tester) async {
      setScreen(tester, const Size(390, 844));
      await resetTestState({'onboarded': true, 'sleep_wake': 6 * 60 + 30});
      nowProvider = () => now;
      await tester.pumpWidget(testApp(const SleepModePage()));
      await settle(tester);
      // 6:30 wake, 5 cycles -> bedtime 22:45.
      expect(find.textContaining('10:45'), findsWidgets);
    });
  });
}
