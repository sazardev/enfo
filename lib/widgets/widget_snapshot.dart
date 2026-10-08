import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../app_preferences.dart';
import '../focus_quotes.dart';
import '../l10n/gen/app_localizations.dart';
import '../modes/alarm/alarm.dart';
import '../modes/alarm/alarm_service.dart';
import '../modes/stopwatch/stopwatch_controller.dart';
import '../modes/timer/timer_controller.dart';
import '../modes/world/cities.dart';
import '../ui/clock/clock_frame.dart';
import 'pomodoro_live.dart';
import 'widget_bridge.dart';
import 'widget_frames.dart';

/// Everything the native widgets need, as one JSON document. Native code
/// never reads Flutter's own preference file: this is the whole contract,
/// so the two sides can change independently.
///
/// Times are absolute wall-clock milliseconds (the native side turns them
/// into chronometer bases), so nothing here goes stale while the app is
/// closed — a running timer just keeps its `endsAt`.
class WidgetSnapshot {
  const WidgetSnapshot._();

  static const version = 1;
  static const maxWorldCities = 4;
  static const maxAlarms = 8;

  /// Days of focus quotes carried in the snapshot, so the quote widget keeps
  /// changing at midnight for two weeks with the app closed.
  static const quoteDays = 14;

  static String encode(Map<String, Object?> snapshot) => jsonEncode(snapshot);

  static Map<String, Object?> build({
    required DateTime now,
    required AppLocalizations l10n,
    required String lang,
    required ClockFormat clockFormat,
    required bool showDate,
    required bool dynamicColor,
    required ColorScheme light,
    required ColorScheme dark,
    required PomodoroState pomodoro,
    required TimerController timer,
    required StopwatchController stopwatch,
    required List<Alarm> alarms,
    required List<String> worldCityIds,
    required Map<String, Object?> music,
    required Map<String, Object?> focus,
    int quoteStyle = 0,
    Map<WidgetKind, FrameSet> frames = const {},
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    final h24 = switch (clockFormat) {
      ClockFormat.system => null,
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };

    return {
      'v': version,
      'at': nowMs,
      'lang': lang,
      'h24': h24,
      'showDate': showDate,
      'dynamic': dynamicColor,
      'palette': {'light': _palette(light), 'dark': _palette(dark)},
      'labels': {
        'app': l10n.appTitle,
        'focus': l10n.phaseFocus,
        'relax': l10n.phaseRelax,
        'paused': l10n.phasePaused,
        'timer': l10n.modeTimer,
        'stopwatch': l10n.modeStopwatch,
        'alarm': l10n.modeAlarm,
        'world': l10n.modeWorld,
        'timerDone': l10n.timerUpTitle,
        'noAlarms': l10n.alarmNone,
        'local': l10n.worldLocal,
        'today': l10n.worldToday,
        'tomorrow': l10n.worldTomorrow,
        'yesterday': l10n.worldYesterday,
        'quote': l10n.focusQuoteTitle,
      },
      'pomodoro': _countdown(
        phase: pomodoro.phase,
        totalSeconds: pomodoro.totalSeconds,
        remainingMs: pomodoro.remainingAt(nowMs),
        nowMs: nowMs,
        rest: pomodoro.rest,
        frames: frames[WidgetKind.pomodoro],
      ),
      'timer': {
        ..._countdown(
          phase: switch (timer.phase) {
            TimerPhase.idle => ClockPhase.idle,
            TimerPhase.running => ClockPhase.running,
            TimerPhase.paused => ClockPhase.paused,
          },
          totalSeconds: timer.totalSeconds,
          remainingMs: timer.remainingMs,
          nowMs: nowMs,
          rest: false,
          frames: frames[WidgetKind.timer],
        ),
        'presets': timer.presets.take(4).toList(),
      },
      'stopwatch': {
        'running': stopwatch.running,
        'elapsedMs': stopwatch.elapsed.inMilliseconds,
        'laps': stopwatch.laps.length,
      },
      'alarms': _alarms(alarms, now, l10n, lang, h24),
      'world': _world(worldCityIds, lang),
      'music': music,
      'focus': focus,
      'quote': {'style': quoteStyle, 'days': _quotes(now, l10n, lang)},
    };
  }

  /// One entry per calendar day from today on: the midnight that starts it,
  /// the phrase and a short localized date for the footer.
  static List<Map<String, Object?>> _quotes(
    DateTime now,
    AppLocalizations l10n,
    String lang,
  ) {
    final dateFormat = DateFormat.MMMEd(lang);
    final out = <Map<String, Object?>>[];
    for (var d = 0; d < quoteDays; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      out.add({
        'at': day.millisecondsSinceEpoch,
        'text': FocusQuotes.forDate(l10n, day),
        'day': dateFormat.format(day),
      });
    }
    return out;
  }

  static Map<String, int> _palette(ColorScheme cs) => {
        'surface': cs.surfaceContainer.toARGB32(),
        'tile': cs.surfaceContainerHighest.toARGB32(),
        'onSurface': cs.onSurface.toARGB32(),
        'variant': cs.onSurfaceVariant.toARGB32(),
        'primary': cs.primary.toARGB32(),
        'onPrimary': cs.onPrimary.toARGB32(),
        'container': cs.primaryContainer.toARGB32(),
        'onContainer': cs.onPrimaryContainer.toARGB32(),
      };

  static Map<String, Object?> _countdown({
    required ClockPhase phase,
    required int totalSeconds,
    required int remainingMs,
    required int nowMs,
    required bool rest,
    required FrameSet? frames,
  }) {
    return {
      'phase': phase.name,
      'rest': rest,
      'total': totalSeconds,
      'remainingMs': remainingMs,
      if (phase == ClockPhase.running) 'endsAt': nowMs + remainingMs,
      if (frames != null) 'frames': frames.toJson(),
    };
  }

  /// The next rings, soonest first. Repeating alarms contribute several, so
  /// the widget still shows the right one after a ring passes with the app
  /// closed (it just skips the ones already gone).
  static List<Map<String, Object?>> _alarms(
    List<Alarm> alarms,
    DateTime now,
    AppLocalizations l10n,
    String lang,
    bool? h24,
  ) {
    final upcoming = <(DateTime, Alarm)>[];
    for (final a in alarms) {
      var at = AlarmService.nextFire(a, now);
      for (var i = 0; at != null && i < 6; i++) {
        upcoming.add((at, a));
        if (!a.repeats) break;
        final next = AlarmService.nextFire(a, at);
        if (next == null || !next.isAfter(at)) break;
        at = next;
      }
    }
    upcoming.sort((x, y) => x.$1.compareTo(y.$1));

    return [
      for (final (at, alarm) in upcoming.take(maxAlarms))
        {
          'at': at.millisecondsSinceEpoch,
          'time': _time(at, lang, h24),
          'repeat': alarm.repeats ? _repeat(alarm.days, l10n, lang) : '',
          'label': alarm.label,
        },
    ];
  }

  /// `07:30`, or `7:30 AM` in 12-hour mode. Without an explicit choice the
  /// app's language decides, as the rest of the UI does.
  static String _time(DateTime at, String lang, bool? h24) {
    final use24 = h24 ?? (lang != 'en' && lang != 'hi');
    return (use24 ? DateFormat.Hm(lang) : DateFormat.jm(lang)).format(at);
  }

  static String _repeat(Set<int> days, AppLocalizations l10n, String lang) {
    if (days.length == 7) return l10n.alarmEveryDay;
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return l10n.alarmWeekdays;
    }
    if (days.length == 2 && days.containsAll({6, 7})) return l10n.alarmWeekends;
    final sorted = days.toList()..sort();
    // 2024-01-01 was a Monday, so day n is January n.
    return sorted
        .map((d) => DateFormat.E(lang).format(DateTime(2024, 1, d)))
        .join(', ');
  }

  static List<Map<String, String>> _world(List<String> ids, String lang) {
    final rows = <Map<String, String>>[];
    for (final id in ids) {
      final city = cityById(id);
      if (city == null) continue;
      rows.add({'name': city.name(lang), 'zone': city.zone});
      if (rows.length == maxWorldCities) break;
    }
    return rows;
  }
}
