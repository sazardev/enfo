import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../ui/design/spacing.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import 'event_logic.dart';
import 'label_wheel.dart';

/// Inline date and time choosers: day / month / year wheels plus hour /
/// minute wheels (no system pickers). One row of five wheels when there is
/// room, otherwise the date over the time.
class DateTimeWheels extends StatefulWidget {
  const DateTimeWheels({
    super.key,
    required this.value,
    required this.onChanged,
    this.extent = 48,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final double extent;

  @override
  State<DateTimeWheels> createState() => _DateTimeWheelsState();
}

class _DateTimeWheelsState extends State<DateTimeWheels> {
  late int _year = widget.value.year;
  late int _month = widget.value.month;
  late int _day = widget.value.day;
  late int _hour = widget.value.hour;
  late int _minute = widget.value.minute;

  late final int _yearFrom = math.min(1970, _year);
  late final int _yearTo = math.max(nowProvider().year + 60, _year);

  late final FixedExtentScrollController _dayC =
      FixedExtentScrollController(initialItem: _day - 1);
  late final FixedExtentScrollController _monthC =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _yearC =
      FixedExtentScrollController(initialItem: _year - _yearFrom);
  late final FixedExtentScrollController _hourC =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteC =
      FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    for (final c in [_dayC, _monthC, _yearC, _hourC, _minuteC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final max = daysInMonth(_year, _month);
    if (_day > max) {
      // 31 -> the last day of a shorter month: move the wheel with it.
      _day = max;
      if (_dayC.hasClients) {
        _dayC.animateToItem(
          _day - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
    widget.onChanged(DateTime(_year, _month, _day, _hour, _minute));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final months = [
      for (var m = 1; m <= 12; m++)
        DateFormat.MMM(locale).format(DateTime(2000, m)),
    ];
    final e = widget.extent;

    final day = LabelWheel(
      controller: _dayC,
      labels: [for (var d = 1; d <= 31; d++) two(d)],
      extent: e,
      loop: true,
      onChanged: (i) {
        _day = i + 1;
        _emit();
      },
    );
    final month = LabelWheel(
      controller: _monthC,
      labels: months,
      extent: e,
      loop: true,
      onChanged: (i) {
        _month = i + 1;
        _emit();
      },
    );
    final year = LabelWheel(
      controller: _yearC,
      labels: [for (var y = _yearFrom; y <= _yearTo; y++) '$y'],
      extent: e,
      onChanged: (i) {
        _year = _yearFrom + i;
        _emit();
      },
    );
    final hour = LabelWheel(
      controller: _hourC,
      labels: [for (var h = 0; h < 24; h++) two(h)],
      extent: e,
      loop: true,
      onChanged: (i) {
        _hour = i;
        _emit();
      },
    );
    final minute = LabelWheel(
      controller: _minuteC,
      labels: [for (var m = 0; m < 60; m++) two(m)],
      extent: e,
      loop: true,
      onChanged: (i) {
        _minute = i;
        _emit();
      },
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 460) {
        return WheelBand(
          extent: e,
          flex: const [10, 14, 14, 9, 9],
          children: [day, month, year, hour, minute],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WheelBand(
            extent: e,
            flex: const [10, 14, 14],
            children: [day, month, year],
          ),
          const SizedBox(height: AppSpacing.md),
          WheelBand(extent: e, children: [hour, minute]),
        ],
      );
    });
  }
}
