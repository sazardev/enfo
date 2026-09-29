/// One beat of a vibration: when it starts, how strong it is (0..1) and how
/// long it lasts. Events are lists of these.
class Pulse {
  const Pulse(this.at, this.strength, [this.length = 20]);

  /// Milliseconds after the event starts.
  final int at;
  final double strength;
  final int length;

  int get end => at + length;
}

/// A named vibration: the app's haptic vocabulary is a fixed set of these,
/// so the same gesture always feels the same everywhere.
class HapticEvent {
  const HapticEvent(
    this.pulses, {
    this.micro = false,
    this.sharpness = 0.5,
    this.period,
  });

  final List<Pulse> pulses;

  /// Small UI feedback (taps, ticks). Rendered with the platform's own
  /// tuned haptic engine, which feels best for tiny events; composed events
  /// use amplitude-controlled patterns instead.
  final bool micro;

  /// iOS Core Haptics sharpness (0 soft .. 1 crisp).
  final double sharpness;

  /// For looping events (alarms): how often the pattern repeats, ms.
  final int? period;

  int get duration => pulses.isEmpty ? 0 : pulses.last.end;

  /// How "hit" the event is [ms] after it starts, 0..1: each pulse spikes to
  /// its strength when it lands and decays over its length plus a short tail.
  /// Animations read this so what you see follows what you feel.
  double envelopeAt(int ms) {
    var level = 0.0;
    for (final p in pulses) {
      if (ms < p.at) continue;
      final decay = 1 - ((ms - p.at) / (p.length + 160)).clamp(0.0, 1.0);
      final v = p.strength * decay;
      if (v > level) level = v;
    }
    return level;
  }
}

/// The vocabulary. Strengths are for the "medium" setting; the user's
/// strength scales all of them together, so the relationships hold.
abstract final class HapticEvents {
  // --- touch: the lightest, most frequent ---------------------------------
  static const tap = HapticEvent([Pulse(0, .30)], micro: true, sharpness: .6);
  static const select =
      HapticEvent([Pulse(0, .18)], micro: true, sharpness: .8);
  static const confirm = HapticEvent([Pulse(0, .55)], micro: true);
  static const toggleOn = HapticEvent(
    [Pulse(0, .30), Pulse(70, .55)],
    micro: true,
  );
  static const toggleOff = HapticEvent([Pulse(0, .26)], micro: true);
  static const lap = HapticEvent([Pulse(0, .50)], micro: true, sharpness: 1);

  // --- motion: things that move under your finger -------------------------
  static const tick = HapticEvent([Pulse(0, .16)], micro: true, sharpness: .9);
  static const dragStart = HapticEvent([Pulse(0, .45)], micro: true);
  static const drop = HapticEvent([Pulse(0, .35)], micro: true);
  static const transition = HapticEvent([Pulse(0, .28)], micro: true);

  // --- alerts: composed, meant to be noticed ------------------------------
  static const warning = HapticEvent(
    [Pulse(0, .65, 35), Pulse(90, .65, 35)],
    sharpness: .7,
  );
  static const success = HapticEvent(
    [Pulse(0, .45, 35), Pulse(100, .80, 60)],
    sharpness: .5,
  );

  /// Focus block finished, rest begins: a soft release, fading away.
  static const toRest = HapticEvent(
    [Pulse(0, .75, 80), Pulse(140, .50, 70), Pulse(280, .28, 90)],
    sharpness: .25,
  );

  /// Rest finished, focus begins: a charge that builds.
  static const toWork = HapticEvent(
    [Pulse(0, .30, 45), Pulse(110, .60, 55), Pulse(220, .95, 100)],
    sharpness: .8,
  );

  /// Interval trainer: a work block starts. A short, sharp double hit,
  /// distinct from the rising Pomodoro charge.
  static const go = HapticEvent(
    [Pulse(0, .85, 50), Pulse(90, 1.0, 90)],
    sharpness: .9,
  );

  /// Timer reached zero (one cycle; the ringer repeats it).
  static const timerDone = HapticEvent(
    [Pulse(0, .90, 90), Pulse(170, .90, 90), Pulse(340, 1.0, 150)],
    period: 1500,
    sharpness: .7,
  );

  /// Guided breathing: a soft swell for the inhale, a fading one for the
  /// exhale and a single faint touch for a hold.
  static const breatheIn = HapticEvent(
    [Pulse(0, .12, 60), Pulse(150, .20, 80), Pulse(320, .30, 110)],
    sharpness: .2,
  );
  static const breatheOut = HapticEvent(
    [Pulse(0, .30, 110), Pulse(200, .20, 80), Pulse(370, .12, 60)],
    sharpness: .2,
  );
  static const breatheHold =
      HapticEvent([Pulse(0, .14)], micro: true, sharpness: .3);

  /// Last seconds of a countdown: three taps that firm up.
  static HapticEvent countdown(int secondsLeft) => HapticEvent(
        [
          Pulse(
            0,
            switch (secondsLeft) {
              <= 1 => .75,
              2 => .50,
              _ => .35,
            },
          ),
        ],
        micro: true,
        sharpness: .8,
      );
}

/// What an alarm feels like while it rings. Each is one cycle that repeats
/// every [HapticEvent.period]; the ringing screen's animation is driven by
/// the same period, so what you see and what you feel beat together.
enum AlarmPattern {
  heartbeat(HapticEvent(
    [Pulse(0, .90, 70), Pulse(170, .60, 70)],
    period: 1200,
    sharpness: .35,
  )),
  pulse(HapticEvent(
    [Pulse(0, .80, 220)],
    period: 1000,
    sharpness: .5,
  )),
  crescendo(HapticEvent(
    [
      Pulse(0, .25, 80),
      Pulse(240, .40, 90),
      Pulse(480, .60, 100),
      Pulse(720, .80, 120),
      Pulse(960, 1.0, 180),
    ],
    period: 1600,
    sharpness: .6,
  )),
  ripple(HapticEvent(
    [
      Pulse(0, 1.0, 60),
      Pulse(140, .70, 50),
      Pulse(260, .50, 40),
      Pulse(360, .35, 30),
      Pulse(440, .20, 30),
    ],
    period: 1400,
    sharpness: .9,
  )),
  beacon(HapticEvent(
    [Pulse(0, 1.0, 400)],
    period: 2000,
    sharpness: .3,
  ));

  const AlarmPattern(this.event);

  final HapticEvent event;

  int get period => event.period!;
}
