import 'package:enfo/haptics/haptics.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/intervals/interval_plan.dart';
import 'package:enfo/modes/intervals/intervals_service.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_keys.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

Future<List<ToolEvent>> _history() async {
  await pumpEventQueue();
  return ToolHistory.load();
}

void main() {
  setUpAll(loadAppFonts);

  late DateTime now;
  final svc = IntervalsService.instance;

  setUp(() async {
    await resetTestState({'onboarded': true});
    now = DateTime(2026, 9, 28, 10, 0, 0);
    nowProvider = () => now;
    svc.wipe();
    await ModePrefs.setEnabled(AppMode.intervals, true);
  });

  void advance(int seconds) => now = now.add(Duration(seconds: seconds));

  group('plan', () {
    test('tabata timeline: 8 x 20s work, 7 x 10s rest, no trailing rest', () {
      final p = IntervalPreset.tabata.plan;
      final segs = p.segments;
      expect(segs, hasLength(15));
      expect(p.totalSeconds, 8 * 20 + 7 * 10);
      expect(segs.last.kind, IntervalKind.work);
      expect(segs.last.endMs, p.totalMs);
      expect(segs[1].kind, IntervalKind.rest);
      expect(segs[2].round, 2);
    });

    test('warm-up and cool-down bracket the rounds; zeros are skipped', () {
      const p =
          IntervalPlan(warmUp: 30, work: 40, rest: 0, rounds: 2, coolDown: 20);
      final kinds = p.segments.map((s) => s.kind).toList();
      expect(kinds, [
        IntervalKind.warmUp,
        IntervalKind.work,
        IntervalKind.work,
        IntervalKind.coolDown,
      ]);
      expect(p.totalSeconds, 30 + 80 + 20);
    });

    test('indexAt finds the segment and -1 after the end', () {
      final p = IntervalPreset.tabata.plan;
      final segs = p.segments;
      expect(p.indexAt(segs, 0), 0);
      expect(p.indexAt(segs, 19999), 0);
      expect(p.indexAt(segs, 20000), 1);
      expect(p.indexAt(segs, p.totalMs), -1);
    });

    test('json round trip', () {
      const p =
          IntervalPlan(warmUp: 5, work: 6, rest: 7, rounds: 8, coolDown: 9);
      expect(IntervalPlan.fromJson(p.toJson()), p);
    });
  });

  group('service', () {
    test('phase and round come from the clock', () {
      svc.start();
      expect(svc.segment!.kind, IntervalKind.work);
      advance(25);
      expect(svc.segment!.kind, IntervalKind.rest);
      expect(svc.segment!.round, 1);
      expect(svc.segmentRemainingMs, 5000);
      advance(5);
      expect(svc.segment!.kind, IntervalKind.work);
      expect(svc.segment!.round, 2);
      expect(svc.overallProgress, closeTo(30 / 230, 1e-9));
    });

    test('pause freezes progress and resume shifts the start', () {
      svc.start();
      advance(12);
      svc.pause();
      advance(600);
      expect(svc.elapsedMs, 12000);
      expect(svc.segment!.kind, IntervalKind.work);
      svc.start();
      advance(8);
      expect(svc.segment!.kind, IntervalKind.rest);
      expect(svc.elapsedMs, 20000);
    });

    test('editing switches to custom and is ignored while running', () {
      svc.edit(const IntervalPlan(work: 45, rest: 15, rounds: 3));
      expect(svc.preset, IntervalPreset.custom);
      expect(svc.plan.work, 45);
      svc.start();
      svc.edit(const IntervalPlan(work: 99));
      expect(svc.plan.work, 45);
      svc.selectPreset(IntervalPreset.emom);
      expect(svc.preset, IntervalPreset.custom);
    });

    test('a run in progress survives a restart', () async {
      svc.selectPreset(IntervalPreset.hiit);
      svc.start();
      advance(130);
      await Future<void>.delayed(Duration.zero);
      final before = svc.segment!;
      // Simulate a cold start: memory gone, prefs kept.
      final saved = svc.preset;
      svc.wipe();
      expect(svc.status, IntervalStatus.idle);
      await svc.load();
      expect(svc.preset, saved);
      expect(svc.status, IntervalStatus.running);
      expect(svc.segment!.startMs, before.startMs);
      expect(svc.segment!.kind, IntervalKind.work);
    });

    test('finishing logs the workout and rings', () async {
      svc.selectPreset(IntervalPreset.tabata);
      svc.start();
      advance(230);
      svc.check();
      expect(svc.status, IntervalStatus.idle);
      expect(Alerts.current.value, isNotNull);
      expect(Alerts.current.value!.timer, isTrue);
      final events = await _history();
      expect(events, hasLength(1));
      expect(events.single.kind, ToolKind.intervals);
      expect(events.single.label, 'Tabata');
      expect(events.single.seconds, 230);
      expect(events.single.planned, 230);
      expect(events.single.completed, isTrue);
    });

    test('a workout that ended long ago is logged but does not ring', () async {
      svc.start();
      advance(230 + 3600);
      svc.check();
      expect(Alerts.current.value, isNull);
      expect(await _history(), hasLength(1));
    });

    test('reset logs an unfinished run, but not a 2 second one', () async {
      svc.start();
      advance(2);
      svc.reset();
      expect(await _history(), isEmpty);
      svc.start();
      advance(60);
      svc.reset();
      final events = await _history();
      expect(events.single.completed, isFalse);
      expect(events.single.seconds, 60);
    });

    test('skip jumps to the next phase', () {
      svc.start();
      advance(3);
      svc.skip();
      expect(svc.segment!.kind, IntervalKind.rest);
      expect(svc.elapsedMs, 20000);
    });

    test('phase changes fire distinct haptics', () async {
      final phone = FakePhone()..attach();
      addTearDown(() {
        phone.detach();
        Haptics.debugAvailable = null;
        Haptics.debugAmplitude = null;
      });
      Haptics.debugAvailable = true;
      Haptics.debugAmplitude = true;
      Haptics.resetCapabilities();
      svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final work = phone.patterns.length;
      expect(work, 1); // "go" on the first work block
      advance(20);
      svc.check();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(phone.patterns.length, 2); // rest release
      expect(phone.patterns[0], isNot(equals(phone.patterns[1])));
    });
  });

  group('page', () {
    testWidgets('space starts and pauses, r resets', (tester) async {
      setScreen(tester, const Size(390, 844));
      await ModePrefs.setCurrent(AppMode.intervals);
      await tester.pumpWidget(testApp(const ModeHost()));
      await tester.pump(const Duration(milliseconds: 300));
      final keys = ModeKeys.of(AppMode.intervals)!;
      keys.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.running, isTrue);
      expect(find.text('WORK'), findsOneWidget);
      keys.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.status, IntervalStatus.paused);
      keys.reset!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.status, IntervalStatus.idle);
      expect(tester.takeException(), isNull);
    });

    for (final size in const {
      'watch': Size(200, 200),
      'phone': Size(390, 844),
      'landscape': Size(844, 390),
      'tablet': Size(800, 1280),
      'tv': Size(960, 540),
      'desktop': Size(1920, 1080),
    }.entries) {
      for (final active in [false, true]) {
        testWidgets('fits on ${size.key} (${active ? 'running' : 'idle'})',
            (tester) async {
          setScreen(tester, size.value);
          if (active) {
            svc.selectPreset(IntervalPreset.hiit);
            svc.start();
            advance(125);
          }
          await ModePrefs.setCurrent(AppMode.intervals);
          await tester.pumpWidget(testApp(const ModeHost()));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          if (!active && size.key != 'watch') {
            // Open the work editor: wheels must fit too.
            await tester.tap(find.text('Work').first);
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
          }
          Fullscreen.active.value = false;
        });
      }
    }
  });
}
