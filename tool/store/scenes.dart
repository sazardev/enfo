import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:enfo/accent_color_page.dart';
import 'package:enfo/settings.dart';
import 'package:enfo/clock_style_page.dart';
import 'package:enfo/history.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/modes/alarm/alarm_service.dart';
import 'package:enfo/modes/ambient/ambient_service.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/event/event_service.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/intervals/interval_plan.dart';
import 'package:enfo/modes/intervals/intervals_service.dart';
import 'package:enfo/modes/kitchen/kitchen_service.dart';
import 'package:enfo/modes/mode_keys.dart';
import 'package:enfo/modes/modes_page.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:enfo/modes/tracker/tracker_service.dart';
import 'package:enfo/modes/world/meeting_planner_page.dart';
import 'package:enfo/onboarding.dart';
import 'package:enfo/pomodoro_state.dart';
import 'package:enfo/stats.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/ambient_test.dart' show FakePlayer;
import 'shot_harness.dart';

import 'scene_def.dart';

/// Pomodoro mid-way: [remaining] left of [total].
Future<void> runningPomodoro({
  Duration total = const Duration(minutes: 25),
  Duration remaining = const Duration(minutes: 11, seconds: 32),
  bool rest = false,
}) async {
  final now = DateTime.now();
  await PomodoroStore.save(PomodoroSnapshot(
    run: PomodoroRun.running,
    rest: rest,
    totalSeconds: total.inSeconds,
    endsAt: now.add(remaining),
    sessionStart: now.subtract(total - remaining),
  ));
}

/// Runs [body] with the app clock set [ago] before the frozen instant, then
/// puts the frozen clock back. Lets the real services "start" things in the
/// past so the shot shows them part-way.
Future<T> at<T>(ShotCtx c, Duration ago, Future<T> Function() body) async {
  nowProvider = () => c.frozen.subtract(ago);
  try {
    return await body();
  } finally {
    nowProvider = () => c.frozen;
  }
}

/// A believable Pomodoro history: ~6 weeks, busy weekdays, quiet weekends,
/// an unbroken streak up to today.
String _historyJson(DateTime frozen) {
  final rng = math.Random(11);
  final sessions = <PomodoroSession>[];
  final today = DateTime(frozen.year, frozen.month, frozen.day);
  for (var back = 0; back < 46; back++) {
    final day = today.subtract(Duration(days: back));
    final weekend = day.weekday >= 6;
    // Keep a 14-day streak; before that, some gaps.
    if (back > 13 && rng.nextDouble() < (weekend ? .6 : .18)) continue;
    var count = weekend ? 1 + rng.nextInt(3) : 3 + rng.nextInt(6);
    if (back == 0) count = 2;
    var t = day.add(Duration(hours: 8, minutes: 20 + rng.nextInt(50)));
    for (var i = 0; i < count; i++) {
      final abandoned = rng.nextDouble() < .1;
      final minutes = abandoned ? 8 + rng.nextInt(12) : 25;
      sessions.add(PomodoroSession(
        isWork: true,
        startedAt: t,
        endedAt: t.add(Duration(minutes: minutes)),
        plannedSeconds: 25 * 60,
        focusedSeconds: minutes * 60,
        pauseCount: rng.nextInt(3) == 0 ? 1 : 0,
        pausedSeconds: 40,
        completed: !abandoned,
      ));
      t = t.add(Duration(minutes: minutes));
      final long = (i + 1) % 4 == 0;
      final rest = long ? 15 : 5;
      sessions.add(PomodoroSession(
        isWork: false,
        startedAt: t,
        endedAt: t.add(Duration(minutes: rest)),
        plannedSeconds: rest * 60,
        focusedSeconds: rest * 60,
        pauseCount: 0,
        pausedSeconds: 0,
        completed: true,
      ));
      t = t.add(Duration(minutes: rest + rng.nextInt(12)));
    }
  }
  sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
  return jsonEncode([for (final s in sessions) s.toJson()]);
}

final allScenes = <Scene>[
  // 1 ------------------------------------------------------------- hero
  Scene(
    n: 1,
    id: 'hero',
    theme: 'dark',
    accent: const Color(0xFF7C3AED),
    both: true,
    prefs: (c) => {'clock_style': 'rings', 'work_minutes': 25},
    seed: (c) => runningPomodoro(),
    featuredHeadline: 'focus',
    note: 'Pomodoro running, rings style, violet',
  ),

  // 2 ------------------------------------------------- style/combo gallery
  Scene(
    n: 2,
    id: 'styles',
    theme: 'light',
    accent: const Color(0xFF14B8A6),
    home: (c) => const ClockStylePage(selected: ClockStyle.wavyRing),
    prefs: (c) => {'clock_style': 'wavyRing'},
    featuredHeadline: 'styles',
    note: 'Clock style picker with the combos section',
  ),

  // 3 ------------------------------------------------- clock, nightstand
  Scene(
    n: 3,
    id: 'clock_night',
    theme: 'dark',
    accent: const Color(0xFFF59E0B),
    mode: AppMode.clock,
    prefs: (c) => {'clock_face': 'split', 'clock_show_seconds': true},
    seed: (c) async => Fullscreen.active.value = true,
    featuredHeadline: 'nightstand',
    note: 'Clock mode, full screen',
  ),

  // 4 ------------------------------------------------------------ timer
  Scene(
    n: 4,
    id: 'timer',
    theme: 'light',
    accent: const Color(0xFFEA580C),
    mode: AppMode.timer,
    prefs: (c) => {'clock_style': 'kitchen'},
    seed: (c) async {
      final t = TimerController.instance;
      t.setTotal(15 * 60);
      await at(c, const Duration(minutes: 5, seconds: 48), () async => t.start());
    },
    note: 'Timer running, kitchen dial',
  ),

  // 5 ---------------------------------------------------------- stopwatch
  Scene(
    n: 5,
    id: 'stopwatch',
    theme: 'dark',
    accent: const Color(0xFF10B981),
    mode: AppMode.stopwatch,
    prefs: (c) {
      const laps = [41230, 38900, 40150, 43720, 34990, 46800];
      final elapsedMs = laps.fold<int>(0, (a, b) => a + b) + 17340;
      final start =
          c.frozen.subtract(Duration(milliseconds: elapsedMs)).millisecondsSinceEpoch;
      return {
        'clock_style': 'sevenSeg',
        'stopwatch_state': jsonEncode({
          'r': true,
          'a': 0,
          'm': laps.fold<int>(0, (a, b) => a + b),
          't': start,
          's': start,
          'l': laps,
        }),
      };
    },
    seed: (c) => StopwatchController.instance.load(),
    note: 'Stopwatch with 6 laps, best and slowest highlighted',
  ),

  // 6 ------------------------------------------------------------- alarm
  Scene(
    n: 6,
    id: 'alarm',
    theme: 'light',
    accent: const Color(0xFF6366F1),
    mode: AppMode.alarm,
    seed: (c) async {
      final l = c;
      const weekdays = {1, 2, 3, 4, 5};
      await AlarmService.upsert(AlarmService.create(
          hour: 6,
          minute: 45,
          days: weekdays,
          label: l.t('Wake up', es: 'Despertar')));
      await AlarmService.upsert(AlarmService.create(
          hour: 8,
          minute: 30,
          days: {6, 7},
          label: l.t('Weekend run', es: 'Correr el fin de semana')));
      await AlarmService.upsert(AlarmService.create(
          hour: 13,
          minute: 0,
          days: weekdays,
          label: l.t('Lunch break', es: 'Hora de comer')));
      await AlarmService.upsert(AlarmService.create(
          hour: 18,
          minute: 30,
          days: {2, 4},
          label: l.t('Piano class', es: 'Clase de piano')));
      await AlarmService.upsert(AlarmService.create(
              hour: 22,
              minute: 30,
              days: {1, 2, 3, 4, 5, 6, 7},
              label: l.t('Wind down', es: 'Prepararse para dormir'))
          .copyWith(enabled: false));
    },
    note: 'Alarm list with repeats and a disabled alarm',
  ),

  // 7 -------------------------------------------------------- world clock
  Scene(
    n: 7,
    id: 'world',
    theme: 'dark',
    accent: const Color(0xFF2563EB),
    mode: AppMode.world,
    prefs: (c) => {
          'world_cities': [
            'Europe/London',
            'Europe/Madrid',
            'Asia/Dubai',
            'Asia/Tokyo',
            'Australia/Sydney',
          ],
        },
    featuredHeadline: 'world',
    note: 'World clock, 5 cities',
  ),

  // 8 ---------------------------------------------------------- intervals
  Scene(
    n: 8,
    id: 'intervals',
    theme: 'dark',
    accent: const Color(0xFFEA580C),
    mode: AppMode.intervals,
    prefs: (c) => {'clock_style': 'segments'},
    seed: (c) async {
      final s = IntervalsService.instance;
      s.wipe();
      s.edit(const IntervalPlan(
          warmUp: 30, work: 40, rest: 20, rounds: 6, coolDown: 60));
      // 30 warm-up + 2 rounds (120 s) + 17 s into round 3.
      await at(c, const Duration(seconds: 167), () async => s.start());
    },
    note: 'Intervals workout, WORK phase of round 3/6',
  ),

  // 9 ------------------------------------------------------------ kitchen
  Scene(
    n: 9,
    id: 'kitchen',
    theme: 'light',
    accent: const Color(0xFFF59E0B),
    mode: AppMode.kitchen,
    seed: (c) async {
      final k = KitchenService.instance;
      k.wipe();
      await at(c, const Duration(minutes: 6, seconds: 12),
          () async => k.add(c.t('Pasta', es: 'Pasta'), 10 * 60));
      await at(c, const Duration(minutes: 2, seconds: 5),
          () async => k.add(c.t('Tea', es: 'Té'), 4 * 60));
      await at(c, const Duration(minutes: 11),
          () async => k.add(c.t('Roast', es: 'Asado'), 45 * 60));
      await at(c, const Duration(seconds: 50),
          () async => k.add(c.t('Eggs', es: 'Huevos'), 7 * 60));
    },
    featuredHeadline: 'kitchen',
    note: 'Kitchen: 4 timers running',
  ),

  // 10 ------------------------------------------------------------ breathe
  Scene(
    n: 10,
    id: 'breathe',
    theme: 'dark',
    accent: const Color(0xFF14B8A6),
    mode: AppMode.breathe,
    prefs: (c) => {'breathe_pattern': 'box', 'breathe_minutes': 5},
    drive: (tester, c) async {
      ModeKeys.of(AppMode.breathe)!.primary!();
      nowProvider = () => c.frozen;
      await tester.pump(const Duration(milliseconds: 100));
      nowProvider = () => c.frozen.add(const Duration(milliseconds: 6300));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    },
    note: 'Breathe, box pattern, mid-cycle',
  ),

  // 11 -------------------------------------------------------------- music
  Scene(
    n: 11,
    id: 'music',
    theme: 'dark',
    accent: const Color(0xFF8B5CF6),
    mode: AppMode.music,
    prefs: (c) => {'clock_style': 'equalizer'},
    seed: (c) async {
      final s = AmbientService.instance;
      // ignore: invalid_use_of_visible_for_testing_member
      s.debugReset();
      s.player = FakePlayer()..position = const Duration(seconds: 38);
      s.selectTrack(5);
      await s.playMusic();
    },
    featuredHeadline: 'music',
    note: 'Music: song title pager + equalizer dial',
  ),

  // 12 --------------------------------------------------------------- sleep
  Scene(
    n: 12,
    id: 'sleep',
    theme: 'dark',
    accent: const Color(0xFF6366F1),
    mode: AppMode.sleep,
    prefs: (c) => {
          'sleep_plan': 'wakeAt',
          'sleep_wake': 6 * 60 + 45,
          'sleep_wind': true,
        },
    note: 'Sleep planner, wake at 06:45',
  ),

  // 13 ---------------------------------------------------------------- events
  Scene(
    n: 13,
    id: 'events',
    theme: 'light',
    accent: const Color(0xFFF43F5E),
    mode: AppMode.event,
    seed: (c) async {
      final e = EventService.instance;
      await e.wipe();
      final y = c.frozen.year;
      await e.upsert(e.create(
          name: c.t('Trip to Lisbon', es: 'Viaje a Lisboa'),
          target: DateTime(y, c.frozen.month, c.frozen.day + 23, 7, 30),
          icon: 3));
      await e.upsert(e.create(
          name: c.t('Anna\'s birthday', es: 'Cumpleaños de Ana'),
          target: DateTime(1994, c.frozen.month, c.frozen.day + 9, 9),
          yearly: true,
          icon: 1));
      await e.upsert(e.create(
          name: c.t('Product launch', es: 'Lanzamiento del producto'),
          target: DateTime(y, c.frozen.month, c.frozen.day + 3, 16),
          icon: 6));
      await e.upsert(e.create(
          name: c.t('New Year', es: 'Año Nuevo'),
          target: DateTime(y + 1, 1, 1),
          icon: 4,
          yearly: true));
    },
    note: 'Events countdown list',
  ),

  // 14 --------------------------------------------------------------- tracker
  Scene(
    n: 14,
    id: 'tracker',
    theme: 'light',
    accent: const Color(0xFF0D9488),
    mode: AppMode.tracker,
    seed: (c) async {
      final t = TrackerService.instance;
      await t.load();
      final rng = math.Random(5);
      final today = DateTime(c.frozen.year, c.frozen.month, c.frozen.day);
      final ids = ['d-study', 'd-code', 'd-reading', 'd-exercise'];
      for (var back = 6; back >= 1; back--) {
        final day = today.subtract(Duration(days: back));
        for (var k = 0; k < 3; k++) {
          final id = ids[(back + k) % ids.length];
          final a = t.byId(id)!;
          final minutes = 25 + rng.nextInt(50) + (id == 'd-code' ? 40 : 0);
          await ToolHistory.add(ToolEvent(
            kind: ToolKind.tracker,
            at: day.add(Duration(hours: 8 + k * 3, minutes: rng.nextInt(30))),
            seconds: minutes * 60,
            label: a.displayName,
          ));
        }
      }
      // Today: some finished work, and Code running for 38 min.
      final study = t.byId('d-study')!;
      await ToolHistory.add(ToolEvent(
        kind: ToolKind.tracker,
        at: today.add(const Duration(hours: 8, minutes: 10)),
        seconds: 55 * 60,
        label: study.displayName,
      ));
      await at(c, const Duration(minutes: 38), () => t.start('d-code'));
      await t.reloadEvents();
    },
    featuredHeadline: 'tracker',
    note: 'Tracker: running activity + 7-day chart',
  ),

  // 15 --------------------------------------------------------------- stats
  Scene(
    n: 15,
    id: 'stats',
    theme: 'dark',
    accent: const Color(0xFF10B981),
    home: (c) => const Stats(),
    prefs: (c) => {'session_history': _historyJson(c.frozen)},
    featuredHeadline: 'stats',
    note: 'Pomodoro statistics, ~6 weeks of history, streak',
  ),

  // 16 ------------------------------------------------------------ modes menu
  Scene(
    n: 16,
    id: 'modes',
    theme: 'light',
    accent: const Color(0xFF2563EB),
    home: (c) => const ModesPage(),
    note: 'Modes menu / customize',
  ),

  // 17 --------------------------------------------------------- appearance
  Scene(
    n: 17,
    id: 'settings',
    theme: 'dark',
    accent: const Color(0xFFD946EF),
    home: (c) => const Settings(),
    prefs: (c) => {'clock_style': 'flower'},
    note: 'Settings hub (master-detail on wide screens)',
  ),

  // 18 ------------------------------------------------------- onboarding
  Scene(
    n: 18,
    id: 'onboarding',
    theme: 'light',
    accent: const Color(0xFF7C3AED),
    home: (c) => const Onboarding(),
    prefs: (c) => {'onboarded': false, 'clock_style': 'orbit'},
    drive: (tester, c) async {
      final l = await AppLocalizations.delegate.load(Locale(c.lang));
      // language, tools, rhythm -> look
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(l.onbNext).first);
        await settleShot(tester);
      }
    },
    note: 'Onboarding look step: theme, combos, accent, live preview',
  ),

  // 19 ------------------------------------------------- world meeting planner
  Scene(
    n: 19,
    id: 'world_planner',
    theme: 'light',
    accent: const Color(0xFF0EA5E9),
    home: (c) => const MeetingPlannerPage(),
    prefs: (c) => {
          'world_cities': [
            'Europe/London',
            'Asia/Tokyo',
            'America/Los_Angeles',
          ],
        },
    note: 'Meeting planner',
  ),

  // 20 ----------------------------------------------------- accent picker
  Scene(
    n: 20,
    id: 'accent',
    theme: 'light',
    accent: const Color(0xFFF43F5E),
    home: (c) => AccentColorPage(
        colors: Themes.colors, selected: const Color(0xFFF43F5E)),
    note: 'Accent picker with live preview',
  ),
];

const _featuredNote = 'headline keys are suggestions for the composition step';

void writeManifest(String out) {
  final root = Directory(out);
  final scenes = <Map<String, Object?>>[];
  for (final s in allScenes) {
    final files = <String>[];
    if (root.existsSync()) {
      final suffix = RegExp(
          '^${s.n.toString().padLeft(2, '0')}_${RegExp.escape(s.id)}_(dark|light)_[a-z]+\\.png\$');
      for (final f in root.listSync(recursive: true).whereType<File>()) {
        final base = f.path.split('/').last;
        if (suffix.hasMatch(base)) {
          files.add(f.path.substring(root.path.length + 1));
        }
      }
    }
    files.sort();
    scenes.add({
      'n': s.n,
      'id': s.id,
      'featured': s.featuredHeadline != null,
      'headlineKey': s.featuredHeadline,
      'theme': s.theme,
      'alsoTheme': s.both ? (s.theme == 'dark' ? 'light' : 'dark') : null,
      'accent': '#${(s.accent.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      'mode': s.mode?.name,
      'note': s.note,
      'files': files,
    });
  }
  File('$out/manifest.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'note': _featuredNote,
      'devices': {
        'phone': '1080x1920 / 1920x1080',
        'tablet7': '1200x1920 / 1920x1200',
        'tablet10': '1600x2560 / 2560x1600',
      },
      'fileNameFormat': '<NN>_<scene>_<theme>_<lang>.png',
      'scenes': scenes,
    }));
}
