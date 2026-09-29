import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../bar_buttons.dart';
import '../l10n/locale_controller.dart';
import '../settings.dart';
import '../ui/atoms/app_icon_button.dart';
import '../ui/design/page_transition.dart';
import '../ui/design/responsive.dart';
import '../ui/organisms/live_clock_bar.dart';
import '../ui/templates/home_shell.dart';
import 'activity_page.dart';
import 'mode_actions.dart';
import 'platform_title_bar.dart';

/// The shell every non-Pomodoro mode sits in: same adaptive layout, title
/// bar, control bar and full-screen behavior as the Pomodoro home, so
/// switching modes feels like one app.
class ModeScaffold extends StatelessWidget {
  const ModeScaffold({
    super.key,
    required this.body,
    this.actions = const [],
    this.primaryAction,
    this.showClockBar = true,
  });

  /// The mode's main content: fills the space the timer dial would.
  final Widget body;

  /// Mode-specific buttons, placed before the shared ones.
  final List<Widget> actions;

  /// The mode's play/pause control; the shell places it last in the bar.
  final Widget? primaryAction;

  /// The little "current time" readout. A clock mode hides it (redundant).
  final bool showClockBar;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final l10n = context.l10n;

    return HomeShell(
      titleBar: platformTitleBar(),
      liveClock: showClockBar
          ? ValueListenableBuilder<bool>(
              valueListenable: AppPreferences.showClock,
              builder: (context, show, _) => show
                  ? LiveClockBar(fontSize: r.isWide ? 22 : 14)
                  : const SizedBox.shrink(),
            )
          : const SizedBox.shrink(),
      dial: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
        child: body,
      ),
      actions: [
        AppIconButton(
          tooltip: l10n.tooltipSettings,
          onPressed: () =>
              Navigator.of(context).push(appPageRoute((_) => const Settings())),
          icon: const Icon(Icons.tune_rounded),
        ),
        if (!r.isWatch)
          BarButtonVisibility(
            button: BarButton.stats,
            child: AppIconButton(
              tooltip: l10n.tooltipActivity,
              onPressed: () => Navigator.of(context)
                  .push(appPageRoute((_) => const ActivityPage())),
              icon: const Icon(Icons.bar_chart_rounded),
            ),
          ),
        ...actions,
        const ModeActionButtons(),
      ],
      primaryAction: primaryAction,
    );
  }
}
