import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../modes/timer/duration_wheels.dart';
import '../design/radii.dart';

/// Two looping hour/minute wheels on a highlighted band, shared by the sleep
/// planner and the daily-quote time.
class TimeWheels extends StatefulWidget {
  const TimeWheels({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
    this.extent = 40,
  });

  final int hour;
  final int minute;
  final double extent;
  final void Function(int hour, int minute) onChanged;

  @override
  State<TimeWheels> createState() => _TimeWheelsState();
}

class _TimeWheelsState extends State<TimeWheels> {
  late final FixedExtentScrollController _h =
      FixedExtentScrollController(initialItem: widget.hour);
  late final FixedExtentScrollController _m =
      FixedExtentScrollController(initialItem: widget.minute);

  @override
  void dispose() {
    _h.dispose();
    _m.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_h.selectedItem % 24, _m.selectedItem % 60);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final e = widget.extent;
    return SizedBox(
      height: e * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: e,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: LoopWheel(
                  controller: _h,
                  count: 24,
                  unit: l10n.timerHoursShort,
                  extent: e,
                  onChanged: _emit,
                ),
              ),
              Expanded(
                child: LoopWheel(
                  controller: _m,
                  count: 60,
                  unit: l10n.timerMinutesShort,
                  extent: e,
                  onChanged: _emit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
