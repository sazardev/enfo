import 'package:flutter/material.dart';

import 'alarm/alarm_mode_page.dart';
import 'event/event_mode_page.dart';
import 'intervals/intervals_mode_page.dart';
import 'breathe/breathe_mode_page.dart';
import 'tracker/tracker_mode_page.dart';
import 'kitchen/kitchen_mode_page.dart';
import 'sleep/sleep_mode_page.dart';
import 'versus/versus_mode_page.dart';
import 'breaks/breaks_mode_page.dart';
import 'ambient/ambient_mode_page.dart';
import 'music/music_mode_page.dart';
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
      AppMode.event => const EventModePage(),
      AppMode.intervals => const IntervalsModePage(),
      AppMode.breathe => const BreatheModePage(),
      AppMode.tracker => const TrackerModePage(),
      AppMode.kitchen => const KitchenModePage(),
      AppMode.sleep => const SleepModePage(),
      AppMode.versus => const VersusModePage(),
      AppMode.breaks => const BreaksModePage(),
      AppMode.ambient => const AmbientModePage(),
      AppMode.music => const MusicModePage(),
    };
