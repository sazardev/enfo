/// Shared layout constraints for the whole app.
abstract final class AppLayout {
  const AppLayout._();

  /// Max width for a readable content column — keeps forms/grids from
  /// stretching edge-to-edge on wide desktop windows or landscape/tablet
  /// screens, where an unconstrained 2-4 column grid would otherwise render
  /// each item oversized.
  static const double maxContentWidth = 480;
}
