import 'package:flutter/material.dart';

import '../../app_preferences.dart';

/// Whether the user wants a 24 h clock (their setting, else the system's).
bool use24hOf(BuildContext context) =>
    switch (AppPreferences.clockFormat.value) {
      ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };

/// "14:30" or "2:30 PM" following the user's clock format.
String formatHourMinute(BuildContext context, int hour, int minute) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: use24hOf(context),
    );
