import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tv/tv_mode.dart';
import 'ui/design/radii.dart';

class Themes {
  static const Color defaultAccent = Colors.lime;

  /// The accent the app is currently themed with (loaded at startup).
  static Color accent = defaultAccent;

  /// Bumped whenever [accent] changes, for things that mirror it outside the
  /// widget tree (the home-screen widgets).
  static final accentChanges = ValueNotifier<int>(0);

  static const _accentKey = 'accent_color';
  // Legacy: the accent used to be stored as an index into [colors]. The
  // first 16 entries keep their order so old indexes still resolve.
  static const _legacyIndexKey = 'defaultIndex';

  static Future<void> loadAccent() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_accentKey);
    if (stored != null) {
      accent = Color(stored);
      return;
    }
    final legacy = prefs.getInt(_legacyIndexKey);
    if (legacy != null && legacy >= 0 && legacy < colors.length) {
      accent = colors[legacy];
    }
  }

  /// Back to the built-in accent, in memory only (callers that erase
  /// preferences have already removed the stored value).
  static void resetAccent() {
    accent = defaultAccent;
    accentChanges.value++;
  }

  static Future<void> saveAccent(Color color) async {
    accent = color;
    accentChanges.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.toARGB32());
  }

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
    // Extra variety (appended: never reorder the entries above).
    Color(0xFFE11D48), // rose
    Color(0xFFF43F5E), // coral
    Color(0xFFD946EF), // fuchsia
    Color(0xFF7C3AED), // violet
    Color(0xFF6366F1), // periwinkle
    Color(0xFF2563EB), // royal blue
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // aqua
    Color(0xFF10B981), // emerald
    Color(0xFF84CC16), // pear
    Color(0xFFF59E0B), // honey
    Color(0xFFEA580C), // tangerine
    Color(0xFF8B5E3C), // cocoa
    Color(0xFF64748B), // slate
    Color(0xFF334155), // midnight
    Color(0xFF111827), // ink
  ];

  static const String fontFamily = 'GeistMono';

  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

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

    // Material buttons have their own focus overlay, separate from
    // BouncyTap. On a TV it must be strong enough to read from the sofa.
    final tvFocusOverlay = TvMode.isTv
        ? WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.focused)) {
              return colorScheme.onSurface.withValues(alpha: 0.24);
            }
            return null;
          })
        : null;
    final tvFocusSide = TvMode.isTv
        ? WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.92),
                width: 2.5,
              );
            }
            return null;
          })
        : null;

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
        overlayColor: tvFocusOverlay,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const StadiumBorder(),
        ).copyWith(
          overlayColor: tvFocusOverlay,
          side: tvFocusSide,
        ),
      ),
      textButtonTheme: TvMode.isTv
          ? TextButtonThemeData(
              style: TextButton.styleFrom().copyWith(
                overlayColor: tvFocusOverlay,
                side: tvFocusSide,
              ),
            )
          : null,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: AppRadii.pill,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ).copyWith(
          overlayColor: tvFocusOverlay,
          side: tvFocusSide,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: AppRadii.pill,
          side: BorderSide.none,
          backgroundColor: colorScheme.surfaceContainerHigh,
        ).copyWith(
          overlayColor: tvFocusOverlay,
          side: tvFocusSide,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        // A TV has no hover and the focus halo must be visible from the
        // sofa; phones keep the flat, overlay-free look.
        overlayShape: TvMode.isTv
            ? const RoundSliderOverlayShape(overlayRadius: 20)
            : SliderComponentShape.noOverlay,
        overlayColor:
            TvMode.isTv ? colorScheme.primary.withValues(alpha: 0.18) : null,
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
