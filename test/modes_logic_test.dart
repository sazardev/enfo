import 'package:enfo/modes/alarm/alarm.dart';
import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:enfo/modes/world/cities.dart';
import 'package:enfo/modes/world/world_clock_page.dart';
import 'package:enfo/modes/world/world_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'test_harness.dart';

void main() {
  setUp(() => resetTestState());

  /// Freezes "now" and lets a test move it.
  late DateTime now;
  void clockAt(DateTime start) {
    now = start;
    nowProvider = () => now;
  }

  group('modes', () {
    test('order, visibility and the quick-switch cycle', () async {
      // More tools start off; only the core modes are on out of the box.
      expect(ModePrefs.enabled, AppMode.values.where((m) => m.core));
      await ModePrefs.setEnabled(AppMode.timer, false);
      await ModePrefs.setEnabled(AppMode.alarm, false);
      expect(ModePrefs.enabled, [
        AppMode.pomodoro,
        AppMode.clock,
        AppMode.stopwatch,
        AppMode.world,
      ]);

      await ModePrefs.setCurrent(AppMode.world);
      await ModePrefs.step(); // wraps around
      expect(ModePrefs.current.value, AppMode.pomodoro);
      await ModePrefs.step(-1);
      expect(ModePrefs.current.value, AppMode.world);

      await ModePrefs.setOrder([
        AppMode.world,
        AppMode.clock,
        ...AppMode.values
            .where((m) => m != AppMode.world && m != AppMode.clock),
      ]);
      expect(ModePrefs.enabled.first, AppMode.world);
    });

    test('the last visible mode cannot be hidden; hiding current moves on',
        () async {
      for (final m in AppMode.values.skip(1)) {
        expect(await ModePrefs.setEnabled(m, false), true);
      }
      expect(await ModePrefs.setEnabled(AppMode.pomodoro, false), false);
      expect(ModePrefs.enabled, [AppMode.pomodoro]);

      await ModePrefs.setEnabled(AppMode.clock, true);
      await ModePrefs.setCurrent(AppMode.clock);
      await ModePrefs.setEnabled(AppMode.clock, false);
      expect(ModePrefs.current.value, AppMode.pomodoro);
    });

    test('persists, and starts on the chosen mode', () async {
      await ModePrefs.setCurrent(AppMode.stopwatch);
      await ModePrefs.setEnabled(AppMode.alarm, false);
      await ModePrefs.load();
      expect(ModePrefs.current.value, AppMode.stopwatch); // remembered
      expect(ModePrefs.enabled.contains(AppMode.alarm), false);

      await ModePrefs.setStartMode(AppMode.clock);
      await ModePrefs.load();
      expect(ModePrefs.current.value, AppMode.clock); // fixed start mode
    });
  });

  group('tool history', () {
    test('events round-trip, including laps', () async {
      final at = DateTime(2026, 9, 28, 10);
      await ToolHistory.add(ToolEvent(
        kind: ToolKind.stopwatch,
        at: at,
        seconds: 90,
        laps: const [40000, 50000],
      ));
      await ToolHistory.add(ToolEvent(
        kind: ToolKind.timer,
        at: at,
        seconds: 60,
        planned: 300,
        completed: false,
        label: 'tea',
      ));
      final events = await ToolHistory.load();
      expect(events, hasLength(2));
      expect(events[0].laps, [40000, 50000]);
      expect(events[1].planned, 300);
      expect(events[1].completed, false);
      expect(events[1].label, 'tea');

      await ToolHistory.clear();
      expect(await ToolHistory.load(), isEmpty);
    });
  });

  group('timer', () {
    test('runs, pauses without losing time, finishes and rings', () async {
      clockAt(DateTime(2026, 9, 28, 12));
      final t = TimerController.instance;
      t.setTotal(60);
      t.start();
      expect(t.phase, TimerPhase.running);

      now = now.add(const Duration(seconds: 20));
      expect(t.remainingMs, 40000);
      expect(t.progress, closeTo(1 / 3, 0.001));

      t.pause();
      now = now.add(const Duration(minutes: 5)); // paused: no time passes
      expect(t.remainingMs, 40000);

      t.start();
      now = now.add(const Duration(seconds: 39));
      t.check();
      expect(t.phase, TimerPhase.running); // 1s to go

      now = now.add(const Duration(seconds: 2));
      t.check();
      expect(t.phase, TimerPhase.idle);
      expect(Alerts.current.value, isNotNull);
      expect(Alerts.current.value!.title, "Time's up");

      await pumpEventQueue();
      final events = await ToolHistory.load();
      expect(events.single.kind, ToolKind.timer);
      expect(events.single.completed, true);
      expect(events.single.planned, 60);
    });

    test('adding time extends a running timer; reset logs a partial run',
        () async {
      clockAt(DateTime(2026, 9, 28, 12));
      final t = TimerController.instance;
      t.setTotal(120);
      t.start();
      now = now.add(const Duration(seconds: 30));
      t.addSeconds(60);
      expect(t.totalSeconds, 180);
      expect(t.remainingMs, 150000);

      t.reset();
      expect(t.phase, TimerPhase.idle);
      await pumpEventQueue();
      final e = (await ToolHistory.load()).single;
      expect(e.completed, false);
      expect(e.seconds, 30);
      expect(e.planned, 180);
    });

    test('a timer that ran out while the app was closed rings on load',
        () async {
      clockAt(DateTime(2026, 9, 28, 12));
      final t = TimerController.instance;
      t.setTotal(60);
      t.start();
      await pumpEventQueue();

      // "Close" the app for ten minutes, then reopen.
      now = now.add(const Duration(minutes: 10));
      await TimerController.instance.load();
      expect(t.phase, TimerPhase.idle);
      expect(Alerts.current.value, isNotNull);
    });

    test('presets: add, no duplicates, remove, persisted', () async {
      final t = TimerController.instance;
      t.addPreset(45);
      t.addPreset(45);
      expect(t.presets.where((p) => p == 45), hasLength(1));
      await pumpEventQueue();
      t.presets = [];
      await t.load();
      expect(t.presets.contains(45), true);
      t.removePreset(45);
      expect(t.presets.contains(45), false);
    });
  });

  group('stopwatch', () {
    test('counts across stop/start, records laps, files the run on reset',
        () async {
      clockAt(DateTime(2026, 9, 28, 9));
      final sw = StopwatchController.instance;
      sw.start();
      now = now.add(const Duration(seconds: 65));
      sw.lap();
      now = now.add(const Duration(seconds: 20));
      sw.stop();
      now = now.add(const Duration(hours: 1)); // stopped: doesn't count
      expect(sw.elapsed, const Duration(seconds: 85));
      expect(sw.laps, [65000]);

      sw.start();
      now = now.add(const Duration(seconds: 5));
      expect(sw.elapsed, const Duration(seconds: 90));
      sw.stop();

      sw.reset();
      expect(sw.hasData, false);
      expect(sw.laps, isEmpty);

      await pumpEventQueue();
      final e = (await ToolHistory.load()).single;
      expect(e.kind, ToolKind.stopwatch);
      expect(e.seconds, 90);
      // The stretch after the last lap is filed as the final lap.
      expect(e.laps, [65000, 25000]);
    });

    test('a run under a second is not filed', () async {
      clockAt(DateTime(2026, 9, 28, 9));
      final sw = StopwatchController.instance;
      sw.start();
      now = now.add(const Duration(milliseconds: 400));
      sw.stop();
      sw.reset();
      await pumpEventQueue();
      expect(await ToolHistory.load(), isEmpty);
    });

    test('survives a restart while running', () async {
      clockAt(DateTime(2026, 9, 28, 9));
      final sw = StopwatchController.instance;
      sw.start();
      await pumpEventQueue();
      now = now.add(const Duration(minutes: 3));
      sw.wipe(); // simulates a fresh process: memory gone, prefs remain
      await sw.load();
      expect(sw.running, true);
      expect(sw.elapsed, const Duration(minutes: 3));
    });
  });

  group('alarms', () {
    // 2026-09-28 is a Monday.
    Future<Alarm> arm({
      Set<int> days = const {},
      int hour = 7,
      int minute = 30,
    }) async {
      final a = AlarmService.create(
        hour: hour,
        minute: minute,
        days: days,
        label: 'Wake up',
      );
      await AlarmService.upsert(a);
      return AlarmService.alarms.value.single;
    }

    test('next fire: today if still ahead, otherwise the next matching day',
        () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      final a = await arm(days: {1, 2, 3, 4, 5});
      expect(AlarmService.nextFire(a, now), DateTime(2026, 9, 28, 7, 30));

      clockAt(DateTime(2026, 9, 28, 8, 0)); // Monday, already passed
      expect(AlarmService.nextFire(a, now), DateTime(2026, 9, 29, 7, 30));

      clockAt(DateTime(2026, 10, 2, 8, 0)); // Friday after -> Monday
      expect(AlarmService.nextFire(a, now), DateTime(2026, 10, 5, 7, 30));
    });

    test('rings once when due, not twice', () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      await arm();

      now = DateTime(2026, 9, 28, 7, 29, 59);
      await AlarmService.check();
      expect(Alerts.current.value, isNull);

      now = DateTime(2026, 9, 28, 7, 30, 1);
      await AlarmService.check();
      expect(Alerts.current.value, isNotNull);
      expect(Alerts.current.value!.title, 'Wake up');
      Alerts.finish();

      now = DateTime(2026, 9, 28, 7, 31);
      await AlarmService.check();
      expect(Alerts.current.value, isNull); // already handled

      // A one-shot switches itself off after it went.
      expect(AlarmService.alarms.value.single.enabled, false);
    });

    test('a repeating alarm stays on and rings again the next matching day',
        () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      await arm(days: {1, 2, 3, 4, 5});

      now = DateTime(2026, 9, 28, 7, 30, 2);
      await AlarmService.check();
      Alerts.finish();
      expect(AlarmService.alarms.value.single.enabled, true);

      // Tuesday: rings.
      now = DateTime(2026, 9, 29, 7, 30, 3);
      await AlarmService.check();
      expect(Alerts.current.value, isNotNull);
      Alerts.finish();

      // Saturday (Oct 3): weekdays only, so nothing rings.
      now = DateTime(2026, 10, 3, 7, 30, 3);
      await AlarmService.check();
      expect(Alerts.current.value, isNull);
    });

    test('an alarm that passed long ago is logged missed, not rung', () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      await arm();

      now = DateTime(2026, 9, 28, 9, 0); // 90 min late (app was closed)
      await AlarmService.check();
      expect(Alerts.current.value, isNull);
      await pumpEventQueue();
      final e = (await ToolHistory.load()).single;
      expect(e.kind, ToolKind.alarm);
      expect(e.outcome, 'missed');
    });

    test('snooze rings again after 5 minutes and is logged', () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      await arm();

      now = DateTime(2026, 9, 28, 7, 30, 1);
      await AlarmService.check();
      final request = Alerts.current.value!;
      expect(request.snoozeMinutes, 5);
      request.onSnooze!();
      Alerts.finish();
      await pumpEventQueue();

      final alarm = AlarmService.alarms.value.single;
      expect(alarm.snoozedUntilMs, isNotNull);
      expect(AlarmService.nextFire(alarm, now),
          now.add(const Duration(minutes: 5)));

      now = now.add(const Duration(minutes: 5, seconds: 1));
      await AlarmService.check();
      expect(Alerts.current.value, isNotNull); // ringing again
      final outcomes =
          (await ToolHistory.load()).map((e) => e.outcome).toList();
      expect(outcomes, contains('snoozed'));
    });

    test('editing or re-enabling never rings for a time already past today',
        () async {
      clockAt(DateTime(2026, 9, 28, 12, 0));
      await arm(hour: 7); // 07:30, created at noon
      now = DateTime(2026, 9, 28, 12, 1);
      await AlarmService.check();
      expect(Alerts.current.value, isNull);
    });

    test('persists across a restart', () async {
      clockAt(DateTime(2026, 9, 28, 7, 0));
      await arm(days: {6, 7});
      await AlarmService.load();
      final a = AlarmService.alarms.value.single;
      expect(a.days, {6, 7});
      expect(a.label, 'Wake up');
    });
  });

  group('world clock', () {
    test('every city has a real time zone in the bundled database', () {
      for (final city in worldCities) {
        expect(() => tz.getLocation(city.zone), returnsNormally,
            reason: '${city.id} -> ${city.zone}');
      }
      final ids = worldCities.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate city');
    });

    test('offset formatting', () {
      expect(formatOffset(const Duration(hours: 9)), '+9h');
      expect(formatOffset(const Duration(hours: -5)), '-5h');
      expect(formatOffset(const Duration(hours: 5, minutes: 30)), '+5h 30m');
      expect(formatOffset(const Duration(hours: -3, minutes: -30)), '-3h 30m');
    });

    test('daylight saving is honoured', () {
      // New York is UTC-4 in September and UTC-5 in January.
      final ny = tz.getLocation('America/New_York');
      expect(tz.TZDateTime(ny, 2026, 9, 1).timeZoneOffset,
          const Duration(hours: -4));
      expect(tz.TZDateTime(ny, 2026, 1, 15).timeZoneOffset,
          const Duration(hours: -5));
    });

    test('add / remove / reorder are persisted', () async {
      await WorldPrefs.add('Asia/Dubai');
      await WorldPrefs.add('Asia/Dubai'); // no duplicate
      expect(WorldPrefs.cities.value.where((c) => c == 'Asia/Dubai'),
          hasLength(1));
      await WorldPrefs.reorder(WorldPrefs.cities.value.length - 1, 0);
      expect(WorldPrefs.cities.value.first, 'Asia/Dubai');

      await WorldPrefs.load();
      expect(WorldPrefs.cities.value.first, 'Asia/Dubai');
      await WorldPrefs.remove('Asia/Dubai');
      expect(WorldPrefs.cities.value.contains('Asia/Dubai'), false);
    });
  });
}
