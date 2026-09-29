import 'package:enfo/app_preferences.dart';
import 'package:enfo/history.dart';
import 'package:enfo/pomodoro_state.dart';
import 'package:enfo/ui/clock/clock_frame.dart';
import 'package:enfo/ui/organisms/countdown_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late CountdownController controller;

  setUp(() async {
    await resetTestState();
    controller = CountdownController();
  });

  Future<void> pumpDial(WidgetTester tester) async {
    setScreen(tester, const Size(500, 900));
    await tester.pumpWidget(testApp(Scaffold(
      body: CountdownDial(
        workSeconds: 60,
        restSeconds: 30,
        notification: false,
        controller: controller,
      ),
    )));
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Tears the dial down, as closing the app does.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  PomodoroSnapshot snap({
    PomodoroRun run = PomodoroRun.running,
    bool rest = false,
    int total = 60,
    Duration? endsIn,
    int remainingMs = 0,
    Duration? startedAgo,
  }) =>
      PomodoroSnapshot(
        run: run,
        rest: rest,
        totalSeconds: total,
        endsAt: endsIn == null ? null : DateTime.now().add(endsIn),
        remainingMs: remainingMs,
        sessionStart:
            startedAgo == null ? null : DateTime.now().subtract(startedAgo),
      );

  testWidgets('a running phase is saved with the instant it ends',
      (tester) async {
    await pumpDial(tester);
    controller.toggle();
    await tester.pump(const Duration(milliseconds: 100));

    final saved = PomodoroStore.snapshot!;
    expect(saved.run, PomodoroRun.running);
    expect(saved.rest, isFalse);
    final left = saved.endsAt!.difference(DateTime.now());
    expect(left.inSeconds, inInclusiveRange(58, 60));
    await close(tester);
  });

  testWidgets('closing the app mid-run keeps it running on reopen',
      (tester) async {
    await pumpDial(tester);
    controller.toggle();
    await tester.pump(const Duration(milliseconds: 100));
    await close(tester);

    // Nothing was logged as abandoned by closing.
    expect(await SessionHistory.load(), isEmpty);

    controller = CountdownController();
    await pumpDial(tester);
    expect(controller.value, ClockPhase.running);
    await close(tester);
  });

  testWidgets('a paused phase comes back paused with its time left',
      (tester) async {
    PomodoroStore.snapshot = snap(
      run: PomodoroRun.paused,
      remainingMs: 15000,
      startedAgo: const Duration(minutes: 5),
    );
    await pumpDial(tester);
    expect(controller.value, ClockPhase.paused);
    expect(PomodoroStore.snapshot!.remainingMs, inInclusiveRange(14900, 15100));
    await close(tester);
  });

  testWidgets('time spent closed counts: 20 s left resumes mid-phase',
      (tester) async {
    PomodoroStore.snapshot = snap(
      endsIn: const Duration(seconds: 20),
      startedAgo: const Duration(seconds: 40),
    );
    await pumpDial(tester);
    expect(controller.value, ClockPhase.running);
    final left = PomodoroStore.snapshot!.endsAt!.difference(DateTime.now());
    expect(left.inSeconds, inInclusiveRange(18, 20));
    await close(tester);
  });

  testWidgets('a phase that ended while closed is logged and moves on',
      (tester) async {
    final endsAt = DateTime.now().subtract(const Duration(minutes: 3));
    PomodoroStore.snapshot = PomodoroSnapshot(
      run: PomodoroRun.running,
      rest: false,
      totalSeconds: 60,
      endsAt: endsAt,
      sessionStart: endsAt.subtract(const Duration(seconds: 60)),
    );
    await pumpDial(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(controller.value, ClockPhase.idle);
    final sessions = await tester.runAsync(SessionHistory.load);
    expect(sessions, hasLength(1));
    expect(sessions!.single.completed, isTrue);
    expect(sessions.single.isWork, isTrue);
    expect(sessions.single.endedAt.millisecondsSinceEpoch,
        endsAt.millisecondsSinceEpoch);
    // Next up is the rest.
    expect(PomodoroStore.snapshot!.run, PomodoroRun.idle);
    expect(PomodoroStore.snapshot!.rest, isTrue);
    await close(tester);
  });

  testWidgets('auto-start carries on into the next phase if still in it',
      (tester) async {
    AppPreferences.autoStartNext.value = true;
    // Work ended 10 s ago; the 30 s rest that followed is still going.
    final endsAt = DateTime.now().subtract(const Duration(seconds: 10));
    PomodoroStore.snapshot = PomodoroSnapshot(
      run: PomodoroRun.running,
      rest: false,
      totalSeconds: 60,
      endsAt: endsAt,
      sessionStart: endsAt.subtract(const Duration(seconds: 60)),
    );
    await pumpDial(tester);

    expect(controller.value, ClockPhase.running);
    final saved = PomodoroStore.snapshot!;
    expect(saved.rest, isTrue);
    expect(saved.totalSeconds, 30);
    expect(saved.endsAt!.difference(DateTime.now()).inSeconds,
        inInclusiveRange(18, 20));
    await close(tester);
    AppPreferences.autoStartNext.value = false;
  });

  testWidgets('auto-start does not invent phases that passed unseen',
      (tester) async {
    AppPreferences.autoStartNext.value = true;
    final endsAt = DateTime.now().subtract(const Duration(hours: 2));
    PomodoroStore.snapshot = PomodoroSnapshot(
      run: PomodoroRun.running,
      rest: false,
      totalSeconds: 60,
      endsAt: endsAt,
      sessionStart: endsAt.subtract(const Duration(seconds: 60)),
    );
    await pumpDial(tester);

    expect(controller.value, ClockPhase.idle);
    await close(tester);
    AppPreferences.autoStartNext.value = false;
  });

  testWidgets('reset forgets the run', (tester) async {
    await pumpDial(tester);
    controller.toggle();
    await tester.pump(const Duration(seconds: 6));
    expect(PomodoroStore.snapshot, isNotNull);

    controller.reset();
    await tester.pump(const Duration(milliseconds: 100));
    expect(PomodoroStore.snapshot, isNull);
    await close(tester);
  });

  test('a corrupted blob loads as a clean dial', () async {
    await resetTestState({PomodoroStore.key: '{"run":"running","t":60}'});
    await PomodoroStore.load();
    expect(PomodoroStore.snapshot, isNull);
  });
}
