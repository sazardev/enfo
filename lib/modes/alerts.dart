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
