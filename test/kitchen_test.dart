import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/kitchen/kitchen_service.dart';
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
  final svc = KitchenService.instance;

  setUp(() async {
    await resetTestState({'onboarded': true});
    now = DateTime(2026, 9, 28, 12, 0, 0);
    nowProvider = () => now;
    svc.wipe();
    await ModePrefs.setEnabled(AppMode.kitchen, true);
  });

  void advance(int seconds) => now = now.add(Duration(seconds: seconds));

  group('service', () {
    test('timers are sorted by soonest end, paused ones last', () {
      final a = svc.add('Pasta', 540)!;
      final b = svc.add('Tea', 180)!;
      final c = svc.add('Oven', 1500)!;
      expect(svc.timers.map((t) => t.name), ['Tea', 'Pasta', 'Oven']);
      svc.pause(b.id);
      expect(svc.timers.map((t) => t.name), ['Pasta', 'Oven', 'Tea']);
      expect({a.id, b.id, c.id}, hasLength(3));
      expect(svc.soonest!.name, 'Pasta');
    });

    test('remaining is computed from the clock; pause/resume keep it', () {
      final t = svc.add('Eggs', 420)!;
      advance(60);
      expect(t.remainingMs, 360000);
      svc.pause(t.id);
      advance(500);
      expect(t.remainingMs, 360000);
      svc.resume(t.id);
      advance(60);
      expect(t.remainingMs, 300000);
      expect(t.progress, closeTo(120 / 420, 1e-9));
    });

    test('+1 min extends running and paused timers and the plan', () {
      final t = svc.add('Rice', 900)!;
      svc.addMinute(t.id);
      expect(t.remainingMs, 960000);
      expect(t.plannedSeconds, 960);
      svc.pause(t.id);
      svc.addMinute(t.id);
      expect(t.remainingMs, 1020000);
    });

    test('an empty name falls back to a default; zero seconds is refused', () {
      expect(svc.add('  ', 0), isNull);
      expect(svc.add('  ', 60)!.name, 'Timer');
    });

    test('the list is capped and slots are reused', () {
      for (var i = 0; i < KitchenService.maxTimers; i++) {
        expect(svc.add('t$i', 60), isNotNull);
      }
      expect(svc.add('one more', 60), isNull);
      svc.remove(3);
      expect(svc.add('again', 60)!.id, 3);
    });

    test('finished timers ring (queued), log and disappear', () async {
      svc.add('Pasta', 60);
      svc.add('Tea', 30);
      svc.add('Oven', 600);
      advance(61);
      svc.check();
      expect(svc.timers.map((t) => t.name), ['Oven']);
      // Tea finished first, so it rings first; Pasta waits in the queue.
      expect(Alerts.current.value!.title, contains('Tea'));
      Alerts.finish();
      expect(Alerts.current.value!.title, contains('Pasta'));
      final events = await _history();
      expect(events.map((e) => e.label), ['Tea', 'Pasta']);
      expect(events.every((e) => e.kind == ToolKind.kitchen), isTrue);
      expect(events.first.seconds, 30);
      expect(events.first.planned, 30);
      expect(events.first.completed, isTrue);
    });

    test('a paused timer never finishes', () {
      final t = svc.add('Tea', 30)!;
      svc.pause(t.id);
      advance(3600);
      svc.check();
      expect(svc.timers, hasLength(1));
      expect(Alerts.current.value, isNull);
    });

    test('deleting a started timer logs it as not completed', () async {
      final t = svc.add('Pasta', 600)!;
      advance(90);
      svc.remove(t.id);
      expect(svc.timers, isEmpty);
      final e = (await _history()).single;
      expect(e.completed, isFalse);
      expect(e.seconds, 90);
      expect(e.planned, 600);
    });

    test('timers survive a restart', () async {
      svc.add('Pasta', 540);
      final t = svc.add('Tea', 180)!;
      svc.pause(t.id);
      advance(30);
      await Future<void>.delayed(Duration.zero);
      svc.wipe();
      expect(svc.timers, isEmpty);
      await svc.load();
      expect(svc.timers.map((t) => t.name), ['Pasta', 'Tea']);
      expect(svc.byId(t.id)!.running, isFalse);
      expect(svc.timers.first.remainingMs, 510000);
    });

    test('notification ids stay in their own range', () {
      expect(KitchenService.notificationBase, greaterThan(9100));
      expect(KitchenService.notificationBase + KitchenService.maxTimers,
          lessThan(10000));
    });
  });

  group('page', () {
    testWidgets('chips add timers, cards control them', (tester) async {
      setScreen(tester, const Size(390, 844));
      await ModePrefs.setCurrent(AppMode.kitchen);
      await tester.pumpWidget(testApp(const ModeHost()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          find.text('No timers yet. Tap a chip to start one.'), findsOneWidget);
      await tester.tap(find.text('Tea · 3m'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.timers.single.name, 'Tea');
      expect(find.text('03:00'), findsOneWidget);
      await tester.tap(find.byTooltip('+1 min'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('04:00'), findsOneWidget);
      ModeKeys.of(AppMode.kitchen)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.timers.single.running, isFalse);
      await tester.tap(find.byTooltip('Delete timer'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.timers, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom timer via the inline editor', (tester) async {
      setScreen(tester, const Size(390, 844));
      await ModePrefs.setCurrent(AppMode.kitchen);
      await tester.pumpWidget(testApp(const ModeHost()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Custom'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'Bread');
      await tester.tap(find.text('Start timer'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(svc.timers.single.name, 'Bread');
      expect(svc.timers.single.plannedSeconds, 300);
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
      for (final many in [false, true]) {
        testWidgets('fits on ${size.key} (${many ? '6 timers' : 'empty'})',
            (tester) async {
          setScreen(tester, size.value);
          if (many) {
            for (final (n, s) in [
              ('Pasta', 540),
              ('Eggs', 420),
              ('Tea', 180),
              ('Rice', 900),
              ('Oven', 1500),
              ('A very long timer name that keeps going', 3725),
            ]) {
              svc.add(n, s);
            }
          }
          await ModePrefs.setCurrent(AppMode.kitchen);
          await tester.pumpWidget(testApp(const ModeHost()));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          if (size.key != 'watch') {
            await tester.tap(find.text('Custom'));
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });
}
