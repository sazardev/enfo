import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app_preferences.dart';

/// Coarse screen class, decided from the logical window size alone (Flutter
/// can't tell a watch from a TV, but their sizes are unmistakable).
enum FormFactor {
  /// Wearables: ~200 dp. Stripped-down UI, timer first.
  watch,

  /// Phones in portrait.
  compact,

  /// Large phones sideways, small tablets, small desktop windows.
  medium,

  /// Tablets, desktop, TV, car displays.
  expanded,
}

/// Everything layout code needs to adapt to the screen it is on.
///
/// Read with [Responsive.of]; it rebuilds the caller when the window size,
/// the system text scale, or the user's "UI size" setting changes.
class Responsive {
  const Responsive._({
    required this.size,
    required this.factor,
    required this.scale,
  });

  final Size size;
  final FormFactor factor;

  /// Multiplier applied to text, icons and content widths so everything
  /// grows on big screens (and with the user's UI-size choice).
  final double scale;

  /// Below this shortest side the screen is treated as a watch. Kept under
  /// the Windows minimum window size (310x280) so a desktop window never
  /// flips into watch mode.
  static const double watchShortestSide = 260;

  static Responsive of(BuildContext context) {
    // Depending on the text scaler too: main() rewrites it whenever the UI
    // size changes, and that is what triggers the rebuild.
    MediaQuery.textScalerOf(context);
    return fromSize(
      MediaQuery.sizeOf(context),
      uiSize: AppPreferences.uiSize.value,
    );
  }

  static Responsive fromSize(Size size, {UiSize uiSize = UiSize.normal}) {
    final shortest = size.shortestSide;
    final FormFactor factor;
    if (shortest < watchShortestSide) {
      factor = FormFactor.watch;
    } else if (size.width < 600) {
      factor = FormFactor.compact;
    } else if (size.width < 840) {
      factor = FormFactor.medium;
    } else {
      factor = FormFactor.expanded;
    }

    // Phones stay at 1.0; bigger screens grow gently, capped so a huge
    // window doesn't balloon the UI. Watches stay at 1.0 (already tiny).
    final base = factor == FormFactor.watch
        ? 1.0
        : (shortest / 480).clamp(1.0, 1.5).toDouble();
    return Responsive._(
      size: size,
      factor: factor,
      scale: base * uiSize.multiplier,
    );
  }

  bool get isWatch => factor == FormFactor.watch;
  bool get isLandscape => size.width > size.height;

  /// Side-by-side layout: room for the timer plus a control panel.
  bool get isWide => !isWatch && size.width >= 600 && size.aspectRatio > 1.15;

  /// Master-detail settings: needs real width, in any orientation.
  bool get isExpanded => factor == FormFactor.expanded;

  /// Readable content column width for forms and lists.
  double get contentWidth {
    if (isWatch) return double.infinity;
    final base = switch (factor) {
      FormFactor.compact => 480.0,
      FormFactor.medium => 620.0,
      _ => 720.0,
    };
    return math.min(base * scale, size.width);
  }

  /// Horizontal page padding.
  double get pagePadding => isWatch ? 10 : (20 * math.min(scale, 1.3));
}
