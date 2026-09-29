import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/shortcuts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> press(WidgetTester tester, LogicalKeyboardKey key,
    {String? character}) async {
  await simulateKeyDownEvent(key, character: character);
  await simulateKeyUpEvent(key);
  await settle(tester);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => resetTestState({'onboarded': true}));

  Future<void> open(WidgetTester tester, AppMode mode) async {
    setScreen(tester, const Size(500, 900));
    await ModePrefs.setCurrent(mode);
    await tester.pumpWidget(testApp(const ModeHost()));
    await settle(tester);
  }

  testWidgets('digits jump to a mode, brackets step through them',
      (tester) async {
    await open(tester, AppMode.pomodoro);
    await press(tester, LogicalKeyboardKey.digit3, character: '3');
    expect(ModePrefs.current.value, AppMode.timer);
    await press(tester, LogicalKeyboardKey.bracketRight, character: ']');
    expect(ModePrefs.current.value, AppMode.stopwatch);
    await press(tester, LogicalKeyboardKey.channelDown);
    expect(ModePrefs.current.value, AppMode.timer);
  });

  testWidgets('media play/pause and lap drive the stopwatch', (tester) async {
    await open(tester, AppMode.stopwatch);
    final sw = StopwatchController.instance;
    await press(tester, LogicalKeyboardKey.mediaPlayPause);
    expect(sw.running, isTrue);
    await press(tester, LogicalKeyboardKey.keyL, character: 'l');
    expect(sw.laps.length, 1);
    await press(tester, LogicalKeyboardKey.mediaPlayPause);
    expect(sw.running, isFalse);
  });

  testWidgets('space starts and pauses the timer', (tester) async {
    await open(tester, AppMode.timer);
    final timer = TimerController.instance;
    timer.setTotal(90);
    await settle(tester);
    // Nothing has been tabbed to yet, so Space belongs to the mode.
    FocusManager.instance.primaryFocus?.unfocus();
    await press(tester, LogicalKeyboardKey.space, character: ' ');
    expect(timer.running, isTrue);
    await press(tester, LogicalKeyboardKey.mediaPlayPause);
    expect(timer.running, isFalse);
  });

  testWidgets('F toggles full screen and Esc leaves it', (tester) async {
    await open(tester, AppMode.clock);
    await press(tester, LogicalKeyboardKey.keyF, character: 'f');
    expect(Fullscreen.active.value, isTrue);
    await press(tester, LogicalKeyboardKey.escape);
    expect(Fullscreen.active.value, isFalse);
  });

  testWidgets('? opens the shortcut list and Esc closes it', (tester) async {
    await open(tester, AppMode.clock);
    await press(tester, LogicalKeyboardKey.slash, character: '?');
    expect(find.byType(ShortcutsPage), findsOneWidget);
    // Mode keys are ignored over another page.
    await press(tester, LogicalKeyboardKey.digit1, character: '1');
    expect(ModePrefs.current.value, AppMode.clock);
    await press(tester, LogicalKeyboardKey.escape);
    expect(find.byType(ShortcutsPage), findsNothing);
  });

  testWidgets('arrow keys turn a focused timer wheel', (tester) async {
    await open(tester, AppMode.timer);
    final timer = TimerController.instance;
    timer.setTotal(0);
    await settle(tester);
    // Tab to the first focusable control until a wheel takes it: the first
    // wheel is hours, so Up adds an hour.
    for (var i = 0; i < 12 && timer.totalSeconds == 0; i++) {
      await press(tester, LogicalKeyboardKey.tab);
      await press(tester, LogicalKeyboardKey.arrowUp);
    }
    expect(timer.totalSeconds, greaterThan(0));
  });
}
