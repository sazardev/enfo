import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/locale_controller.dart';

/// "Weekdays", "Every day", "Mon, Wed" ... for an alarm's repeat days.
String repeatSummary(BuildContext context, Set<int> days) {
  final l10n = context.l10n;
  if (days.isEmpty) return l10n.alarmOnce;
  if (days.length == 7) return l10n.alarmEveryDay;
  if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
    return l10n.alarmWeekdays;
  }
  if (days.length == 2 && days.containsAll({6, 7})) return l10n.alarmWeekends;
  final locale = Localizations.localeOf(context).toString();
  final sorted = days.toList()..sort();
  // 2024-01-01 was a Monday, so day n is January n.
  return sorted
      .map((d) => DateFormat.E(locale).format(DateTime(2024, 1, d)))
      .join(', ');
}
