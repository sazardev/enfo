import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'bar_buttons.dart';
import 'l10n/locale_controller.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';
import 'ui/atoms/app_switch.dart';

/// What the home screen shows: the live clock above the timer and how it
/// formats the time.
class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    Widget formatOption(String label, ClockFormat format, ClockFormat current) {
      final selected = format == current;
      return SettingsRow(
        label: label,
        onTap: () => AppPreferences.setClockFormat(format),
        trailing: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      );
    }

    Widget sizeOption(String label, UiSize size, UiSize current) {
      final selected = size == current;
      return SettingsRow(
        label: label,
        onTap: () => AppPreferences.setUiSize(size),
        trailing: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SettingsShell(
      title: l10n.displayTitle,
      loaded: true,
      children: [
        ValueListenableBuilder<UiSize>(
          valueListenable: AppPreferences.uiSize,
          builder: (context, current, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.xs,
                ),
                child: Text(
                  l10n.uiSizeTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              sizeOption(l10n.uiSizeSmall, UiSize.small, current),
              sizeOption(l10n.uiSizeNormal, UiSize.normal, current),
              sizeOption(l10n.uiSizeLarge, UiSize.large, current),
              sizeOption(l10n.uiSizeExtraLarge, UiSize.extraLarge, current),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.uiSizeHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ValueListenableBuilder<Set<BarButton>>(
          valueListenable: BarButtons.hidden,
          builder: (context, hidden, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.xs,
                ),
                child: Text(
                  l10n.displayMenuButtons,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              for (final button in BarButton.values)
                SettingsRow(
                  label: button.labelOf(l10n),
                  trailing: AppSwitch(
                    value: !hidden.contains(button),
                    onChanged: (on) => BarButtons.setVisible(button, on),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.displayMenuButtonsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.showClock,
          builder: (context, show, _) => SettingsRow(
            label: l10n.showClock,
            subtitle: l10n.showClockHint,
            trailing: AppSwitch(
              value: show,
              onChanged: AppPreferences.setShowClock,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.showClock,
          builder: (context, show, _) => AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: show ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !show,
              child: ValueListenableBuilder<ClockFormat>(
                valueListenable: AppPreferences.clockFormat,
                builder: (context, current, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        l10n.clockFormat,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    formatOption(
                        l10n.clockFormatSystem, ClockFormat.system, current),
                    formatOption(l10n.clockFormat12, ClockFormat.h12, current),
                    formatOption(l10n.clockFormat24, ClockFormat.h24, current),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
