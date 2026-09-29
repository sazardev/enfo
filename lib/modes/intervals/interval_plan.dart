import '../../l10n/gen/app_localizations.dart';

/// The four kinds of stretch a workout is made of.
enum IntervalKind {
  warmUp,
  work,
  rest,
  coolDown;

  /// Everything but work is drawn in the calmer "rest" palette.
  bool get isRest => this != IntervalKind.work;

  String label(AppLocalizations l10n) => switch (this) {
        IntervalKind.warmUp => l10n.intervalsWarmUp,
        IntervalKind.work => l10n.intervalsWork,
        IntervalKind.rest => l10n.intervalsRest,
        IntervalKind.coolDown => l10n.intervalsCoolDown,
      };
}

/// One stretch of the timeline: [durationMs] long, starting [startMs] after
/// the workout began. [round] is 1-based (0 for warm-up / cool-down).
class IntervalSegment {
  const IntervalSegment(this.kind, this.round, this.startMs, this.durationMs);

  final IntervalKind kind;
  final int round;
  final int startMs;
  final int durationMs;

  int get endMs => startMs + durationMs;
}

/// A workout: warm-up, [rounds] x (work + rest), cool-down. Durations are in
/// seconds; a zero warm-up, rest or cool-down is simply skipped. The rest
/// after the last round is skipped too (the cool-down or the end follows).
class IntervalPlan {
  const IntervalPlan({
    this.warmUp = 0,
    this.work = 20,
    this.rest = 10,
    this.rounds = 8,
    this.coolDown = 0,
  });

  final int warmUp;
  final int work;
  final int rest;
  final int rounds;
  final int coolDown;

  static const maxRounds = 99;
  static const maxSeconds = 99 * 60 + 59;

  IntervalPlan copyWith({
    int? warmUp,
    int? work,
    int? rest,
    int? rounds,
    int? coolDown,
  }) =>
      IntervalPlan(
        warmUp: warmUp ?? this.warmUp,
        work: work ?? this.work,
        rest: rest ?? this.rest,
        rounds: rounds ?? this.rounds,
        coolDown: coolDown ?? this.coolDown,
      );

  /// The whole timeline, in order.
  List<IntervalSegment> get segments {
    final out = <IntervalSegment>[];
    var t = 0;
    void add(IntervalKind kind, int round, int seconds) {
      if (seconds <= 0) return;
      out.add(IntervalSegment(kind, round, t, seconds * 1000));
      t += seconds * 1000;
    }

    add(IntervalKind.warmUp, 0, warmUp);
    for (var r = 1; r <= rounds; r++) {
      add(IntervalKind.work, r, work);
      if (r < rounds) add(IntervalKind.rest, r, rest);
    }
    add(IntervalKind.coolDown, 0, coolDown);
    return out;
  }

  int get totalSeconds =>
      warmUp +
      rounds * work +
      (rounds - 1).clamp(0, maxRounds) * rest +
      coolDown;

  int get totalMs => totalSeconds * 1000;

  /// Index of the segment containing [elapsedMs], or -1 once it is over.
  int indexAt(List<IntervalSegment> segs, int elapsedMs) {
    if (elapsedMs < 0) return 0;
    for (var i = 0; i < segs.length; i++) {
      if (elapsedMs < segs[i].endMs) return i;
    }
    return -1;
  }

  bool get isValid => rounds >= 1 && work > 0;

  @override
  bool operator ==(Object other) =>
      other is IntervalPlan &&
      other.warmUp == warmUp &&
      other.work == work &&
      other.rest == rest &&
      other.rounds == rounds &&
      other.coolDown == coolDown;

  @override
  int get hashCode => Object.hash(warmUp, work, rest, rounds, coolDown);

  Map<String, dynamic> toJson() => {
        'w': warmUp,
        'k': work,
        'r': rest,
        'n': rounds,
        'c': coolDown,
      };

  factory IntervalPlan.fromJson(Map<String, dynamic> j) => IntervalPlan(
        warmUp: (j['w'] as int? ?? 0).clamp(0, maxSeconds),
        work: (j['k'] as int? ?? 20).clamp(1, maxSeconds),
        rest: (j['r'] as int? ?? 0).clamp(0, maxSeconds),
        rounds: (j['n'] as int? ?? 1).clamp(1, maxRounds),
        coolDown: (j['c'] as int? ?? 0).clamp(0, maxSeconds),
      );
}

/// Built-in plans. The user's own lives under [custom].
enum IntervalPreset {
  tabata(IntervalPlan(work: 20, rest: 10, rounds: 8)),
  hiit(IntervalPlan(warmUp: 120, work: 40, rest: 20, rounds: 8, coolDown: 60)),
  emom(IntervalPlan(work: 60, rest: 0, rounds: 10)),
  custom(IntervalPlan(work: 30, rest: 15, rounds: 6));

  const IntervalPreset(this.plan);
  final IntervalPlan plan;

  String label(AppLocalizations l10n) => switch (this) {
        IntervalPreset.tabata => l10n.intervalsPresetTabata,
        IntervalPreset.hiit => l10n.intervalsPresetHiit,
        IntervalPreset.emom => l10n.intervalsPresetEmom,
        IntervalPreset.custom => l10n.intervalsPresetCustom,
      };
}
