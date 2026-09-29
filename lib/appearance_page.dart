import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'accent_color_page.dart';
import 'clock_style_page.dart';
import 'l10n/locale_controller.dart';
import 'theme.dart';
import 'ui/clock/clock_style.dart';
import 'ui/clock/clock_style_l10n.dart';
import 'ui/design/page_transition.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/theme_mode_selector.dart';

/// Theme mode and accent color.
class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  Color _accent = Themes.accent;
  ClockStyle _clockStyle = ClockStyle.ring;

  @override
  void initState() {
    super.initState();
    _loadClockStyle();
  }

  Future<void> _loadClockStyle() async {
    final style = await ClockStyle.load();
    if (mounted) setState(() => _clockStyle = style);
  }

  Future<void> _pickClockStyle() async {
    await Navigator.of(context).push(
      appPageRoute((context) => ClockStylePage(selected: _clockStyle)),
    );
    await _loadClockStyle();
  }

  Future<void> _pickAccentColor() async {
    final color = await Navigator.of(context).push<Color>(
      appPageRoute(
        (context) => AccentColorPage(
          colors: Themes.colors,
          selected: _accent,
        ),
      ),
    );
    if (color == null || !mounted) return;

    setState(() {
      _accent = color;
      AdaptiveTheme.of(context).setTheme(
        light: Themes.light(color),
        dark: Themes.dark(color),
      );
    });
    await Themes.saveAccent(color);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.appearanceTitle,
      loaded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: const ThemeModeSelector(),
        ),
        SettingsRow(
          label: l10n.accentColor,
          onTap: _pickAccentColor,
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SettingsRow(
          label: l10n.clockStyleTitle,
          subtitle: _clockStyle.labelOf(l10n),
          onTap: _pickClockStyle,
          trailing: Icon(
            Icons.timelapse_rounded,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
