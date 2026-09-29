import 'package:flutter/material.dart';

import 'alarm/alarm_mode_page.dart';
import 'app_mode.dart';
import 'clock/clock_mode_page.dart';
import 'stopwatch/stopwatch_mode_page.dart';
import 'timer/timer_mode_page.dart';
import 'world/world_clock_page.dart';

/// The screen for each non-Pomodoro mode (Pomodoro is the app's original
/// home screen, kept alive by the host).
Widget modePage(AppMode mode) => switch (mode) {
      AppMode.pomodoro => const SizedBox.shrink(),
      AppMode.clock => const ClockModePage(),
      AppMode.timer => const TimerModePage(),
      AppMode.stopwatch => const StopwatchModePage(),
      AppMode.alarm => const AlarmModePage(),
      AppMode.world => const WorldClockPage(),
    };
