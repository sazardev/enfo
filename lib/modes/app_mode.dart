import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// The things Enfo can be. Pomodoro is one of them; the rest turn the app
/// into a general clock/timer toolbox.
enum AppMode {
  pomodoro(Icons.hourglass_bottom_rounded),
  clock(Icons.schedule_rounded),
  timer(Icons.timer_outlined),
  stopwatch(Icons.av_timer_rounded),
  alarm(Icons.alarm_rounded),
  world(Icons.public_rounded),
  // "More tools": off until the user turns them on.
  event(Icons.event_rounded, core: false),
  intervals(Icons.fitness_center_rounded, core: false),
  breathe(Icons.air_rounded, core: false),
  tracker(Icons.track_changes_rounded, core: false),
  kitchen(Icons.restaurant_rounded, core: false),
  sleep(Icons.bedtime_rounded, core: false),
  versus(Icons.swap_horiz_rounded, core: false),
  breaks(Icons.self_improvement_rounded, core: false),
  ambient(Icons.graphic_eq_rounded, core: false),
  music(Icons.library_music_rounded, core: false);

  const AppMode(this.icon, {this.core = true});

  final IconData icon;

  /// Core modes are on for everyone; the rest start off (see [ModePrefs]).
  final bool core;

  String labelOf(AppLocalizations l) => switch (this) {
        AppMode.pomodoro => l.modePomodoro,
        AppMode.clock => l.modeClock,
        AppMode.timer => l.modeTimer,
        AppMode.stopwatch => l.modeStopwatch,
        AppMode.alarm => l.modeAlarm,
        AppMode.world => l.modeWorld,
        AppMode.event => l.modeEvent,
        AppMode.intervals => l.modeIntervals,
        AppMode.breathe => l.modeBreathe,
        AppMode.tracker => l.modeTracker,
        AppMode.kitchen => l.modeKitchen,
        AppMode.sleep => l.modeSleep,
        AppMode.versus => l.modeVersus,
        AppMode.breaks => l.modeBreaks,
        AppMode.ambient => l.modeAmbient,
        AppMode.music => l.modeMusic,
      };

  String descriptionOf(AppLocalizations l) => switch (this) {
        AppMode.pomodoro => l.modeDescPomodoro,
        AppMode.clock => l.modeDescClock,
        AppMode.timer => l.modeDescTimer,
        AppMode.stopwatch => l.modeDescStopwatch,
        AppMode.alarm => l.modeDescAlarm,
        AppMode.world => l.modeDescWorld,
        AppMode.event => l.modeDescEvent,
        AppMode.intervals => l.modeDescIntervals,
        AppMode.breathe => l.modeDescBreathe,
        AppMode.tracker => l.modeDescTracker,
        AppMode.kitchen => l.modeDescKitchen,
        AppMode.sleep => l.modeDescSleep,
        AppMode.versus => l.modeDescVersus,
        AppMode.breaks => l.modeDescBreaks,
        AppMode.ambient => l.modeDescAmbient,
        AppMode.music => l.modeDescMusic,
      };
}
