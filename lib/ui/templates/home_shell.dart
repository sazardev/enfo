import 'package:flutter/material.dart';

import '../design/spacing.dart';

/// Scaffold layout for the home screen: optional title-bar slot, a live
/// clock readout, the countdown dial filling the remaining space, and a
/// bottom control row.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    this.titleBar,
    required this.liveClock,
    required this.dial,
    required this.bottomControls,
  });

  final PreferredSizeWidget? titleBar;
  final Widget liveClock;
  final Widget dial;
  final Widget bottomControls;

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: bottomControls,
      ),
    );
  }
}
