import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/design/spacing.dart';
import '../../ui/templates/settings_shell.dart';
import '../ambient/ambience_catalog.dart';
import '../ambient/ambience_labels.dart';
import '../ambient/music_catalog.dart';

/// Who made the bundled songs and ambience loops, and under which license
/// (CC BY asks for attribution).
class MusicCreditsPage extends StatelessWidget {
  const MusicCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget header(String label) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(label,
              style: text.labelLarge?.copyWith(color: muted)),
        );
    Widget loopLine(AmbienceLoop t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text('${t.label(l10n)} — ${t.artist} · ${t.license}',
              style: text.bodyMedium),
        );
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
        header(l10n.ambientNature),
        for (final t in natureLoops) loopLine(t),
        header(l10n.ambientPlaces),
        for (final t in placeLoops) loopLine(t),
      ],
    );
  }
}
