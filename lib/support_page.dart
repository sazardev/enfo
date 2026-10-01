import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/locale_controller.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

/// Ways to support the app: a coffee link.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  Future<void> _openCoffee() async {
    final uri = Uri.parse('https://www.buymeacoffee.com/sazarcode');
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: Platform.isAndroid
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.supportTitle,
      loaded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.supportHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        SettingsRow(
          label: l10n.buyCoffee,
          onTap: _openCoffee,
          trailing: const Icon(Icons.coffee_rounded),
        ),
      ],
    );
  }
}
