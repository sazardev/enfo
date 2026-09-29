import 'package:flutter/material.dart';

import '../../modes/fullscreen.dart';
import '../../modes/immersive_view.dart';
import '../design/responsive.dart';
import '../design/spacing.dart';

/// Adaptive scaffold for the home screen.
///
/// * Portrait / narrow: optional title bar, live clock, the dial filling the
///   remaining space, and a bottom control row.
/// * Wide (landscape phones, tablets, desktop, TV, car): the dial gets the
///   whole height on the left, and clock + controls move to a side panel so
///   the timer isn't squeezed into a thin strip.
/// * Watch: just the dial and one small control row.
/// * Full screen (see [Fullscreen]): the dial alone, edge to edge.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    this.titleBar,
    required this.liveClock,
    required this.dial,
    required this.actions,
  });

  final PreferredSizeWidget? titleBar;

  /// The live clock readout, or a shrunk box when the user hid it.
  final Widget liveClock;
  final Widget dial;

  /// Icon buttons (settings, stats, ...). Laid out in a row or a grid.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: Fullscreen.active,
      builder: (context, fullscreen, _) {
        // Full screen: only the dial, edge to edge, chrome hidden.
        if (fullscreen) return ImmersiveView(child: dial);
        if (r.isWatch) return _watch(context, r);
        if (r.isWide) return _wide(context, r);
        return _portrait(context, r);
      },
    );
  }

  Widget _portrait(BuildContext context, Responsive r) {
    return Scaffold(
      appBar: titleBar,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: liveClock,
            ),
          ),
          Expanded(child: dial),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            r.pagePadding * 0.6,
            AppSpacing.xs,
            r.pagePadding * 0.6,
            AppSpacing.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actions,
          ),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, Responsive r) {
    final panelWidth = (r.size.width * 0.34).clamp(240.0, 420.0 * r.scale);

    return Scaffold(
      appBar: titleBar,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: dial,
              ),
            ),
            SizedBox(
              width: panelWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.xl,
                  r.pagePadding,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: liveClock),
                    const SizedBox(height: AppSpacing.xxl),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
