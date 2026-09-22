import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// A closed-form, duration-agnostic spring curve (damped harmonic
/// oscillator). Like every other [Curve], `t` is a 0..1 fraction of whatever
/// [Duration] the caller assigns it — this is NOT a physics `Simulation`,
/// it's a fixed-shape easing curve driven by spring-like parameters.
///
/// Safe to use as `AnimatedContainer.curve`, `TweenAnimationBuilder.curve`,
/// `CurvedAnimation.curve`, or inside `.chain(CurveTween(...))` — those all
/// read an unclamped curve value.
///
/// NOT safe as the literal `curve:` argument of
/// `AnimationController.animateTo()`/`.animateBack()` on a normal bounded
/// (default 0..1) controller: the controller clamps its `.value` to its
/// bounds every frame, which silently flattens this curve's overshoot into a
/// plain ease with no error. Drive it through a `CurvedAnimation` instead
/// (its `.value` is unclamped), or use it on an `.unbounded()` controller.
class SpringCurve extends Curve {
  const SpringCurve({
    this.mass = 1.0,
    this.stiffness = 200.0,
    this.damping = 10.0,
  })  : assert(mass > 0),
        assert(stiffness > 0),
        assert(damping >= 0);

  final double mass;
  final double stiffness;
  final double damping;

  /// Playful, pronounced overshoot (~34%). Good for taps and celebratory pops.
  static const SpringCurve bouncy =
      SpringCurve(mass: 0.5, stiffness: 300, damping: 8);

  /// Quick settle with a light overshoot (~21%). Good for general UI motion.
  static const SpringCurve snappy =
      SpringCurve(mass: 1.0, stiffness: 400, damping: 18);

  /// Slow, subtle overshoot (~11%). Good for larger surfaces (sheets, cards).
  static const SpringCurve gentle =
      SpringCurve(mass: 2.0, stiffness: 150, damping: 20);

  double get _omegaN => math.sqrt(stiffness / mass);
  double get _zeta => damping / (2 * math.sqrt(stiffness * mass));

  @override
  double transformInternal(double t) {
    final omegaN = _omegaN;
    final zeta = _zeta;
    final decay = math.exp(-zeta * omegaN * t);

    if (zeta >= 1.0) {
      // Critically/over-damped: no oscillation, guards the omegaD divide
      // below. None of the three presets above hit this branch, but callers
      // may construct arbitrary mass/stiffness/damping combinations.
      return 1 - decay * (1 + omegaN * t);
    }

    final omegaD = omegaN * math.sqrt(1 - zeta * zeta);
    final osc =
        math.cos(omegaD * t) + (zeta * omegaN / omegaD) * math.sin(omegaD * t);
    return 1 - decay * osc;
  }
}

/// Shared motion tokens: durations and curve presets for the whole app.
abstract final class Motion {
  const Motion._();

  static const bouncy = SpringCurve.bouncy;
  static const snappy = SpringCurve.snappy;
  static const gentle = SpringCurve.gentle;

  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
