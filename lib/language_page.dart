import 'package:flutter/material.dart';

import 'l10n/locale_controller.dart';
import 'ui/design/spacing.dart';
import 'ui/organisms/language_options.dart';
import 'ui/templates/settings_shell.dart';

/// App language: follow the system, or force Spanish / English.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.languageTitle,
      loaded: true,
      children: [
        const LanguageOptions(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.languageHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
