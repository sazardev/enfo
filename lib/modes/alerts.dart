import 'package:flutter/material.dart';

/// Something that needs the user's attention right now: an alarm going off,
/// a timer reaching zero.
class RingRequest {
  const RingRequest({
    required this.title,
    required this.icon,
    required this.onDismiss,
    this.subtitle,
    this.snoozeMinutes,
    this.onSnooze,
    this.onExpire,
    this.timer = false,
    this.giveUpAfter,
    this.gentle = false,
    this.dismissLabel,
    this.extraLabel,
    this.onExtra,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  /// Stop it.
  final VoidCallback onDismiss;

  /// Offer "snooze N minutes" (alarms).
  final int? snoozeMinutes;
  final VoidCallback? onSnooze;

  /// Nobody answered for a couple of minutes (alarms log this as missed).
  final VoidCallback? onExpire;

  /// A finished timer (its own beat) rather than an alarm.
  final bool timer;

  /// How long before [onExpire] runs on its own (default two minutes).
  final Duration? giveUpAfter;

  /// A soft prompt (a short break): no alert sound, a light haptic tap.
  final bool gentle;

  /// Replaces the "Dismiss" label (e.g. "Done").
  final String? dismissLabel;

  /// One more choice next to Dismiss/Snooze (e.g. "Skip").
  final String? extraLabel;
  final VoidCallback? onExtra;
}

/// Queue of things ringing. The host shows the front one full screen;
/// finishing it reveals the next.
class Alerts {
  static final current = ValueNotifier<RingRequest?>(null);
  static final List<RingRequest> _queue = [];

  static void ring(RingRequest request) {
    if (current.value == null) {
      current.value = request;
    } else {
      _queue.add(request);
    }
  }

  /// Called by the ringing screen when the front request is handled.
  static void finish() {
    current.value = _queue.isEmpty ? null : _queue.removeAt(0);
  }

  @visibleForTesting
  static void reset() {
    _queue.clear();
    current.value = null;
  }
}
