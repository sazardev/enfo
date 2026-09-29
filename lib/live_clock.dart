import 'dart:async';

import 'package:flutter/material.dart';

import 'app_preferences.dart';

class LiveClock extends StatefulWidget {
  final TextStyle? style;

  const LiveClock({super.key, this.style});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ClockFormat>(
      valueListenable: AppPreferences.clockFormat,
      builder: (context, format, _) {
        final use24h = switch (format) {
          ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
          ClockFormat.h12 => false,
          ClockFormat.h24 => true,
        };
        final time = MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(_now),
          alwaysUse24HourFormat: use24h,
        );
        return Text(time, style: widget.style);
      },
    );
  }
}
