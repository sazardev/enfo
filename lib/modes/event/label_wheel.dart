import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../haptics/haptics.dart';
import '../../ui/design/radii.dart';

/// A wheel of text rows (numbers, month names, years), looping or not.
/// Same feel as the timer's [LoopWheel]: a haptic tick per notch, Up/Down
/// keys turn it, and it wears a soft halo when focused by keyboard / D-pad.
class LabelWheel extends StatelessWidget {
  const LabelWheel({
    super.key,
    required this.controller,
    required this.labels,
    required this.extent,
    required this.onChanged,
    this.loop = false,
    this.semanticLabel,
  });

  final FixedExtentScrollController controller;
  final List<String> labels;
  final double extent;
  final bool loop;
  final String? semanticLabel;

  /// Called with the selected index (already folded into range).
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final digits = TextStyle(
      fontSize: extent * 0.5,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      height: 1,
    );

    final rows = [
      for (final label in labels)
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: digits),
          ),
        ),
    ];

    final wheel = ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: extent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 2.4,
      perspective: 0.002,
      overAndUnderCenterOpacity: 0.3,
      onSelectedItemChanged: (i) {
        Haptics.tick();
        onChanged(i % labels.length);
      },
      childDelegate: loop
          ? ListWheelChildLoopingListDelegate(children: rows)
          : ListWheelChildListDelegate(children: rows),
    );

    return Semantics(
      label: semanticLabel,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyUpEvent) return KeyEventResult.ignored;
          final step = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowUp => 1,
            LogicalKeyboardKey.arrowDown => -1,
            LogicalKeyboardKey.pageUp => 5,
            LogicalKeyboardKey.pageDown => -5,
            _ => 0,
          };
          if (step == 0 || !controller.hasClients) {
            return KeyEventResult.ignored;
          }
          var target = controller.selectedItem + step;
          if (!loop) target = target.clamp(0, labels.length - 1);
          controller.animateToItem(
            target,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        },
        child: Builder(
          builder: (context) {
            final showFocus = Focus.of(context).hasFocus &&
                FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: showFocus
                    ? colorScheme.primary.withValues(alpha: 0.22)
                    : Colors.transparent,
                borderRadius: AppRadii.mdRadius,
              ),
              child: wheel,
            );
          },
        ),
      ),
    );
  }
}

/// Wheels side by side over one soft band that marks the selected row.
class WheelBand extends StatelessWidget {
  const WheelBand({
    super.key,
    required this.extent,
    required this.children,
    this.flex,
  });

  final double extent;

  /// The wheels; each is wrapped in an [Expanded] (with its [flex] entry).
  final List<Widget> children;
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: extent * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: extent,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < children.length; i++)
                Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ),
        ],
      ),
    );
  }
}
