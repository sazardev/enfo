import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../app_preferences.dart';
import '../history.dart';
import '../l10n/locale_controller.dart';
import '../modes/ambient/ambient_service.dart';
import '../modes/format.dart';
import '../modes/alarm/alarm_service.dart';
import '../modes/clock/clock_prefs.dart';
import '../modes/stopwatch/stopwatch_controller.dart';
import '../modes/timer/timer_controller.dart';
import '../modes/world/world_prefs.dart';
import '../theme.dart';
import '../ui/clock/clock_frame.dart';
import '../ui/clock/clock_style.dart';
import 'pomodoro_live.dart';
import 'widget_bridge.dart';
import 'widget_frames.dart';
import 'widget_launch.dart';
import 'widget_prefs.dart';
import 'widget_snapshot.dart';

/// Keeps the Android home-screen widgets in step with the app.
///
/// Anything a widget shows (timer, stopwatch, alarms, cities, the clock
/// style, colors, language) is watched; when it changes — after a short
/// debounce, so a burst of edits is one update — a fresh [WidgetSnapshot] is
/// pushed to the native side, and pictures of the chosen clock style are
/// rendered for the face widgets that are actually on a home screen.
class WidgetSync {
  static bool _started = false;
  static Timer? _debounce;
  static int _generation = 0;

  /// The last rendered timeline per face widget, and what it was made from.
  static final Map<WidgetKind, (String, FrameSet)> _cache = {};

  static const _debounceTime = Duration(milliseconds: 350);

  static List<Listenable> get _sources => [
        TimerController.instance,
        StopwatchController.instance,
        AmbientService.instance,
        PomodoroLive.state,
        AlarmService.alarms,
        WorldPrefs.cities,
        AppPreferences.clockFormat,
        ClockPrefs.showDate,
        WidgetPrefs.dynamicColor,
        WidgetPrefs.quoteStyle,
        LocaleController.locale,
        ClockStyle.changes,
        Themes.accentChanges,
      ];

  /// Wires everything up. Safe to call more than once, and a no-op off
  /// Android.
  static void start() {
    if (_started || !WidgetBridge.supported) return;
    _started = true;

    for (final source in _sources) {
      source.addListener(schedule);
    }
    WidgetBridge.listen(onLaunch: WidgetLaunch.apply, onResync: schedule);
    WidgetBridge.takeLaunch().then((launch) {
      if (launch != null) WidgetLaunch.apply(launch);
    });
    schedule();
  }

  /// Asks for an update soon.
  static void schedule() {
    _debounce?.cancel();
    _debounce = Timer(_debounceTime, () => unawaited(_push(++_generation)));
  }

  @visibleForTesting
  static void stop() {
    for (final source in _sources) {
      source.removeListener(schedule);
    }
    _debounce?.cancel();
    _started = false;
    _cache.clear();
  }

  static String get _language {
    final chosen = LocaleController.locale.value?.languageCode ??
        PlatformDispatcher.instance.locale.languageCode;
    return resolveLanguage(chosen);
  }

  /// Both palettes the widgets use, from the system's Material You accent
  /// when allowed and available, otherwise from Enfo's own accent.
  static Future<({ColorScheme light, ColorScheme dark, bool dynamic})>
      _schemes() async {
    final systemSeed =
        WidgetPrefs.dynamicColor.value ? await WidgetBridge.systemSeed() : null;
    final seed = systemSeed == null ? Themes.accent : Color(systemSeed);
    return (
      light: Themes.light(seed).colorScheme,
      dark: Themes.dark(seed).colorScheme,
      dynamic: systemSeed != null,
    );
  }

  static Future<void> _push(int generation) async {
    bool isCurrent() => generation == _generation;
    final now = DateTime.now();
    final schemes = await _schemes();
    // Weekday and time formats are needed before the app's own delegates may
    // have loaded them.
    await initializeDateFormatting(_language);
    final l10n = currentL10n();
    final style = await ClockStyle.load();
    if (!isCurrent()) return;

    final pomodoro = PomodoroLive.state.value;
    final timer = TimerController.instance;
    final timerPhase = switch (timer.phase) {
      TimerPhase.idle => ClockPhase.idle,
      TimerPhase.running => ClockPhase.running,
      TimerPhase.paused => ClockPhase.paused,
    };

    final frames = <WidgetKind, FrameSet>{};
    final dir = await WidgetBridge.framesDir();
    final active = dir == null ? const <WidgetKind>{} : await _activeFaces();
    final labels = ClockLabels.of(l10n);
    if (!isCurrent()) return;

    Future<void> face(
      WidgetKind kind, {
      required bool rest,
      required ClockPhase phase,
      required int totalSeconds,
      required int remainingMs,
    }) async {
      if (dir == null || !active.contains(kind)) return;
      // Same inputs, same pictures: a running timeline stays valid for as
      // long as its end time does, so unrelated updates don't re-render.
      final endsAt = phase == ClockPhase.running
          ? now.millisecondsSinceEpoch + remainingMs
          : 0;
      final idleRemaining = phase == ClockPhase.running ? 0 : remainingMs;
      final signature = [
        style.name,
        rest,
        phase.name,
        totalSeconds,
        idleRemaining,
        // Running timelines are keyed by end time to the second.
        endsAt ~/ 1000,
        schemes.light.primary.toARGB32(),
        schemes.dark.primary.toARGB32(),
        labels.focus,
      ].join('|');

      final cached = _cache[kind];
      if (cached != null && cached.$1 == signature) {
        frames[kind] = cached.$2;
        return;
      }
      final set = await WidgetFrames.render(
        kind: kind,
        dir: dir,
        style: style,
        rest: rest,
        phase: phase,
        totalSeconds: totalSeconds,
        remainingMs: remainingMs,
        nowMs: now.millisecondsSinceEpoch,
        light: schemes.light,
        dark: schemes.dark,
        labels: labels,
        isCurrent: isCurrent,
      );
      if (set == null) return;
      _cache[kind] = (signature, set);
      frames[kind] = set;
    }

    await face(
      WidgetKind.pomodoro,
      rest: pomodoro.rest,
      phase: pomodoro.phase,
      totalSeconds: pomodoro.totalSeconds,
      remainingMs: pomodoro.remainingAt(now.millisecondsSinceEpoch),
    );
    await face(
      WidgetKind.timer,
      rest: false,
      phase: timerPhase,
      totalSeconds: timer.totalSeconds,
      remainingMs: timer.remainingMs,
    );
    if (!isCurrent()) return;

    final sessions = await SessionHistory.load();
    final stats = SessionStats(sessions, now: now);
    final ambient = AmbientService.instance;
    final music = <String, Object?>{
      'hasSong': ambient.musicPlaying || ambient.musicPaused,
      'playing': ambient.musicPlaying,
      'title': ambient.track.title,
      'artist': ambient.track.artist,
    };
    final focus = <String, Object?>{
      'today': formatDuration(stats.todayFocusSeconds),
      'detail': '${l10n.statsTodayPomodoros}: ${stats.todayPomodoros}',
      'streak': stats.currentStreakDays > 0
          ? l10n.statsStreak(stats.currentStreakDays)
          : '',
    };
    if (!isCurrent()) return;

    final snapshot = WidgetSnapshot.build(
      now: now,
      l10n: l10n,
      lang: _language,
      clockFormat: AppPreferences.clockFormat.value,
      showDate: ClockPrefs.showDate.value,
      dynamicColor: schemes.dynamic,
      light: schemes.light,
      dark: schemes.dark,
      pomodoro: pomodoro,
      timer: timer,
      stopwatch: StopwatchController.instance,
      alarms: AlarmService.alarms.value,
      worldCityIds: WorldPrefs.cities.value,
      music: music,
      focus: focus,
      quoteStyle: WidgetPrefs.quoteStyle.value,
      frames: frames,
    );
    await WidgetBridge.sync(WidgetSnapshot.encode(snapshot));

    if (dir != null) {
      for (final kind in const [WidgetKind.pomodoro, WidgetKind.timer]) {
        await WidgetFrames.prune(dir, kind, frames[kind]?.prefix);
        if (frames[kind] == null) _cache.remove(kind);
      }
    }
  }

  static Future<Set<WidgetKind>> _activeFaces() async {
    final kinds = await WidgetBridge.activeKinds();
    return kinds.where((k) => k.isFace).toSet();
  }
}
