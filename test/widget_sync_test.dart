import 'dart:convert';
import 'dart:io';

import 'package:enfo/app_preferences.dart';
import 'package:enfo/focus_quotes.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/modes/alarm/alarm.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_frame.dart';
import 'package:enfo/widgets/pomodoro_live.dart';
import 'package:enfo/widgets/widget_bridge.dart';
import 'package:enfo/widgets/widget_launch.dart';
import 'package:enfo/widgets/widget_snapshot.dart';
import 'package:enfo/widgets/widget_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('es');
  });

  setUp(() async {
    await resetTestState();
    PomodoroLive.state.value = const PomodoroState();
    PomodoroLive.pendingToggle = false;
  });

  final now = DateTime(2026, 9, 29, 10, 0);

  Map<String, Object?> snapshot({
    List<Alarm> alarms = const [],
    ClockFormat format = ClockFormat.h24,
    String lang = 'en',
    PomodoroState? pomodoro,
    bool dynamicColor = false,
  }) {
    nowProvider = () => now;
    return WidgetSnapshot.build(
      now: now,
      l10n: lookupAppLocalizations(Locale(lang)),
      lang: lang,
      clockFormat: format,
      showDate: true,
      dynamicColor: dynamicColor,
      light: Themes.light(Colors.lime).colorScheme,
      dark: Themes.dark(Colors.lime).colorScheme,
      pomodoro: pomodoro ?? const PomodoroState(),
      timer: TimerController.instance,
      stopwatch: StopwatchController.instance,
      alarms: alarms,
      worldCityIds: const ['Asia/Tokyo', 'Europe/London'],
      music: const {
        'hasSong': false,
        'playing': false,
        'title': '',
        'artist': '',
      },
      focus: const {'today': '0m', 'detail': '', 'streak': ''},
    );
  }

  group('snapshot', () {
    test('is plain JSON with everything the widgets read', () {
      final s = snapshot();
      final decoded =
          jsonDecode(WidgetSnapshot.encode(s)) as Map<String, dynamic>;
      expect(decoded['v'], WidgetSnapshot.version);
      expect(decoded['at'], now.millisecondsSinceEpoch);
      expect(decoded['h24'], true);
      expect(decoded['palette']['light']['primary'], isA<int>());
      expect(decoded['palette']['dark']['surface'], isA<int>());
      expect(decoded['labels']['focus'], 'Focus');
      expect(decoded['world'], [
        {'name': 'Tokyo', 'zone': 'Asia/Tokyo'},
        {'name': 'London', 'zone': 'Europe/London'},
      ]);
      expect(
          decoded['timer']['presets'], TimerController.defaultPresets.take(4));
    });

    test('12/24 h follows the app setting, null means the system', () {
      expect(snapshot(format: ClockFormat.h12)['h24'], false);
      expect(snapshot(format: ClockFormat.system)['h24'], isNull);
    });

    test('an idle timer has no end time; a running one keeps absolute time',
        () {
      final idle = snapshot()['timer'] as Map<String, Object?>;
      expect(idle['phase'], 'idle');
      expect(idle.containsKey('endsAt'), false);

      TimerController.instance
        ..setTotal(120)
        ..start();
      nowProvider = () => now; // start() stamped "now"
      final running = snapshot()['timer'] as Map<String, Object?>;
      expect(running['phase'], 'running');
      expect(running['endsAt'], now.millisecondsSinceEpoch + 120000);
    });

    test('a running Pomodoro keeps counting after it was published', () {
      final published = PomodoroState(
        phase: ClockPhase.running,
        totalSeconds: 600,
        remainingMs: 500000,
        publishedAtMs: now.millisecondsSinceEpoch - 20000,
      );
      final p = snapshot(pomodoro: published)['pomodoro'] as Map;
      expect(p['remainingMs'], 480000);
      expect(p['endsAt'], now.millisecondsSinceEpoch + 480000);

      // A paused one stands still, however long ago it was published.
      final paused = PomodoroState(
        phase: ClockPhase.paused,
        totalSeconds: 600,
        remainingMs: 500000,
        publishedAtMs: 0,
      );
      final q = snapshot(pomodoro: paused)['pomodoro'] as Map;
      expect(q['remainingMs'], 500000);
      expect(q.containsKey('endsAt'), false);
    });

    test('alarms: soonest first, repeating ones contribute several rings', () {
      const daily = Alarm(
        id: 1,
        hour: 7,
        minute: 30,
        days: {1, 2, 3, 4, 5, 6, 7},
        label: 'Gym',
      );
      const once = Alarm(id: 2, hour: 23, minute: 15);
      const off = Alarm(id: 3, hour: 6, minute: 0, enabled: false);
      final alarms = snapshot(alarms: [daily, once, off])['alarms'] as List;

      // Tomorrow 07:30 is first (10:00 now, so today's has passed)... except
      // the 23:15 one-shot tonight.
      expect(alarms.first['time'], '23:15');
      expect(alarms.first['repeat'], '');
      final daily1 = alarms[1] as Map;
      expect(daily1['time'], '07:30');
      expect(daily1['repeat'], 'Every day');
      expect(daily1['label'], 'Gym');
      expect(alarms.length, greaterThan(3));
      final ats = [for (final a in alarms) a['at'] as int];
      expect([...ats]..sort(), ats);
      expect(alarms.where((a) => a['time'] == '06:00'), isEmpty);
      expect(alarms.length, lessThanOrEqualTo(WidgetSnapshot.maxAlarms));
    });

    test('12-hour times and Spanish labels', () {
      const a = Alarm(id: 1, hour: 19, minute: 5, days: {1, 2, 3, 4, 5});
      final en =
          snapshot(alarms: [a], format: ClockFormat.h12)['alarms'] as List;
      expect(en.first['time'], contains('7:05'));
      expect(en.first['repeat'], 'Weekdays');

      final es = snapshot(alarms: [a], lang: 'es')['alarms'] as List;
      expect(es.first['repeat'], isNot('Weekdays'));
      expect((snapshot(lang: 'es')['labels'] as Map)['focus'], 'Enfoque');
    });

    test('stopwatch state is exact at the moment of the snapshot', () {
      final s = snapshot()['stopwatch'] as Map;
      expect(s['running'], false);
      expect(s['elapsedMs'], 0);
    });

    test('carries two weeks of focus quotes for the quote widget', () {
      final quote = snapshot()['quote'] as Map<String, dynamic>;
      expect(quote['style'], 0);
      final days = quote['days'] as List;
      expect(days, hasLength(WidgetSnapshot.quoteDays));
      final first = days.first as Map<String, dynamic>;
      expect(first['at'], DateTime(2026, 9, 29).millisecondsSinceEpoch);
      expect(first['text'], FocusQuotes.forDate(
          lookupAppLocalizations(const Locale('en')), now));
      expect(first['day'], isNotEmpty);
      // Consecutive midnights, one per day.
      expect((days[1] as Map)['at'],
          DateTime(2026, 9, 30).millisecondsSinceEpoch);

      // The style travels with the snapshot.
      nowProvider = () => now;
      final styled = WidgetSnapshot.build(
        now: now,
        l10n: lookupAppLocalizations(const Locale('en')),
        lang: 'en',
        clockFormat: ClockFormat.h24,
        showDate: true,
        dynamicColor: false,
        light: Themes.light(Colors.lime).colorScheme,
        dark: Themes.dark(Colors.lime).colorScheme,
        pomodoro: const PomodoroState(),
        timer: TimerController.instance,
        stopwatch: StopwatchController.instance,
        alarms: const [],
        worldCityIds: const [],
        music: const {},
        focus: const {},
        quoteStyle: 1,
      );
      expect((styled['quote'] as Map)['style'], 1);
    });
  });

  group('widget launches', () {
    test('open the mode, even one the user hid', () async {
      await ModePrefs.setEnabled(AppMode.stopwatch, false);
      await WidgetLaunch.apply({'mode': 'stopwatch'});
      expect(ModePrefs.current.value, AppMode.stopwatch);
      expect(ModePrefs.enabled, contains(AppMode.stopwatch));
    });

    test('unknown modes are ignored', () async {
      await ModePrefs.setCurrent(AppMode.clock);
      await WidgetLaunch.apply({'mode': 'nope'});
      expect(ModePrefs.current.value, AppMode.clock);
    });

    test('timer presets start a timer of that length', () async {
      await WidgetLaunch.apply({'mode': 'timer', 'action': 'timer_start:180'});
      final t = TimerController.instance;
      expect(t.phase, TimerPhase.running);
      expect(t.totalSeconds, 180);
      expect(ModePrefs.current.value, AppMode.timer);
    });

    test('a preset does not restart or resize a timer already running',
        () async {
      final t = TimerController.instance..setTotal(600);
      t.start();
      await WidgetLaunch.apply({'mode': 'timer', 'action': 'timer_start:60'});
      expect(t.totalSeconds, 600);
      expect(t.phase, TimerPhase.running);
    });

    test('timer toggle pauses and resumes', () async {
      final t = TimerController.instance..setTotal(60);
      await WidgetLaunch.apply({'mode': 'timer', 'action': 'timer_toggle'});
      expect(t.phase, TimerPhase.running);
      await WidgetLaunch.apply({'mode': 'timer', 'action': 'timer_toggle'});
      expect(t.phase, TimerPhase.paused);
      await WidgetLaunch.apply({'mode': 'timer', 'action': 'timer_toggle'});
      expect(t.phase, TimerPhase.running);
    });

    test('stopwatch toggle and lap', () async {
      final s = StopwatchController.instance;
      await WidgetLaunch.apply(
          {'mode': 'stopwatch', 'action': 'stopwatch_lap'});
      expect(s.laps, isEmpty, reason: 'a lap needs a running stopwatch');
      await WidgetLaunch.apply(
          {'mode': 'stopwatch', 'action': 'stopwatch_toggle'});
      expect(s.running, true);
      await WidgetLaunch.apply(
          {'mode': 'stopwatch', 'action': 'stopwatch_lap'});
      expect(s.laps, hasLength(1));
      await WidgetLaunch.apply(
          {'mode': 'stopwatch', 'action': 'stopwatch_toggle'});
      expect(s.running, false);
    });

    test('pomodoro toggle is a pending request for the dial', () async {
      var seen = 0;
      void listener() => seen++;
      PomodoroLive.toggleRequests.addListener(listener);
      addTearDown(() => PomodoroLive.toggleRequests.removeListener(listener));

      await WidgetLaunch.apply(
          {'mode': 'pomodoro', 'action': 'pomodoro_toggle'});
      expect(PomodoroLive.pendingToggle, true);
      expect(seen, 1);
    });
  });

  group('bridge', () {
    const channel = MethodChannel('com.sazarcode.enfo/widgets');
    final calls = <MethodCall>[];
    late Directory framesDir;
    Map<String, String>? launchOnStart;

    setUp(() {
      calls.clear();
      launchOnStart = null;
      framesDir = Directory.systemTemp.createTempSync('enfo_sync');
      WidgetBridge.debugSupported = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'activeKinds':
            return ['timer', 'clock', 'bogus'];
          case 'framesDir':
            return framesDir.path;
          case 'systemSeed':
            return null;
          case 'takeLaunch':
            return launchOnStart;
          case 'canPin':
            return true;
        }
        return null;
      });
    });

    tearDown(() {
      framesDir.deleteSync(recursive: true);
      WidgetBridge.debugSupported = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('reads what native says, ignoring kinds it does not know', () async {
      expect(await WidgetBridge.activeKinds(),
          {WidgetKind.timer, WidgetKind.clock});
      expect(await WidgetBridge.framesDir(), framesDir.path);
      expect(await WidgetBridge.systemSeed(), isNull);
      expect(await WidgetBridge.canPin(), true);
      launchOnStart = {'mode': 'timer', 'action': 'timer_toggle'};
      expect(await WidgetBridge.takeLaunch(), launchOnStart);
    });

    test('pin and sync pass their arguments through', () async {
      await WidgetBridge.pin(WidgetKind.world);
      await WidgetBridge.sync('{"a":1}');
      expect(calls.map((c) => c.method), ['pin', 'sync']);
      expect(calls[0].arguments, 'world');
      expect(calls[1].arguments, '{"a":1}');
    });

    test('everything is a quiet no-op off Android', () async {
      WidgetBridge.debugSupported = false;
      expect(await WidgetBridge.activeKinds(), isEmpty);
      expect(await WidgetBridge.canPin(), false);
      expect(await WidgetBridge.takeLaunch(), isNull);
      await WidgetBridge.sync('{}');
      expect(calls, isEmpty);
    });

    test('a missing platform side is tolerated', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await WidgetBridge.framesDir(), isNull);
      expect(await WidgetBridge.activeKinds(), isEmpty);
    });

    test('sync pushes a snapshot after a change, debounced', () async {
      WidgetSync.start();
      addTearDown(WidgetSync.stop);
      // start() asked for one update and consumed the launch.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      calls.clear();

      TimerController.instance.setTotal(90);
      TimerController.instance.setTotal(95);
      TimerController.instance.setTotal(100);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final syncs = calls.where((c) => c.method == 'sync').toList();
      expect(syncs, hasLength(1), reason: 'a burst is one update');
      final pushed = jsonDecode(syncs.single.arguments as String) as Map;
      expect(pushed['timer']['total'], 100);
      // The fake launcher has a timer widget placed, so its pictures were
      // rendered next to the snapshot; the pomodoro one (not placed) was not.
      final frames = pushed['timer']['frames'] as Map;
      expect(File('${frames['dir']}/${frames['prefix']}_l_0.png').existsSync(),
          true);
      expect(pushed['pomodoro'].containsKey('frames'), false);
    });

    test('a tap that launched the app is applied on start', () async {
      launchOnStart = {'mode': 'stopwatch', 'action': 'stopwatch_toggle'};
      WidgetSync.start();
      addTearDown(WidgetSync.stop);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(StopwatchController.instance.running, true);
      expect(ModePrefs.current.value, AppMode.stopwatch);
    });
  });
}
