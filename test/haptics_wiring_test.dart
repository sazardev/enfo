import 'package:enfo/haptics/haptic_events.dart';
import 'package:enfo/haptics/haptics.dart';
import 'package:enfo/haptics/haptics_page.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/ringing_page.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/duration_wheels.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/ui/atoms/app_switch.dart';
import 'package:enfo/ui/organisms/countdown_dial.dart';
import 'package:enfo/ui/atoms/bouncy_tap.dart';
import 'package:enfo/ui/molecules/minutes_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _light = 'HapticFeedbackType.lightImpact';
const _medium = 'HapticFeedbackType.mediumImpact';
const _select = 'HapticFeedbackType.selectionClick';

void main() {
  final phone = FakePhone();

  setUpAll(loadAppFonts);
  setUp(() async {
    await resetTestState();
    phone
      ..system.clear()
      ..patterns.clear()
      ..cancels = 0
      ..attach();
    Haptics.debugAvailable = true;
    Haptics.debugAmplitude = true;
    Haptics.debounceMs = 0;
    Haptics.resetCapabilities();
  });
  tearDown(() {
    Haptics.debounceMs = 22;
    Haptics.debugAvailable = null;
    Haptics.debugAmplitude = null;
    phone.detach();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a press lands a light tap; touch switch silences it',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(testApp(Scaffold(
      body: Center(
        child: BouncyTap(
            onTap: () => taps++, child: const SizedBox(width: 80, height: 80)),
      ),
    )));
    await tester.tap(find.byType(BouncyTap));
    await settle(tester);
    expect(taps, 1);
    expect(phone.system, [_light]);

    phone.system.clear();
    await Haptics.setTouch(false);
    await tester.tap(find.byType(BouncyTap));
    await settle(tester);
    expect(taps, 2);
    expect(phone.system, isEmpty);
  });

  testWidgets('long press adds a firmer confirm', (tester) async {
    var long = 0;
    await tester.pumpWidget(testApp(Scaffold(
      body: Center(
        child: BouncyTap(
          onTap: () {},
          onLongPress: () => long++,
          child: const SizedBox(width: 80, height: 80),
        ),
      ),
    )));
    await tester.longPress(find.byType(BouncyTap));
    await settle(tester);
    expect(long, 1);
    // press-down tap first, then the long-press confirm (firmer)
    expect(phone.system, [_light, _medium]);
  });

  testWidgets('switch: rising double tap on, single soft tap off',
      (tester) async {
    var value = false;
    await tester.pumpWidget(testApp(Scaffold(
      body: Center(
        child: StatefulBuilder(
          builder: (context, set) => AppSwitch(
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
      ),
    )));

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value, true);
    expect(phone.system.length, 2);
    // second beat is firmer than the first: it "clicks on"
    const order = [_select, _light, _medium];
    expect(
        order.indexOf(phone.system[1]) >= order.indexOf(phone.system[0]), true);

    phone.system.clear();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 300));
    expect(value, false);
    expect(phone.system.length, 1);
  });

  testWidgets('wheels give one notch per row; motion switch silences them',
      (tester) async {
    await tester.pumpWidget(testApp(Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: DurationWheels(totalSeconds: 300, onChanged: (_) {}),
        ),
      ),
    )));
    await tester.drag(find.byType(LoopWheel).at(1), const Offset(0, -130));
    await settle(tester);
    expect(phone.system, isNotEmpty);
    expect(phone.system.every((h) => h == _select || h == _light), true,
        reason: 'notches are the lightest events');

    phone.system.clear();
    await Haptics.setMotion(false);
    await tester.drag(find.byType(LoopWheel).at(1), const Offset(0, -130));
    await settle(tester);
    expect(phone.system, isEmpty);
  });

  testWidgets('slider ticks on each step, not on every drag frame',
      (tester) async {
    var minutes = 25;
    await tester.pumpWidget(testApp(Scaffold(
      body: Center(
        child: StatefulBuilder(
          builder: (context, set) => SizedBox(
            width: 300,
            child: MinutesSlider(
              label: 'Focus',
              color: Colors.blue,
              minutes: minutes,
              min: 5,
              max: 120,
              onChanged: (v) => set(() => minutes = v),
            ),
          ),
        ),
      ),
    )));
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await settle(tester);
    expect(minutes, greaterThan(25));
    expect(phone.system, isNotEmpty);
    // fewer ticks than pixels dragged: only when the value really steps
    expect(phone.system.length, lessThanOrEqualTo(minutes - 25));
  });

  group('timer + stopwatch', () {
    late DateTime now;
    setUp(() {
      now = DateTime(2026, 9, 28, 12);
      nowProvider = () => now;
    });

    test('start is firm, pause is a touch, reset warns', () async {
      final t = TimerController.instance;
      t.setTotal(600);
      t.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_medium]); // confirm

      phone.system.clear();
      t.pause();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_light]); // tap

      phone.system.clear();
      t.start(); // resuming is only a touch
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_light]);

      phone.system.clear();
      now = now.add(const Duration(seconds: 30));
      t.reset();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.patterns, hasLength(1)); // warning is a composed pattern
    });

    test('the last three seconds tick once each, firming up', () async {
      final t = TimerController.instance;
      t.setTotal(10);
      t.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      phone.system.clear();

      // Poll like the app does: many checks per second.
      for (final ms in [
        5000,
        7000,
        7050,
        7100,
        7900,
        8000,
        8010,
        8900,
        9000,
        9010,
        9020,
        9500,
        9900
      ]) {
        now = DateTime(2026, 9, 28, 12).add(Duration(milliseconds: ms));
        t.check();
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      // Windows: 3s left (7000-7999), 2s (8000-8999), 1s (9000+): 3 ticks.
      expect(phone.system.length, 3);
      const heavy = 'HapticFeedbackType.heavyImpact';
      const order = [_select, _light, _medium, heavy];
      final ranks = phone.system.map(order.indexOf).toList();
      expect(ranks, orderedEquals([...ranks]..sort()));
      expect(ranks.first, lessThan(ranks.last));
      expect(phone.system.last, heavy); // "1" is the firmest tick
    });

    test('adding time cancels a countdown already under way', () async {
      final t = TimerController.instance;
      t.setTotal(10);
      t.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      now = DateTime(2026, 9, 28, 12, 0, 8);
      t.check(); // 2s left: ticks
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final before = phone.system.length;
      t.addSeconds(60);
      now = now.add(const Duration(milliseconds: 100));
      t.check();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      // only the "select" for the +1 min tap, no further countdown tick
      expect(phone.system.length, before + 1);
    });

    test('stopwatch: start confirm, lap crisp, stop touch, reset warns',
        () async {
      final sw = StopwatchController.instance;
      sw.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_medium]);

      now = now.add(const Duration(seconds: 5));
      phone.system.clear();
      sw.lap();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_medium]); // lap is firm and crisp

      phone.system.clear();
      sw.stop();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.system, [_light]);

      sw.reset();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(phone.patterns, hasLength(1));
    });
  });

  group('pomodoro dial', () {
    Future<void> pumpDial(WidgetTester tester) async {
      setScreen(tester, const Size(500, 900));
      await tester.pumpWidget(testApp(const Scaffold(
        body: CountdownDial(
          workSeconds: 60,
          restSeconds: 30,
          notification: false,
        ),
      )));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('start is press + firm confirm, pause/resume are touches',
        (tester) async {
      await pumpDial(tester);
      await tester.tap(find.byType(BouncyTap));
      await tester.pump(const Duration(milliseconds: 200));
      // press-down tap, then the start confirm: the two-step "button" feel
      expect(phone.system, [_light, _medium]);

      phone.system.clear();
      await tester.tap(find.byType(BouncyTap)); // pause
      await tester.pump(const Duration(milliseconds: 200));
      expect(phone.system, [_light, _light]);

      phone.system.clear();
      await tester.tap(find.byType(BouncyTap)); // resume
      await tester.pump(const Duration(milliseconds: 200));
      expect(phone.system, [_light, _light]);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('long press resets with a warning, once', (tester) async {
      await pumpDial(tester);
      await tester.tap(find.byType(BouncyTap));
      await tester.pump(const Duration(milliseconds: 200));
      phone.system.clear();
      phone.patterns.clear();

      await tester.longPress(find.byType(BouncyTap));
      await tester.pump(const Duration(milliseconds: 200));
      expect(phone.patterns, hasLength(1)); // the warning
      expect(phone.system, [_light],
          reason: 'only the press-down tap; no extra long-press confirm');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('finishing focus fades away, finishing rest builds up',
        (tester) async {
      await pumpDial(tester);
      await tester.tap(find.byType(BouncyTap));
      await tester.pump(const Duration(milliseconds: 100));
      phone.patterns.clear();

      await tester.pump(const Duration(seconds: 61)); // focus ends
      await tester.pump(const Duration(milliseconds: 200));
      List<int> amps(Map<Object?, Object?> p) =>
          (p['intensities'] as List).cast<int>().where((a) => a > 0).toList();
      expect(phone.patterns, hasLength(1));
      final toRest = amps(phone.patterns.single);
      expect(toRest.first, greaterThan(toRest.last));

      phone.patterns.clear();
      await tester.tap(find.byType(BouncyTap)); // start the rest
      await tester.pump(const Duration(milliseconds: 100));
      phone.patterns.clear();
      await tester.pump(const Duration(seconds: 31)); // rest ends
      await tester.pump(const Duration(milliseconds: 200));
      final toWork = amps(phone.patterns.single);
      expect(toWork.last, greaterThan(toWork.first));
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('mode changes and full screen have a soft transition beat', () async {
    await ModePrefs.setCurrent(AppMode.clock);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(phone.system, [_light]);

    phone.system.clear();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await ModePrefs.setCurrent(AppMode.clock); // already there: no beat
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(phone.system, isEmpty);

    await Fullscreen.enter();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(phone.system, [_light]);
    await Fullscreen.exit();
  });

  group('ringing screen', () {
    Future<void> pumpRinger(WidgetTester tester, RingRequest r) async {
      setScreen(tester, const Size(500, 900));
      await tester.pumpWidget(testApp(RingingPage(request: r)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    RingRequest alarm({bool timer = false}) => RingRequest(
          title: 'Wake up',
          icon: Icons.alarm_rounded,
          timer: timer,
          onDismiss: () {},
        );

    testWidgets(
        'vibrates on open and again every pattern period, in step '
        'with the pulse animation', (tester) async {
      await Haptics.setAlarmPattern(AlarmPattern.heartbeat);
      await pumpRinger(tester, alarm());
      expect(phone.patterns, hasLength(1)); // first cycle at once

      final period = AlarmPattern.heartbeat.period;
      await tester.pump(Duration(milliseconds: period));
      expect(phone.patterns, hasLength(2));
      await tester.pump(Duration(milliseconds: period));
      expect(phone.patterns, hasLength(3));

      // The disc swells on the beat and has relaxed between beats.
      double scaleNow() {
        final t = tester.widget<Transform>(find
            .descendant(
                of: find.byType(RingingPage), matching: find.byType(Transform))
            .first);
        return t.transform.getMaxScaleOnAxis();
      }

      await tester.pump(Duration(milliseconds: period));
      await tester.pump(const Duration(milliseconds: 10));
      final onBeat = scaleNow();
      await tester.pump(const Duration(milliseconds: 700));
      final between = scaleNow();
      expect(onBeat, greaterThan(between));

      Alerts.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a finished timer rings its own beat, not the alarm pattern',
        (tester) async {
      await Haptics.setAlarmPattern(AlarmPattern.beacon); // 1 pulse
      await pumpRinger(tester, alarm(timer: true));
      final pattern = (phone.patterns.single['pattern'] as List).cast<int>();
      expect(pattern.length, HapticEvents.timerDone.pulses.length * 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('dismissing stops the buzzing and acknowledges with a tap',
        (tester) async {
      await pumpRinger(tester, alarm());
      phone.system.clear();
      await tester.tap(find.text('Dismiss'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(phone.cancels, 1);
      expect(phone.system, isNotEmpty); // the acknowledging confirm

      final count = phone.patterns.length;
      await tester.pump(const Duration(seconds: 4));
      expect(phone.patterns.length, count, reason: 'no more cycles');
    });

    testWidgets('with vibration off it still animates and never buzzes',
        (tester) async {
      await Haptics.setEnabled(false);
      await pumpRinger(tester, alarm());
      await tester.pump(const Duration(seconds: 3));
      expect(phone.patterns, isEmpty);
      expect(phone.system, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('settings page', () {
    Future<void> pumpPage(WidgetTester tester) async {
      setScreen(tester, const Size(500, 2200));
      await tester.pumpWidget(testApp(const HapticsPage()));
      await settle(tester);
    }

    testWidgets('master switch, strength and categories persist',
        (tester) async {
      await pumpPage(tester);
      expect(Haptics.enabled.value, true);

      await tester.tap(find.text('Strong'));
      await settle(tester);
      expect(Haptics.strength.value, HapticStrength.strong);

      // Categories: turn Motion off.
      final motion = find
          .ancestor(of: find.text('Motion'), matching: find.byType(Row))
          .first;
      await tester
          .tap(find.descendant(of: motion, matching: find.byType(Switch)));
      await settle(tester);
      expect(Haptics.motion.value, false);

      await Haptics.load(); // survives a reload
      expect(Haptics.strength.value, HapticStrength.strong);
      expect(Haptics.motion.value, false);
    });

    testWidgets('choosing an alarm pattern selects it and plays it',
        (tester) async {
      await pumpPage(tester);
      phone.patterns.clear();
      await tester.tap(find.text('Ripple'));
      await settle(tester);
      expect(Haptics.alarmPattern.value, AlarmPattern.ripple);
      final pattern = (phone.patterns.last['pattern'] as List).cast<int>();
      expect(pattern.length, AlarmPattern.ripple.event.pulses.length * 2);
    });

    testWidgets('try-it buttons play exactly their event', (tester) async {
      await pumpPage(tester);
      phone.system.clear();
      phone.patterns.clear();

      await tester.tap(find.text('Success'));
      await settle(tester);
      expect(phone.patterns.length, 1);
      expect((phone.patterns.single['pattern'] as List).length,
          HapticEvents.success.pulses.length * 2);
      expect(phone.system, isEmpty,
          reason: 'pill adds no press haptic of its own');
    });

    testWidgets('try-it works even if that category is off, not if master is',
        (tester) async {
      await Haptics.setAlerts(false);
      await pumpPage(tester);
      phone.patterns.clear();
      await tester.tap(find.text('Success'));
      await settle(tester);
      expect(phone.patterns, hasLength(1));

      await Haptics.setEnabled(false);
      await settle(tester);
      phone.patterns.clear();
      await tester.tap(find.text('Success'), warnIfMissed: false);
      await settle(tester);
      expect(phone.patterns, isEmpty);
    });

    testWidgets('the page explains itself where there is no motor',
        (tester) async {
      Haptics.debugAvailable = false;
      await pumpPage(tester);
      expect(find.text('This device has no vibration motor.'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });
  });

  for (final entry in const {
    'watch': Size(200, 200),
    'phone': Size(390, 844),
    'phone-landscape': Size(844, 390),
    'tablet': Size(800, 1280),
    'tv': Size(960, 540),
    'desktop': Size(1920, 1080),
  }.entries) {
    testWidgets('settings page fits on ${entry.key}', (tester) async {
      setScreen(tester, entry.value);
      await tester.pumpWidget(testApp(const HapticsPage()));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await Haptics.setEnabled(false); // the dimmed state too
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }

  test('envelope follows the beats: spikes on a pulse, relaxes between', () {
    final e = AlarmPattern.heartbeat.event; // lub at 0, dub at 170
    expect(e.envelopeAt(0), closeTo(.9, .001));
    expect(e.envelopeAt(60), lessThan(e.envelopeAt(0)));
    // the second beat lifts it again, softer than the first
    expect(e.envelopeAt(170), greaterThan(e.envelopeAt(150)));
    expect(e.envelopeAt(170), lessThan(e.envelopeAt(0)));
    // and it dies away before the cycle repeats
    expect(e.envelopeAt(AlarmPattern.heartbeat.period - 1), lessThan(.05));
  });
}
