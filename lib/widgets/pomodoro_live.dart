import 'package:flutter/foundation.dart';

import '../ui/clock/clock_frame.dart';

/// What the Pomodoro dial is doing right now, published so the home-screen
/// widgets can show it. The dial owns the real state (an animation
/// controller); this is only a read-only mirror plus one command channel.
@immutable
class PomodoroState {
  const PomodoroState({
    this.phase = ClockPhase.idle,
    this.rest = false,
    this.totalSeconds = 25 * 60,
    this.remainingMs = 25 * 60 * 1000,
    this.publishedAtMs = 0,
  });

  final ClockPhase phase;
  final bool rest;
  final int totalSeconds;

  /// Time left in the current phase at the moment of publishing.
  final int remainingMs;
  final int publishedAtMs;

  /// Time left at [nowMs]: a running phase keeps counting down after it was
  /// published, the others stand still.
  int remainingAt(int nowMs) {
    if (phase != ClockPhase.running) return remainingMs;
    final left = remainingMs - (nowMs - publishedAtMs);
    return left < 0 ? 0 : left;
  }
}

class PomodoroLive {
  static final state = ValueNotifier<PomodoroState>(const PomodoroState());

  /// A widget asked to start/pause the Pomodoro. Consumed by the dial, which
  /// may not exist yet when the app is launched by the tap.
  static final toggleRequests = ValueNotifier<int>(0);
  static bool pendingToggle = false;

  static void publish(PomodoroState next) => state.value = next;

  static void requestToggle() {
    pendingToggle = true;
    toggleRequests.value++;
  }
}
