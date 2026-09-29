import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/design/radii.dart';
import '../format.dart';

/// Hours / minutes / seconds wheels. Reports the total in seconds, and
/// follows [totalSeconds] when it is changed from outside (a preset tap).
class DurationWheels extends StatefulWidget {
  const DurationWheels({
    super.key,
    required this.totalSeconds,
    required this.onChanged,
    this.itemExtent = 60,
  });

  final int totalSeconds;
  final ValueChanged<int> onChanged;
  final double itemExtent;

  @override
  State<DurationWheels> createState() => _DurationWheelsState();
}

class _DurationWheelsState extends State<DurationWheels> {
  late final FixedExtentScrollController _hours =
      FixedExtentScrollController(initialItem: widget.totalSeconds ~/ 3600);
  late final FixedExtentScrollController _minutes = FixedExtentScrollController(
    initialItem: (widget.totalSeconds % 3600) ~/ 60,
  );
  late final FixedExtentScrollController _seconds =
      FixedExtentScrollController(initialItem: widget.totalSeconds % 60);

  // Looping wheels report unbounded indexes: fold them back into range.
  int get _h => _hours.selectedItem % 100;
  int get _m => _minutes.selectedItem % 60;
  int get _s => _seconds.selectedItem % 60;

  void _emit() => widget.onChanged(_h * 3600 + _m * 60 + _s);

  @override
  void didUpdateWidget(covariant DurationWheels oldWidget) {
    super.didUpdateWidget(oldWidget);
    final total = widget.totalSeconds;
    // Only move wheels when the change came from outside (not from a drag).
    if (total == _h * 3600 + _m * 60 + _s) return;
    // Spin the short way round the loop.
    void go(FixedExtentScrollController c, int count, int target) {
      var delta = (target - c.selectedItem) % count;
      if (delta > count ~/ 2) delta -= count;
      if (delta == 0) return;
      c.animateToItem(
        c.selectedItem + delta,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    go(_hours, 100, total ~/ 3600);
    go(_minutes, 60, (total % 3600) ~/ 60);
    go(_seconds, 60, total % 60);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.itemExtent * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band the selected row sits in.
          Container(
            height: widget.itemExtent,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: LoopWheel(
                  controller: _hours,
                  count: 100,
                  unit: l10n.timerHoursShort,
                  extent: widget.itemExtent,
                  onChanged: _emit,
                ),
              ),
              Expanded(
                child: LoopWheel(
                  controller: _minutes,
                  count: 60,
                  unit: l10n.timerMinutesShort,
                  extent: widget.itemExtent,
                  onChanged: _emit,
                ),
              ),
              Expanded(
                child: LoopWheel(
                  controller: _seconds,
                  count: 60,
                  unit: l10n.timerSecondsShort,
                  extent: widget.itemExtent,
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

/// One looping numeric wheel with a unit label; shared by the timer and the
/// alarm time pickers.
class LoopWheel extends StatelessWidget {
  const LoopWheel({
    super.key,
    required this.controller,
    required this.count,
    required this.unit,
    required this.extent,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String unit;
  final double extent;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final digits = TextStyle(
      fontSize: extent * 0.62,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1,
    );

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: extent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 2.4,
      perspective: 0.002,
      overAndUnderCenterOpacity: 0.3,
      onSelectedItemChanged: (_) => onChanged(),
      childDelegate: ListWheelChildLoopingListDelegate(
        children: [
          for (var i = 0; i < count; i++)
            Center(
              // Shrinks on very narrow screens (watch) rather than clipping.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(two(i), style: digits),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: extent * 0.24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
