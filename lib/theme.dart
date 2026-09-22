import 'package:flutter/material.dart';

import 'ui/design/radii.dart';

class Themes {
  static int defaultIndex = 10;

  static const List<Color> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  static const String fontFamily = 'GeistMono';

  static ThemeData light(int index) => _build(colors[index], Brightness.light);

  static ThemeData dark(int index) => _build(colors[index], Brightness.dark);

  static ThemeData changeTheme(int index, bool isDark) =>
      _build(colors[index], isDark ? Brightness.dark : Brightness.light);

  static ThemeData _build(Color seed, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // Build the default Material 3 text theme (correctly colored from
    // colorScheme) first, then only swap its font family — constructing a
    // TextTheme from Typography directly yields color-less geometry styles
    // and makes text fall back to the wrong (often unreadable) color.
    final textTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    ).textTheme.apply(fontFamily: fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      // Flat design: interactive feedback comes from BouncyTap's press-scale
      // spring, not Material ink ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // Navigation uses `appPageRoute` (ui/design/page_transition.dart)
      // everywhere, not MaterialPageRoute, so Flutter's own safe per-platform
      // defaults here are never actually exercised — left unset deliberately
      // rather than overridden with a solid-fill cross-fade builder.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgRadius),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdRadius),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const StadiumBorder(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: AppRadii.pill,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: AppRadii.pill,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        overlayShape: SliderComponentShape.noOverlay,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }
}
