import 'package:flutter/material.dart';

import '../bar_buttons.dart';
import '../clock_style_page.dart';
import '../l10n/locale_controller.dart';
import '../ui/clock/clock_style.dart';
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
      builder: (context, _) => Flex(
        direction: AppIconButtonScope.axisOf(context),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!r.isWatch)
            BarButtonVisibility(
              button: BarButton.modes,
              child: AppIconButton(
                tooltip: l10n.tooltipModes,
                onPressed: () => Navigator.of(context)
                    .push(appPageRoute((_) => const ModesPage())),
                icon: const Icon(Icons.apps_rounded),
              ),
            ),
          if (ModePrefs.enabled.length > 1)
            BarButtonVisibility(
              button: BarButton.switchMode,
              child: AppIconButton(
                tooltip: l10n.tooltipSwitchMode,
                onPressed: ModePrefs.step,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
            ),
          if (!r.isWatch)
            BarButtonVisibility(
              button: BarButton.fullscreen,
              child: AppIconButton(
                tooltip: l10n.tooltipFullscreen,
                onPressed: Fullscreen.enter,
                icon: const Icon(Icons.fullscreen_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the clock-style gallery from a mode that draws a dial; [onReturn]
/// runs afterwards so the dial can pick up the new choice.
class ClockStyleButton extends StatelessWidget {
  const ClockStyleButton({super.key, required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    if (r.isWatch) return const SizedBox.shrink();
    return BarButtonVisibility(
      button: BarButton.clockStyle,
      child: AppIconButton(
        tooltip: context.l10n.tooltipClockStyle,
        onPressed: () async {
          final style = await ClockStyle.load();
          if (!context.mounted) return;
          await Navigator.of(context)
              .push(appPageRoute((_) => ClockStylePage(selected: style)));
          onReturn();
        },
        icon: const Icon(Icons.timelapse_rounded),
      ),
    );
  }
}
