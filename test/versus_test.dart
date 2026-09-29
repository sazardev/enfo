import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:enfo/modes/versus/versus_controller.dart';
import 'package:enfo/modes/versus/versus_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _screens = <String, Size>{
  'watch': Size(200, 200),
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

void main() {
  setUpAll(loadAppFonts);
  late DateTime now;
  final c = VersusController.instance;
  setUp(() async {
    await resetTestState({'onboarded': true});
    now = DateTime(2026, 9, 28, 20, 0);
    nowProvider = () => now;
    c.wipe();
  });

  void advance(int seconds) => now = now.add(Duration(seconds: seconds));

  test('labels', () {
    expect(duelName(60, 0), 'Bullet 1+0');
    expect(duelName(180, 2), 'Blitz 3+2');
    expect(duelName(300, 0), 'Blitz 5+0');
    expect(duelName(600, 0), 'Rapid 10+0');
    expect(duelName(900, 10), 'Rapid 15+10');
  });

  test('duel: turns, increment, timestamps', () {
    c.setPreset(const DuelPreset(180, 2));
    c.begin();
    expect(c.phase, VersusPhase.ready);
    c.tapSide(0); // side 0 starts thinking
    advance(10);
    expect(c.remainingMs(0), 170000);
    expect(c.remainingMs(1), 180000);
    c.tapSide(1); // not their turn: ignored
    expect(c.active, 0);
    c.tapSide(0); // ends the turn: +2 s
    expect(c.remainingMs(0), 172000);
    expect(c.active, 1);
    advance(30);
    expect(c.remainingMs(1), 150000);
    c.pause();
    advance(500);
    expect(c.remainingMs(1), 150000);
    c.resume();
    advance(5);
    expect(c.remainingMs(1), 145000);
    expect(c.moves, 1);
  });

  test('duel: flag fall logs the game', () async {
    c.setPreset(const DuelPreset(60, 0));
    c.begin();
    c.tapSide(1);
    advance(59);
    c.check();
    expect(c.phase, VersusPhase.running);
    advance(2);
    c.check();
    expect(c.phase, VersusPhase.over);
    expect(c.flagged, 1);
    expect(c.remainingMs(1), 0);
    await Future<void>.delayed(Duration.zero);
    final events = await ToolHistory.load();
    expect(events, hasLength(1));
    expect(events.single.kind, ToolKind.versus);
    expect(events.single.label, 'Bullet 1+0');
    expect(events.single.seconds, 60);
    expect(events.single.planned, 120);
    expect(events.single.completed, isTrue);
    c.reset();
    expect(await ToolHistory.load(), hasLength(1)); // not logged twice
  });

  test('duel: reset mid-game logs an unfinished game', () async {
    c.begin();
    c.tapSide(0);
    advance(20);
    c.endTurn();
    advance(5);
    c.reset();
    await Future<void>.delayed(Duration.zero);
    final e = (await ToolHistory.load()).single;
    expect(e.completed, isFalse);
    expect(e.seconds, 25);
    expect(c.phase, VersusPhase.setup);
  });

  test('speakers: overtime, next, total, log', () async {
    c.setKind(VersusKind.speakers);
    c.setSpeakerMinutes(1, 1);
    c.setSpeakerMinutes(2, 2);
    c.removeSpeaker(3);
    expect(c.plannedSpeakerSeconds, 180);
    c.begin();
    advance(30);
    expect(c.currentRemainingMs, 30000);
    advance(45); // 75 s of 60: overtime
    c.check();
    expect(c.overtime, isTrue);
    expect(c.currentRemainingMs, -15000);
    c.next();
    expect(c.index, 1);
    expect(c.overtime, isFalse);
    advance(60);
    expect(c.totalElapsedMs, 135000);
    c.next(); // last: finishes
    expect(c.phase, VersusPhase.over);
    await Future<void>.delayed(Duration.zero);
    final e = (await ToolHistory.load()).single;
    expect(e.label, 'Speakers');
    expect(e.seconds, 135);
    expect(e.planned, 180);
  });

  test('configuration persists', () async {
    c.setKind(VersusKind.speakers);
    c.setCustom(minutes: 7, increment: 3);
    c.renameSpeaker(1, 'Ana');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    c.wipe();
    await c.load();
    expect(c.kind, VersusKind.speakers);
    expect(c.baseSeconds, 420);
    expect(c.incrementSeconds, 3);
    expect(c.custom, isTrue);
    expect(c.speakers.first.name, 'Ana');
  });

  for (final size in _screens.entries) {
    testWidgets('versus fits on ${size.key}', (tester) async {
      setScreen(tester, size.value);
      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(testApp(const VersusModePage()));
      await settle();

      // Custom wheels open.
      await tester.tap(find.text('Custom'));
      await settle();

      // Duel running, then flagged.
      c.setPreset(const DuelPreset(180, 2));
      c.begin();
      await settle();
      c.tapSide(0);
      advance(3);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      advance(400);
      await tester.pump(const Duration(milliseconds: 150));
      expect(c.phase, VersusPhase.over);
      await settle();
      expect(find.text('Time is up'), findsOneWidget);
      c.reset();
      await settle();

      // Speakers: setup, running, overtime, done.
      c.setKind(VersusKind.speakers);
      await settle();
      c.begin();
      await settle();
      advance(400);
      await tester.pump(const Duration(milliseconds: 150));
      expect(c.overtime, isTrue);
      await settle();
      c.next();
      c.next();
      c.next();
      await settle();
      expect(c.phase, VersusPhase.over);
      c.reset();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
