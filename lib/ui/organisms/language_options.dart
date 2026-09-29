import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../molecules/settings_row.dart';

/// Radio list: follow the system language, or force Spanish / English.
/// Applies immediately (the whole app re-translates as you tap).
class LanguageOptions extends StatelessWidget {
  const LanguageOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, current, _) {
        Widget option(String label, Locale? value) {
          final selected = current?.languageCode == value?.languageCode;
          return SettingsRow(
            label: label,
            onTap: () => LocaleController.set(value),
            trailing: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            option(l10n.languageSystem, null),
            option(l10n.languageSpanish, const Locale('es')),
            option(l10n.languageEnglish, const Locale('en')),
          ],
        );
      },
    );
  }
}
