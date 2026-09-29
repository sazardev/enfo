import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../ui/atoms/app_icon_button.dart';
import '../ui/design/page_transition.dart';
import '../ui/design/responsive.dart';
import 'fullscreen.dart';
import 'mode_prefs.dart';
import 'modes_page.dart';

/// The three buttons every mode's control bar shares: open the modes menu,
/// jump to the next mode, go full screen. A watch keeps only "next mode".
/// One widget (not three) so it can rebuild itself when modes are toggled.
class ModeActionButtons extends StatelessWidget {
  const ModeActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: ModePrefs.changes,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!r.isWatch)
            AppIconButton(
              tooltip: l10n.tooltipModes,
              onPressed: () => Navigator.of(context)
                  .push(appPageRoute((_) => const ModesPage())),
              icon: const Icon(Icons.apps_rounded),
            ),
          if (ModePrefs.enabled.length > 1)
            AppIconButton(
              tooltip: l10n.tooltipSwitchMode,
              onPressed: ModePrefs.step,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          if (!r.isWatch)
            AppIconButton(
              tooltip: l10n.tooltipFullscreen,
              onPressed: Fullscreen.enter,
              icon: const Icon(Icons.fullscreen_rounded),
            ),
        ],
      ),
    );
  }
}
