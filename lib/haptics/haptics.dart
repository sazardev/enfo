import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'haptic_events.dart';

/// Which family of feedback an event belongs to. Each can be switched off.
enum HapticCategory { touch, motion, alerts }

/// How hard everything hits. One dial scales the whole vocabulary, so a
/// tap is always softer than a confirm, whatever the setting.
enum HapticStrength {
  soft(0.6),
  medium(1.0),
  strong(1.4);

  const HapticStrength(this.multiplier);
  final double multiplier;
}

/// Enfo's vibration.
///
/// Every place that vibrates asks for a *named event* (`Haptics.tap()`,
/// `Haptics.phaseComplete(...)`, ...) instead of picking a raw buzz, so taps,
/// wheels, transitions, phase changes and alarms form one consistent
/// language. Users can turn it off, change the strength, switch categories
/// (touch / motion / alerts) and choose the alarm pattern.
///
/// Rendering: tiny events go through the platform's own haptic engine (best
/// tuned); composed events use amplitude-controlled patterns when the device
/// supports them, and fall back to a sequence of system impacts otherwise.
class Haptics {
  static const _enabledKey = 'haptics';
  static const _strengthKey = 'haptic_strength';
  static const _touchKey = 'haptic_touch';
  static const _motionKey = 'haptic_motion';
  static const _alertsKey = 'haptic_alerts';
  static const _patternKey = 'haptic_alarm_pattern';

  static final enabled = ValueNotifier<bool>(true);
  static final strength = ValueNotifier<HapticStrength>(HapticStrength.medium);
  static final touch = ValueNotifier<bool>(true);
  static final motion = ValueNotifier<bool>(true);
  static final alerts = ValueNotifier<bool>(true);
  static final alarmPattern =
      ValueNotifier<AlarmPattern>(AlarmPattern.heartbeat);

  static Listenable get changes => Listenable.merge(
      [enabled, strength, touch, motion, alerts, alarmPattern]);

  /// Tests force this; otherwise only phones have a vibration motor worth
  /// driving.
  @visibleForTesting
  static bool? debugAvailable;

  static bool get available =>
      debugAvailable ?? (Platform.isAndroid || Platform.isIOS);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? true;
    final s = prefs.getString(_strengthKey);
    strength.value = HapticStrength.values.firstWhere(
      (v) => v.name == s,
      orElse: () => HapticStrength.medium,
    );
    touch.value = prefs.getBool(_touchKey) ?? true;
    motion.value = prefs.getBool(_motionKey) ?? true;
    alerts.value = prefs.getBool(_alertsKey) ?? true;
    final p = prefs.getString(_patternKey);
    alarmPattern.value = AlarmPattern.values.firstWhere(
      (v) => v.name == p,
      orElse: () => AlarmPattern.heartbeat,
    );
  }

  static Future<void> _setBool(
      String key, ValueNotifier<bool> n, bool v) async {
    n.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  static Future<void> setEnabled(bool v) => _setBool(_enabledKey, enabled, v);
  static Future<void> setTouch(bool v) => _setBool(_touchKey, touch, v);
  static Future<void> setMotion(bool v) => _setBool(_motionKey, motion, v);
  static Future<void> setAlerts(bool v) => _setBool(_alertsKey, alerts, v);

  static Future<void> setStrength(HapticStrength v) async {
    strength.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_strengthKey, v.name);
  }

  static Future<void> setAlarmPattern(AlarmPattern v) async {
    alarmPattern.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patternKey, v.name);
  }

  // ------------------------------------------------------------ vocabulary

  // touch
  static void tap() => _fire(HapticCategory.touch, HapticEvents.tap);
  static void select() => _fire(HapticCategory.touch, HapticEvents.select);
  static void confirm() => _fire(HapticCategory.touch, HapticEvents.confirm);
  static void lap() => _fire(HapticCategory.touch, HapticEvents.lap);
  static void toggle(bool on) => _fire(HapticCategory.touch,
      on ? HapticEvents.toggleOn : HapticEvents.toggleOff);

  // motion
  static void tick() => _fire(HapticCategory.motion, HapticEvents.tick);
  static void dragStart() =>
      _fire(HapticCategory.motion, HapticEvents.dragStart);
  static void drop() => _fire(HapticCategory.motion, HapticEvents.drop);
  static void transition() =>
      _fire(HapticCategory.motion, HapticEvents.transition);

  /// Guided breathing cues (motion category: they follow the body).
  static void breatheIn() =>
      _fire(HapticCategory.motion, HapticEvents.breatheIn);
  static void breatheOut() =>
      _fire(HapticCategory.motion, HapticEvents.breatheOut);
  static void breatheHold() =>
      _fire(HapticCategory.motion, HapticEvents.breatheHold);

  // alerts
  static void warning() => _fire(HapticCategory.alerts, HapticEvents.warning);
  static void success() => _fire(HapticCategory.alerts, HapticEvents.success);
  static void timerDone() =>
      _fire(HapticCategory.alerts, HapticEvents.timerDone);
  static void countdown(int secondsLeft) =>
      _fire(HapticCategory.alerts, HapticEvents.countdown(secondsLeft));

  /// A Pomodoro phase ended: [toRest] true when focus just finished.
  static void phaseComplete({required bool toRest}) => _fire(
      HapticCategory.alerts,
      toRest ? HapticEvents.toRest : HapticEvents.toWork);

  /// Interval trainer: a work block starts.
  static void go() => _fire(HapticCategory.alerts, HapticEvents.go);

  /// One cycle of the ringer. [timer] true for a finished timer (its own
  /// triple beat); otherwise the user's alarm pattern.
  static void ringCycle({bool timer = false}) => _fire(
        HapticCategory.alerts,
        timer ? HapticEvents.timerDone : alarmPattern.value.event,
      );

  /// Length of one ringer cycle, ms. The ringing screen animates on this.
  static int ringPeriod({bool timer = false}) =>
      timer ? HapticEvents.timerDone.period! : alarmPattern.value.period;

  /// Plays [event] ignoring the category switches (the settings page uses
  /// this so you can feel a setting even while its category is off). The
  /// master switch and the strength still apply.
  static void preview(HapticEvent event) => _fire(null, event);

  /// Cuts any vibration in progress (e.g. when the ringer is dismissed).
  static Future<void> cancel() async {
    for (final t in _pending) {
      t.cancel();
    }
    _pending.clear();
    if (!available) return;
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// The ringer as an Android notification vibration pattern
  /// (`[wait, on, wait, on, ...]`), so a notification that fires with the app
  /// closed feels like the in-app ringer. Notifications can't set amplitude,
  /// so the user's strength stretches or shrinks each buzz instead.
  static Int64List notificationPattern({bool timer = false}) {
    final event = timer ? HapticEvents.timerDone : alarmPattern.value.event;
    final scale = strength.value.multiplier;
    final out = <int>[];
    var cursor = 0;
    for (final p in event.pulses) {
      out
        ..add(p.at - cursor)
        ..add((p.length * scale).round().clamp(10, 1000));
      cursor = p.end;
    }
    return Int64List.fromList(out);
  }

  // -------------------------------------------------------------- engine

  /// Minimum gap between tiny events, ms. Tests set 0: their fake clock
  /// doesn't advance real time, so consecutive events would be swallowed.
  @visibleForTesting
  static int debounceMs = 22;

  static final List<Timer> _pending = [];
  static DateTime _lastMicro = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<_Caps>? _caps;

  static bool _categoryOn(HapticCategory? c) => switch (c) {
        HapticCategory.touch => touch.value,
        HapticCategory.motion => motion.value,
        HapticCategory.alerts => alerts.value,
        null => true,
      };

  static void _fire(HapticCategory? category, HapticEvent event) {
    if (!available || !enabled.value || !_categoryOn(category)) return;
    final mult = strength.value.multiplier;
    if (event.micro) {
      _micro(event, mult);
    } else {
      _composed(event, mult);
    }
  }

  static void _micro(HapticEvent event, double mult) {
    // A fast wheel can ask for a tick every few ms; the motor can't keep up
    // and the taps smear into a buzz.
    final now = DateTime.now();
    if (now.difference(_lastMicro).inMilliseconds < debounceMs) return;
    _lastMicro = now;

    final start = event.pulses.first.at;
    for (final p in event.pulses) {
      final s = p.strength * mult;
      void play() {
        // Crossover points chosen so "medium" keeps a tap light and a
        // confirm firm, and "soft"/"strong" shift both together.
        if (s < .20) {
          HapticFeedback.selectionClick();
        } else if (s < .40) {
          HapticFeedback.lightImpact();
        } else if (s < .70) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      }

      final delay = p.at - start;
      if (delay <= 0) {
        play();
      } else {
        late Timer t;
        t = Timer(Duration(milliseconds: delay), () {
          _pending.remove(t);
          play();
        });
        _pending.add(t);
      }
    }
  }

  static Future<void> _composed(HapticEvent event, double mult) async {
    final caps = await (_caps ??= _probe());
    if (caps.amplitude) {
      final pattern = <int>[];
      final intensities = <int>[];
      var cursor = 0;
      for (final p in event.pulses) {
        pattern
          ..add(p.at - cursor)
          ..add(p.length);
        intensities
          ..add(0)
          ..add((p.strength * mult * 255).round().clamp(1, 255));
        cursor = p.end;
      }
      try {
        await Vibration.vibrate(
          pattern: pattern,
          intensities: intensities,
          sharpness: event.sharpness,
        );
        return;
      } catch (_) {
        // fall through to system impacts
      }
    }

    // No amplitude control: approximate the shape with system impacts.
    for (final p in event.pulses) {
      final s = p.strength * mult;
      void play() {
        if (s < .35) {
          HapticFeedback.lightImpact();
        } else if (s < .75) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      }

      if (p.at == 0) {
        play();
      } else {
        late Timer t;
        t = Timer(Duration(milliseconds: p.at), () {
          _pending.remove(t);
          play();
        });
        _pending.add(t);
      }
    }
  }

  /// Tests pretend the device does / doesn't have amplitude control.
  @visibleForTesting
  static bool? debugAmplitude;

  static Future<_Caps> _probe() async {
    final forced = debugAmplitude;
    if (forced != null) return _Caps(amplitude: forced);
    try {
      final has = await Vibration.hasVibrator();
      final amp = await Vibration.hasAmplitudeControl();
      return _Caps(amplitude: has && amp);
    } catch (_) {
      return const _Caps(amplitude: false);
    }
  }

  /// Forget the probed capabilities (tests swap the fake device).
  @visibleForTesting
  static void resetCapabilities() => _caps = null;
}

class _Caps {
  const _Caps({required this.amplitude});
  final bool amplitude;
}
