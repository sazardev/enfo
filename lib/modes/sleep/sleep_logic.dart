/// Pure sleep-cycle maths: no widgets, no storage, "now" passed in.
///
/// A sleep cycle lasts about 90 minutes and a person takes about 15 minutes
/// to fall asleep. Waking at the end of a cycle (rather than in the middle
/// of deep sleep) is what feels easier.
library;

const int cycleMinutes = 90;
const int fallAsleepMinutes = 15;

/// How long before bedtime the wind-down reminder goes off.
const int windDownMinutes = 30;

/// Cycle counts suggested when working back from a wake-up time: the
/// recommended 6 and 5 first, then 4.
const List<int> bedtimeCycles = [6, 5, 4];

/// Cycle counts suggested going forward from bedtime.
const List<int> wakeCycles = [4, 5, 6];

bool isRecommended(int cycles) => cycles == 5 || cycles == 6;

/// What the user is asking.
enum SleepPlan {
  /// "I want to wake at HH:MM": suggest bedtimes.
  wakeAt,

  /// "I go to sleep at HH:MM": suggest wake-up times.
  sleepAt,

  /// "I go to sleep now": suggest wake-up times from the current time.
  sleepNow,
}

/// One suggestion: a moment on the clock and how much sleep it gives.
class SleepOption {
  const SleepOption({required this.cycles, required this.time});

  final int cycles;

  /// A bedtime (plan [SleepPlan.wakeAt]) or a wake-up time (the others).
  final DateTime time;

  /// Actual sleep, without the time to fall asleep.
  Duration get sleep => Duration(minutes: cycles * cycleMinutes);

  bool get recommended => isRecommended(cycles);
}

/// The next moment the clock reads [hour]:[minute], strictly after [now]
/// (today if it is still ahead, otherwise tomorrow).
DateTime nextOccurrence(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// Bedtimes that let [wake] fall at the end of a cycle.
List<SleepOption> bedtimesFor(DateTime wake) => [
      for (final c in bedtimeCycles)
        SleepOption(
          cycles: c,
          time: wake.subtract(
            Duration(minutes: c * cycleMinutes + fallAsleepMinutes),
          ),
        ),
    ];

/// Wake-up times if the user goes to bed at [bedtime].
List<SleepOption> wakeTimesFor(DateTime bedtime) => [
      for (final c in wakeCycles)
        SleepOption(
          cycles: c,
          time: bedtime.add(
            Duration(minutes: fallAsleepMinutes + c * cycleMinutes),
          ),
        ),
    ];

/// The moment the wind-down reminder should go off for [bedtime].
DateTime windDownFor(DateTime bedtime) =>
    bedtime.subtract(const Duration(minutes: windDownMinutes));

/// Everything the page needs for one state of the planner.
class SleepPlanResult {
  const SleepPlanResult({
    required this.options,
    required this.bedtimeOf,
    required this.wakeOf,
  });

  final List<SleepOption> options;

  /// When to be in bed if [option] is chosen.
  final DateTime Function(SleepOption option) bedtimeOf;

  /// When the alarm should ring if [option] is chosen.
  final DateTime Function(SleepOption option) wakeOf;
}

SleepPlanResult planFor({
  required SleepPlan plan,
  required DateTime now,
  required int wakeHour,
  required int wakeMinute,
  required int bedHour,
  required int bedMinute,
}) {
  switch (plan) {
    case SleepPlan.wakeAt:
      final wake = nextOccurrence(now, wakeHour, wakeMinute);
      return SleepPlanResult(
        options: bedtimesFor(wake),
        bedtimeOf: (o) => o.time,
        wakeOf: (_) => wake,
      );
    case SleepPlan.sleepAt:
      final bed = nextOccurrence(now, bedHour, bedMinute);
      return SleepPlanResult(
        options: wakeTimesFor(bed),
        bedtimeOf: (_) => bed,
        wakeOf: (o) => o.time,
      );
    case SleepPlan.sleepNow:
      // Rounded to the minute: an alarm has no seconds.
      final bed = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      return SleepPlanResult(
        options: wakeTimesFor(bed),
        bedtimeOf: (_) => bed,
        wakeOf: (o) => o.time,
      );
  }
}
