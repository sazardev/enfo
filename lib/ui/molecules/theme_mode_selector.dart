import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';

/// System / Light / Dark, applied the moment it is chosen.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final adaptive = AdaptiveTheme.maybeOf(context);

    return SegmentedButton<AdaptiveThemeMode>(
      showSelectedIcon: false,
      // Flat: tonal fills instead of an outline.
      style: SegmentedButton.styleFrom(
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
      ),
      segments: [
        ButtonSegment(
          value: AdaptiveThemeMode.system,
          label: Text(l10n.themeModeSystem),
        ),
        ButtonSegment(
          value: AdaptiveThemeMode.light,
          label: Text(l10n.themeModeLight),
        ),
        ButtonSegment(
          value: AdaptiveThemeMode.dark,
          label: Text(l10n.themeModeDark),
        ),
      ],
      selected: {adaptive?.mode ?? AdaptiveThemeMode.system},
      onSelectionChanged: (s) {
        switch (s.first) {
          case AdaptiveThemeMode.system:
            adaptive?.setSystem();
          case AdaptiveThemeMode.light:
            adaptive?.setLight();
          case AdaptiveThemeMode.dark:
            adaptive?.setDark();
        }
        onChanged?.call();
      },
    );
  }
}
