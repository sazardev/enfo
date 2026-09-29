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
  world(Icons.public_rounded);

  const AppMode(this.icon);

  final IconData icon;

  String labelOf(AppLocalizations l) => switch (this) {
        AppMode.pomodoro => l.modePomodoro,
        AppMode.clock => l.modeClock,
        AppMode.timer => l.modeTimer,
        AppMode.stopwatch => l.modeStopwatch,
        AppMode.alarm => l.modeAlarm,
        AppMode.world => l.modeWorld,
      };

  String descriptionOf(AppLocalizations l) => switch (this) {
        AppMode.pomodoro => l.modeDescPomodoro,
        AppMode.clock => l.modeDescClock,
        AppMode.timer => l.modeDescTimer,
        AppMode.stopwatch => l.modeDescStopwatch,
        AppMode.alarm => l.modeDescAlarm,
        AppMode.world => l.modeDescWorld,
      };
}
