import 'package:flutter/widgets.dart';

import 'responsive.dart';

/// Shared layout constraints for the whole app.
abstract final class AppLayout {
  const AppLayout._();

  /// Fixed phone-sized content width. Prefer [contentWidth], which adapts
  /// to the screen; this stays for callers that want a constant.
  static const double maxContentWidth = 480;

  /// Max width for a readable content column — keeps forms/grids from
  /// stretching edge-to-edge on wide desktop windows or landscape/tablet
  /// screens, while growing with the screen so tablets and TVs aren't left
  /// with a thin phone-width strip.
  static double contentWidth(BuildContext context) =>
      Responsive.of(context).contentWidth;

  /// Wider column for dense screens (statistics) on large displays.
  static double wideContentWidth(BuildContext context) {
    final r = Responsive.of(context);
    return r.isExpanded ? r.size.width * 0.9 : r.contentWidth;
  }
}
