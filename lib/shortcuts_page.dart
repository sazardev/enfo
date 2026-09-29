import 'package:flutter/material.dart';

import 'l10n/locale_controller.dart';
import 'ui/design/radii.dart';
import 'ui/design/spacing.dart';
import 'ui/templates/settings_shell.dart';

/// The list of keyboard / remote shortcuts (see `AppShortcuts`).
class ShortcutsPage extends StatelessWidget {
  const ShortcutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final rows = <(List<String>, String)>[
      ([l10n.shortcutKeySpace], l10n.shortcutPlayPause),
      (['R'], l10n.shortcutReset),
      (['L'], l10n.shortcutLap),
      (['1', '…', '9'], l10n.shortcutJumpMode),
      (['[', ']'], l10n.shortcutStepMode),
      (['F', 'F11'], l10n.shortcutFullscreen),
      (['D'], l10n.shortcutDim),
      (['S'], l10n.shortcutSettings),
      (['M'], l10n.shortcutModes),
      (['Esc'], l10n.shortcutBack),
      (['?', 'F1'], l10n.shortcutHelp),
    ];

    return SettingsShell(
      title: l10n.shortcutsTitle,
      loaded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.shortcutsIntro,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final (keys, label) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                for (final key in keys)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: AppRadii.smRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          key,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
