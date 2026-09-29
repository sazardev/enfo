import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/design/spacing.dart';
import '../../ui/templates/settings_shell.dart';
import '../ambient/music_catalog.dart';

/// Who made the bundled songs and under which license (CC BY asks for it).
class MusicCreditsPage extends StatelessWidget {
  const MusicCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SettingsShell(
      title: l10n.ambientMusicCredits,
      loaded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(l10n.ambientMusicCreditsNote,
              style: text.bodySmall?.copyWith(color: muted)),
        ),
        for (final t in musicCatalog)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text('${t.title} — ${t.artist} · ${t.license}',
                style: text.bodyMedium),
          ),
      ],
    );
  }
}
