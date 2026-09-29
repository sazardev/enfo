import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../modes/fullscreen.dart';
import '../../modes/immersive_view.dart';
import '../../modes/mode_actions.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/pop_in.dart';
import '../design/responsive.dart';
import '../design/spacing.dart';

/// Adaptive scaffold for the home screen.
///
/// The timer visual always sits big and dead centre. The controls are bare
/// icons floating over the edge of the screen:
///
/// * Phones in portrait: a horizontal row at the bottom.
/// * Tablets, landscape phones, desktop, TV, car: a vertical column on the
///   right.
///
/// In both, [primaryAction] (play/pause, when the mode has one) is the last
/// button: bottom of the column, right end of the row.
/// * Watch: the visual plus one small row of icons.
/// * Full screen (see [Fullscreen]): the visual alone, edge to edge.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    this.titleBar,
    required this.liveClock,
    required this.dial,
    required this.actions,
    this.primaryAction,
  });

  final PreferredSizeWidget? titleBar;

  /// The live clock readout, or a shrunk box when the user hid it.
  final Widget liveClock;
  final Widget dial;

  /// Icon buttons (settings, stats, ...), in order.
  final List<Widget> actions;

  /// The mode's main control (play/pause), always placed last.
  final Widget? primaryAction;

  List<Widget> get _items => [
        ...actions,
        if (primaryAction != null) primaryAction!,
      ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: Fullscreen.active,
      builder: (context, fullscreen, _) {
        // Full screen: only the dial, edge to edge, chrome hidden.
        if (fullscreen) return ImmersiveView(child: dial);
        if (r.isWatch) return _watch(context, r);
        return _adaptive(context, r, vertical: _useRail(r));
      },
    );
  }

  /// Tablets in any orientation and anything landscape-wide get the
  /// vertical bar on the right; portrait phones keep it at the bottom.
  bool _useRail(Responsive r) => r.isWide || r.size.shortestSide >= 600;

  Widget _adaptive(BuildContext context, Responsive r,
      {required bool vertical}) {
    return Scaffold(
      appBar: titleBar,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final size = _buttonSize(r, box.biggest, vertical);
          // Reserve the bar's thickness on BOTH sides so the visual stays
          // exactly centred and never runs under the buttons.
          final reserve = size +
              _pad * 2 +
              (vertical ? r.pagePadding : AppSpacing.lg) +
              AppSpacing.sm;

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: vertical
                      ? EdgeInsets.symmetric(
                          horizontal: reserve,
                          vertical: AppSpacing.lg,
                        )
                      : EdgeInsets.symmetric(vertical: reserve),
                  child: dial,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: liveClock,
                ),
              ),
              Align(
                alignment:
                    vertical ? Alignment.centerRight : Alignment.bottomCenter,
                child: Padding(
                  padding: vertical
                      ? EdgeInsets.only(right: r.pagePadding * 0.6)
                      : const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _ActionBar(
                    items: _items,
                    vertical: vertical,
                    size: size,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Large, easy targets that shrink only as much as needed to all fit.
  double _buttonSize(Responsive r, Size box, bool vertical) {
    // ModeActionButtons groups up to three buttons in one widget.
    final n = math.max(
      1,
      _items.length + _items.whereType<ModeActionButtons>().length * 2,
    );
    final available = vertical
        ? box.height - AppSpacing.lg * 2
        : box.width - AppSpacing.sm * 2;
    final fit = (available - _pad * 2 - _gap * (n - 1)) / n;
    final ideal = (vertical ? 64.0 : 56.0) * math.min(r.scale, 1.25);
    return math.max(36.0, math.min(ideal, fit));
  }

  Widget _watch(BuildContext context, Responsive r) {
    // Round faces clip the corners: keep the dial inside the inscribed
    // circle's square and the controls at the bottom centre.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            r.size.width * 0.1,
            r.size.height * 0.1,
            r.size.width * 0.1,
            r.size.height * 0.04,
          ),
          child: Column(
            children: [
              Expanded(child: dial),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _items,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const double _gap = 6;
const double _pad = 6;

/// Just the buttons, no surface behind them.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.items,
    required this.vertical,
    required this.size,
  });

  final List<Widget> items;
  final bool vertical;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_pad),
      // Safety net: whatever the buttons add up to (grouped actions, extra
      // mode buttons, big text scale), shrink the bar instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AppIconButtonScope(
          size: size,
          axis: vertical ? Axis.vertical : Axis.horizontal,
          child: Flex(
            direction: vertical ? Axis.vertical : Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap, height: _gap),
                PopIn(
                  delay: Duration(milliseconds: 60 * i),
                  child: items[i],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
