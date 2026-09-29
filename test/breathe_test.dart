import 'package:enfo/haptics/haptic_events.dart';
import 'package:enfo/haptics/haptics.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/breathe/breathe_mode_page.dart';
import 'package:enfo/modes/breathe/breathe_model.dart';
import 'package:enfo/modes/breathe/breathe_prefs.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_keys.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Events written so far. Writes are queued, so give them real time.
Future<List<ToolEvent>> loaded(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  return await tester.runAsync(ToolHistory.load) ?? [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('breatheAt', () {
    test('box walks inhale, hold, exhale, hold and wraps', () {
      const p = BreathePattern.box;
      expect(breatheAt(p, 0).phase, BreathePhase.inhale);
      expect(breatheAt(p, 3999).phase, BreathePhase.inhale);
      expect(breatheAt(p, 4000).phase, BreathePhase.holdFull);
      expect(breatheAt(p, 8000).phase, BreathePhase.exhale);
      expect(breatheAt(p, 12000).phase, BreathePhase.holdEmpty);
      final wrapped = breatheAt(p, 16000 + 500);
      expect(wrapped.phase, BreathePhase.inhale);
      expect(wrapped.breath, 1);
      expect(wrapped.phaseElapsedMs, 500);
    });

    test('fill rises on inhale, stays, falls on exhale', () {
      const p = BreathePattern.box;
      expect(breatheAt(p, 0).fill, 0);
      expect(breatheAt(p, 2000).fill, closeTo(.5, .01));
      expect(breatheAt(p, 5000).fill, 1);
      expect(breatheAt(p, 10000).fill, closeTo(.5, .01));
      expect(breatheAt(p, 13000).fill, 0);
      var last = -1.0;
      for (var ms = 0; ms < 4000; ms += 100) {
        final f = breatheAt(p, ms).fill;
        expect(f, greaterThanOrEqualTo(last));
        last = f;
      }
    });

    test('zero-length holds are skipped', () {
      const p = BreathePattern.calm; // 4-6
      expect(breatheAt(p, 3999).phase, BreathePhase.inhale);
      expect(breatheAt(p, 4000).phase, BreathePhase.exhale);
      expect(breatheAt(p, 9999).phase, BreathePhase.exhale);
      expect(breatheAt(p, 10000).phase, BreathePhase.inhale);
      expect(breatheAt(BreathePattern.relax478, 4000).phase,
          BreathePhase.holdFull);
      expect(
          breatheAt(BreathePattern.relax478, 11000).phase, BreathePhase.exhale);
      expect(breatheAt(BreathePattern.relax478, 19000).breath, 1);
    });

    test('seconds left counts down', () {
      const p = BreathePattern.box;
      expect(breatheAt(p, 0).secondsLeft, 4);
      expect(breatheAt(p, 1000).secondsLeft, 3);
      expect(breatheAt(p, 3999).secondsLeft, 1);
    });

    test('timings string', () {
      expect(BreathePattern.box.timings, '4-4-4-4');
      expect(BreathePattern.relax478.timings, '4-7-8');
      expect(BreathePattern.coherent.timings, '5-5');
    });
  });

  group('BreatheSession', () {
    final t0 = DateTime(2026, 9, 28, 22);

    test('elapsed follows timestamps and pauses', () {
      final s = BreatheSession(pattern: BreathePattern.box, plannedSeconds: 60);
      s.start(t0);
      expect(s.elapsedMs(t0.add(const Duration(seconds: 10))), 10000);
      s.pause(t0.add(const Duration(seconds: 10)));
      expect(s.elapsedMs(t0.add(const Duration(seconds: 50))), 10000);
      s.start(t0.add(const Duration(seconds: 50)));
      expect(s.elapsedMs(t0.add(const Duration(seconds: 60))), 20000);
      expect(s.remainingSeconds(t0.add(const Duration(seconds: 60))), 40);
    });

    test('completes exactly at the plan, endless never does', () {
      final s = BreatheSession(pattern: BreathePattern.box, plannedSeconds: 60);
      s.start(t0);
      expect(s.completeIfDue(t0.add(const Duration(seconds: 59))), isFalse);
      expect(s.completeIfDue(t0.add(const Duration(seconds: 61))), isTrue);
      expect(s.state, BreatheState.done);
      expect(s.elapsedMs(t0.add(const Duration(hours: 1))), 60000);

      final e =
          BreatheSession(pattern: BreathePattern.box, plannedSeconds: null);
      e.start(t0);
      expect(e.completeIfDue(t0.add(const Duration(hours: 5))), isFalse);
    });
  });

  test('settings round-trip', () async {
    await resetTestState();
    final s = BreatheSettings()
      ..pattern = BreathePattern.custom
      ..custom = BreathePattern.custom.copyWith(inhale: 6, holdEmpty: 0)
      ..minutes = 0;
    await s.save();
    final back = await BreatheSettings.load();
    expect(back.pattern.id, 'custom');
    expect(back.active.inhale, 6);
    expect(back.active.holdEmpty, 0);
    expect(back.plannedSeconds, isNull);
  });

  group('haptics', () {
    final phone = FakePhone();
    setUp(() async {
      await resetTestState();
      phone.system.clear();
      phone.patterns.clear();
      phone.attach();
      Haptics.debugAvailable = true;
      Haptics.debugAmplitude = true;
      Haptics.resetCapabilities();
    });
    tearDown(() {
      Haptics.debugAvailable = null;
      Haptics.debugAmplitude = null;
      phone.detach();
    });
    Future<void> flush() =>
        Future<void>.delayed(const Duration(milliseconds: 30));

    test('inhale swells, exhale fades', () {
      final inS = HapticEvents.breatheIn.pulses.map((p) => p.strength).toList();
      final outS =
          HapticEvents.breatheOut.pulses.map((p) => p.strength).toList();
      expect(inS, orderedEquals([...inS]..sort()));
      expect(outS, orderedEquals([...outS]..sort((a, b) => b.compareTo(a))));
      expect(inS.last, lessThan(.5)); // always gentle
    });

    test('cues respect the master switch', () async {
      Haptics.breatheIn();
      Haptics.breatheOut();
      Haptics.breatheHold();
      await flush();
      expect(phone.patterns.length, 2);
      expect(phone.system, isNotEmpty);
      phone.patterns.clear();
      phone.system.clear();
      await Haptics.setEnabled(false);
      Haptics.breatheIn();
      Haptics.breatheOut();
      Haptics.breatheHold();
      await flush();
      expect(phone.patterns, isEmpty);
      expect(phone.system, isEmpty);
    });
  });

  group('page', () {
    setUpAll(loadAppFonts);
    late DateTime now;
    setUp(() async {
      await resetTestState();
      now = DateTime(2026, 9, 28, 22);
      nowProvider = () => now;
    });

    Future<void> advance(WidgetTester tester, int seconds) async {
      for (var i = 0; i < seconds * 2; i++) {
        now = now.add(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('space starts, pauses; a full session is logged',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await ToolHistory.clear();
      await tester.pumpWidget(testApp(const BreatheModePage()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Box'), findsOneWidget);
      // 1 minute session.
      await tester.tap(find.text('1 min'));
      await tester.pump();

      ModeKeys.of(AppMode.breathe)!.primary!();
      await tester.pump();
      await advance(tester, 1);
      expect(find.text('Inhale'), findsOneWidget);
      await advance(tester, 4);
      expect(find.text('Hold'), findsOneWidget);
      await advance(tester, 4);
      expect(find.text('Exhale'), findsOneWidget);

      ModeKeys.of(AppMode.breathe)!.primary!(); // pause
      await tester.pump();
      final frozen = now;
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      now = frozen;
      ModeKeys.of(AppMode.breathe)!.primary!(); // resume
      await tester.pump();
      await advance(tester, 55);
      expect(find.text('Well done'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));

      final events = await loaded(tester);
      expect(events, hasLength(1));
      expect(events.single.kind, ToolKind.breathe);
      expect(events.single.label, 'Box 4-4-4-4');
      expect(events.single.planned, 60);
      expect(events.single.seconds, 60);
      expect(events.single.completed, isTrue);
    });

    testWidgets('R stops early: logged as incomplete, short ones are not',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await ToolHistory.clear();
      await tester.pumpWidget(testApp(const BreatheModePage()));
      await tester.pump(const Duration(milliseconds: 100));

      ModeKeys.of(AppMode.breathe)!.primary!();
      await advance(tester, 3);
      ModeKeys.of(AppMode.breathe)!.reset!();
      await tester.pump();
      expect(await loaded(tester), isEmpty);

      ModeKeys.of(AppMode.breathe)!.primary!();
      await advance(tester, 20);
      ModeKeys.of(AppMode.breathe)!.reset!();
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      final events = await tester.runAsync(ToolHistory.load) ?? [];
      expect(events, hasLength(1));
      expect(events.single.completed, isFalse);
      expect(events.single.seconds, 20);
      expect(find.text('Box'), findsOneWidget); // back to the setup
    });

    testWidgets('custom pattern steppers', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const BreatheModePage()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Custom'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('4-4-6-2'), findsOneWidget);
      await tester.tap(find.byTooltip('+1').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('5-4-6-2'), findsOneWidget);
    });

    testWidgets('reduced motion: text only, no overflow, still works',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(MediaQuery(
        data:
            const MediaQueryData(size: Size(390, 844), disableAnimations: true),
        child: testApp(const BreatheModePage()),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      ModeKeys.of(AppMode.breathe)!.primary!();
      await advance(tester, 2);
      expect(find.text('Inhale'), findsOneWidget);
      expect(tester.takeException(), isNull);
      ModeKeys.of(AppMode.breathe)!.reset!();
      await tester.pump();
    });

    const screens = <String, Size>{
      'watch': Size(200, 200),
      'watch-tall': Size(192, 240),
      'phone': Size(390, 844),
      'phone-landscape': Size(844, 390),
      'tablet': Size(800, 1280),
      'tv': Size(960, 540),
      'desktop': Size(1920, 1080),
    };
    for (final e in screens.entries) {
      for (final custom in [false, true]) {
        testWidgets('fits on ${e.key}${custom ? ' (custom)' : ''}',
            (tester) async {
          setScreen(tester, e.value);
          if (custom) {
            await (BreatheSettings()..pattern = BreathePattern.custom).save();
          }
          await tester.pumpWidget(testApp(const BreatheModePage()));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
          ModeKeys.of(AppMode.breathe)!.primary!();
          await advance(tester, 6);
          expect(tester.takeException(), isNull);
          ModeKeys.of(AppMode.breathe)!.reset!();
          await tester.pump();
        });
      }
    }
  });
}
