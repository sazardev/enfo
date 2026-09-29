import 'dart:convert';

import 'package:enfo/history.dart';
import 'package:enfo/home.dart';
import 'package:enfo/modes/activity_page.dart';
import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/clock_mode_page.dart';
import 'package:enfo/modes/clock/clock_prefs.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/immersive_view.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/modes_page.dart';
import 'package:enfo/modes/ringing_page.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:enfo/modes/world/world_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await settle(tester);
}

Future<void> tapTip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip).first);
  await settle(tester);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => resetTestState({'onboarded': true}));

  testWidgets('quick switch cycles modes and keeps the pomodoro alive',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);
    expect(find.byType(Home), findsOneWidget);

    await tapTip(tester, 'Next mode');
    expect(ModePrefs.current.value, AppMode.clock);
    expect(find.byType(ClockModePage), findsOneWidget);
    // Hidden, not destroyed: a running countdown must keep its time.
    expect(find.byType(Home, skipOffstage: false), findsOneWidget);

    await tapTip(tester, 'Next mode');
    expect(ModePrefs.current.value, AppMode.timer);
    expect(find.byType(ClockModePage), findsNothing);

    // Around the loop and back to the pomodoro screen.
    for (var i = 0; i < 4; i++) {
      await tapTip(tester, 'Next mode');
    }
    expect(ModePrefs.current.value, AppMode.pomodoro);
    expect(find.byType(Home), findsOneWidget);
  });

  testWidgets('full screen shows only the content; exit restores the chrome',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    await ModePrefs.setCurrent(AppMode.clock);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    expect(find.byType(ImmersiveView), findsNothing);
    await tapTip(tester, 'Full screen');
    expect(Fullscreen.active.value, true);
    expect(find.byType(ImmersiveView), findsOneWidget);
    // No mode bar buttons: just the clock and the (temporary) overlay.
    expect(find.byTooltip('Modes'), findsNothing);
    expect(find.byTooltip('Exit full screen'), findsOneWidget);

    await tapTip(tester, 'Exit full screen');
    expect(Fullscreen.active.value, false);
    expect(find.byType(ImmersiveView), findsNothing);
    expect(find.byTooltip('Modes'), findsOneWidget);
  });

  testWidgets('full screen overlay hides itself and tapping brings it back',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    await ModePrefs.setCurrent(AppMode.clock);
    Fullscreen.active.value = true;
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    Finder overlay() => find.ancestor(
          of: find.byTooltip('Exit full screen'),
          matching: find.byType(AnimatedOpacity),
        );
    expect(tester.widget<AnimatedOpacity>(overlay().first).opacity, 1);

    await tester.pump(const Duration(seconds: 5)); // auto-hide
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<AnimatedOpacity>(overlay().first).opacity, 0);

    await tester.tapAt(const Offset(250, 450));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<AnimatedOpacity>(overlay().first).opacity, 1);

    // Dim button cycles through the levels.
    final before = Fullscreen.dimStep.value;
    await tester.tap(find.byTooltip('Dim the screen'));
    await tester.pump();
    expect(
        Fullscreen.dimStep.value, (before + 1) % Fullscreen.dimLevels.length);
    Fullscreen.active.value = false;
  });

  testWidgets('modes page: toggle, keep one, jump to a mode', (tester) async {
    setScreen(tester, const Size(500, 1400));
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);
    await tapTip(tester, 'Modes');
    expect(find.byType(ModesPage), findsOneWidget);

    // Turn a mode off.
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(AppMode.values.length));
    await tester.tap(switches.at(3)); // stopwatch
    await settle(tester);
    expect(ModePrefs.disabled.value, {AppMode.stopwatch});

    // Turn everything else off: the last one refuses.
    for (final i in [1, 2, 4, 5]) {
      await tester.tap(find.byType(Switch).at(i));
      await settle(tester);
    }
    await tester.tap(find.byType(Switch).at(0));
    await settle(tester);
    expect(ModePrefs.enabled, [AppMode.pomodoro]);
    expect(find.text('At least one mode has to stay on.'), findsOneWidget);

    // Bring the timer back and jump straight to it.
    await tester.tap(find.byType(Switch).at(2));
    await settle(tester);
    await tester.tap(find.text('Timer').first);
    await settle(tester);
    expect(find.byType(ModesPage), findsNothing);
    expect(ModePrefs.current.value, AppMode.timer);
  });

  group('timer page', () {
    testWidgets('pick a preset, start, pause, resume, stop', (tester) async {
      setScreen(tester, const Size(500, 900));
      await ModePrefs.setCurrent(AppMode.timer);
      await tester.pumpWidget(testApp(const ModeHost()));
      await settle(tester);
      final t = TimerController.instance;

      await tapText(tester, '10m');
      expect(t.totalSeconds, 600);

      await tapText(tester, 'Start');
      expect(t.phase, TimerPhase.running);
      expect(find.text('Pause'), findsOneWidget);

      await tapText(tester, 'Pause');
      expect(t.phase, TimerPhase.paused);
      expect(find.text('Resume'), findsOneWidget);

      await tapText(tester, 'Resume');
      expect(t.phase, TimerPhase.running);

      await tapTip(tester, 'Reset');
      expect(t.phase, TimerPhase.idle);
      expect(find.text('Start'), findsOneWidget);
      // Leave nothing running for the next test.
      t.wipe();
    });

    testWidgets('running timer keeps going while another mode is open',
        (tester) async {
      setScreen(tester, const Size(500, 900));
      var now = DateTime(2026, 9, 28, 12);
      nowProvider = () => now;
      await ModePrefs.setCurrent(AppMode.timer);
      await tester.pumpWidget(testApp(const ModeHost()));
      await settle(tester);

      final t = TimerController.instance;
      t.setTotal(90);
      t.start();
      await settle(tester);

      await tapTip(tester, 'Next mode'); // away from the timer
      now = now.add(const Duration(seconds: 100));
      await tester.pump(const Duration(seconds: 2)); // host heartbeat fires
      await settle(tester); // the ringing page animates in

      expect(t.phase, TimerPhase.idle);
      expect(find.byType(RingingPage), findsOneWidget);
      await tester.tap(find.text('Dismiss'));
      await settle(tester);
      expect(find.byType(RingingPage), findsNothing);
    });
  });

  testWidgets('stopwatch: start, lap, stop, reset files the run',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    var now = DateTime(2026, 9, 28, 9);
    nowProvider = () => now;
    await ModePrefs.setCurrent(AppMode.stopwatch);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    await tapText(tester, 'Start');
    now = now.add(const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 50));
    await tapTip(tester, 'Lap');
    expect(StopwatchController.instance.laps, [12000]);
    expect(find.text('#1'), findsOneWidget);

    now = now.add(const Duration(seconds: 8));
    await tapText(tester, 'Stop');
    expect(StopwatchController.instance.running, false);

    await tapTip(tester, 'Reset');
    expect(StopwatchController.instance.hasData, false);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final events = await tester.runAsync(ToolHistory.load);
    expect(events!.single.seconds, 20);
    expect(events.single.laps, [12000, 8000]);
  });

  testWidgets('alarm: create, toggle off, edit, delete', (tester) async {
    setScreen(tester, const Size(500, 1200));
    await ModePrefs.setCurrent(AppMode.alarm);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);
    expect(find.text('No alarms on'), findsOneWidget);

    await tapTip(tester, 'New alarm');
    await tester.enterText(find.byType(TextField), 'Gym');
    await tapText(tester, 'M'); // Monday
    await tapText(tester, 'Save');

    final alarms = AlarmService.alarms.value;
    expect(alarms, hasLength(1));
    expect(alarms.single.label, 'Gym');
    expect(alarms.single.days, {1});
    expect(alarms.single.enabled, true);
    expect(find.textContaining('Gym'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect(AlarmService.alarms.value.single.enabled, false);

    // Open it again and delete (confirms in place).
    await tester.tap(find.textContaining('Gym'));
    await settle(tester);
    expect(find.text('Edit alarm'), findsOneWidget);
    await tapText(tester, 'Delete alarm');
    await tapText(tester, 'Confirm: delete alarm');
    expect(AlarmService.alarms.value, isEmpty);
    expect(find.text('Edit alarm'), findsNothing);
  });

  testWidgets('world clock: shows cities, adds one, edits the list',
      (tester) async {
    setScreen(tester, const Size(500, 1400));
    nowProvider = () => DateTime(2026, 9, 28, 12, 0);
    await ModePrefs.setCurrent(AppMode.world);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    expect(find.text('Local time'), findsOneWidget);
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);

    await tapTip(tester, 'Add a city');
    await tester.enterText(find.byType(TextField), 'par');
    await settle(tester);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Tokyo'), findsNothing); // filtered out
    await tester.tap(find.text('Paris'));
    await settle(tester);
    expect(WorldPrefs.cities.value.contains('Europe/Paris'), true);
    expect(find.text('Paris'), findsOneWidget);

    await tapTip(tester, 'Edit list');
    await tester.tap(find.byTooltip('Remove').first);
    await settle(tester);
    expect(WorldPrefs.cities.value.contains('America/New_York'), false);
  });

  testWidgets('ringing page: alarm rings full screen, dismiss stops it',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    var dismissed = false;
    var snoozed = false;
    Alerts.ring(RingRequest(
      title: 'Wake up',
      subtitle: '07:30',
      icon: Icons.alarm_rounded,
      snoozeMinutes: 5,
      onDismiss: () => dismissed = true,
      onSnooze: () => snoozed = true,
    ));
    await settle(tester);
    expect(find.byType(RingingPage), findsOneWidget);
    expect(find.text('Wake up'), findsOneWidget);
    expect(find.text('Snooze 5 min'), findsOneWidget);

    await tester.tap(find.text('Snooze 5 min'));
    await settle(tester);
    expect(snoozed, true);
    expect(dismissed, false);
    expect(find.byType(RingingPage), findsNothing);
    expect(Alerts.current.value, isNull);
  });

  testWidgets('a second alert waits for the first', (tester) async {
    setScreen(tester, const Size(500, 900));
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    RingRequest req(String title) => RingRequest(
          title: title,
          icon: Icons.alarm_rounded,
          onDismiss: () {},
        );
    Alerts.ring(req('First'));
    Alerts.ring(req('Second'));
    await settle(tester);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);

    await tester.tap(find.text('Dismiss'));
    await settle(tester);
    await settle(tester);
    expect(find.text('Second'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await settle(tester);
    expect(find.byType(RingingPage), findsNothing);
  });

  testWidgets('activity page lists every kind and filters', (tester) async {
    setScreen(tester, const Size(500, 1800));
    final now = DateTime.now();
    await resetTestState({
      'onboarded': true,
      'session_history': jsonEncode([
        PomodoroSession(
          isWork: true,
          startedAt: now.subtract(const Duration(hours: 5)),
          endedAt: now.subtract(const Duration(hours: 4, minutes: 35)),
          plannedSeconds: 1500,
          focusedSeconds: 1500,
          pauseCount: 0,
          pausedSeconds: 0,
          completed: true,
        ).toJson(),
      ]),
      'tool_history': jsonEncode([
        ToolEvent(
          kind: ToolKind.timer,
          at: now.subtract(const Duration(hours: 4)),
          seconds: 300,
          planned: 300,
        ).toJson(),
        ToolEvent(
          kind: ToolKind.stopwatch,
          at: now.subtract(const Duration(hours: 3)),
          seconds: 95,
          laps: const [40000, 55000],
        ).toJson(),
        ToolEvent(
          kind: ToolKind.alarm,
          at: now.subtract(const Duration(hours: 2)),
          label: 'Gym',
          outcome: 'snoozed',
        ).toJson(),
        ToolEvent(
          kind: ToolKind.display,
          at: now.subtract(const Duration(hours: 1)),
          seconds: 3600,
          outcome: 'clock',
        ).toJson(),
      ]),
    });
    await tester.pumpWidget(testApp(const ActivityPage()));
    await settle(tester);

    expect(find.textContaining('Gym'), findsOneWidget);
    expect(find.text('Snoozed'), findsOneWidget);
    expect(find.textContaining('Clock on display'), findsOneWidget);
    expect(find.textContaining('2 laps'), findsOneWidget);

    // Laps expand on tap.
    await tester.tap(find.textContaining('2 laps'));
    await settle(tester);
    expect(find.textContaining('Lap 1'), findsOneWidget);

    // Filter to timers only.
    await tapText(tester, 'Timer');
    expect(find.textContaining('Gym'), findsNothing);
    expect(find.textContaining('5m of 5m'), findsOneWidget);
  });

  testWidgets('clock: every design renders and swiping changes it',
      (tester) async {
    setScreen(tester, const Size(500, 900));
    nowProvider = () => DateTime(2026, 9, 28, 21, 47, 32);
    await ModePrefs.setCurrent(AppMode.clock);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);

    for (final face in ClockFace.values) {
      await ClockPrefs.setFace(face);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: face.name);
    }

    await ClockPrefs.setFace(ClockFace.ring);
    await settle(tester);
    await tester.fling(find.byType(ClockModePage), const Offset(-300, 0), 1200);
    await settle(tester);
    expect(ClockPrefs.face.value, ClockFace.digital);
  });
}
