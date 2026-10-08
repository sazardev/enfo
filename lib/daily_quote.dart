import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'focus_quotes.dart';
import 'l10n/locale_controller.dart';
import 'modes/notifier.dart';

/// The daily focus-quote notification: preferences, the day plan and the OS
/// scheduling. Works where [Notifier] can schedule (Android/iOS); every call
/// is best-effort, exactly like the rest of the notification plumbing.
///
/// The next [horizonDays] days are posted as individual one-shot
/// notifications (ids [firstId] + 0..29) instead of one repeating alarm, so
/// every day gets its own phrase. [refresh] cancels and re-posts the window;
/// it runs at boot (rolling the horizon and picking up a language change) and
/// whenever the switch or the time changes.
abstract final class DailyQuote {
  static const _enabledKey = 'focus_quote_enabled';
  static const _hourKey = 'focus_quote_hour';
  static const _minuteKey = 'focus_quote_minute';

  /// Ids reserved for the quote window (30 days).
  static const firstId = 9500;
  static const horizonDays = 30;
  static const defaultHour = 9;
  static const defaultMinute = 0;

  static bool enabled = false;
  static int hour = defaultHour;
  static int minute = defaultMinute;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_enabledKey) ?? false;
    hour = (prefs.getInt(_hourKey) ?? defaultHour).clamp(0, 23);
    minute = (prefs.getInt(_minuteKey) ?? defaultMinute).clamp(0, 59);
  }

  static Future<void> setEnabled(bool on) async {
    enabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
    await refresh();
  }

  static Future<void> setTime(int h, int m) async {
    hour = h.clamp(0, 23);
    minute = m.clamp(0, 59);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    await refresh();
  }

  /// The next [horizonDays] notifications from [now] on: an id, the instant
  /// and the localized quote for that day. Today is skipped when its time
  /// already passed, and the window slides to cover 30 future days.
  static List<({int id, DateTime at, String quote})> plan(DateTime now) {
    final l10n = currentL10n();
    final out = <({int id, DateTime at, String quote})>[];
    for (var d = 0; out.length < horizonDays; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final at = DateTime(day.year, day.month, day.day, hour, minute);
      if (!at.isAfter(now)) continue;
      out.add((id: firstId + d, at: at, quote: FocusQuotes.forDate(l10n, day)));
    }
    return out;
  }

  /// Cancels the window and posts the next one. No-op when disabled or where
  /// notifications cannot be scheduled; old slots are always cleared.
  static Future<void> refresh() async {
    // One more than [horizonDays]: today can be skipped and the ids shift.
    for (var d = 0; d <= horizonDays; d++) {
      await Notifier.cancel(firstId + d);
    }
    if (!enabled) return;
    final l10n = currentL10n();
    for (final slot in plan(DateTime.now())) {
      await Notifier.schedule(
        id: slot.id,
        at: slot.at,
        title: l10n.focusQuoteTitle,
        body: slot.quote,
        quote: true,
      );
    }
  }

  /// Back to a clean slate (tests, data reset).
  @visibleForTesting
  static void debugReset() {
    enabled = false;
    hour = defaultHour;
    minute = defaultMinute;
  }
}
