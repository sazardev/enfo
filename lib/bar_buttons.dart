import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/gen/app_localizations.dart';

/// The optional buttons of the bottom menu. Settings is not here on purpose:
/// it is the way back to this very list, so it always stays.
enum BarButton {
  stats,
  clockStyle,
  modes,
  switchMode,
  fullscreen;

  String labelOf(AppLocalizations l) => switch (this) {
        BarButton.stats => l.tooltipStats,
        BarButton.clockStyle => l.tooltipClockStyle,
        BarButton.modes => l.tooltipModes,
        BarButton.switchMode => l.tooltipSwitchMode,
        BarButton.fullscreen => l.tooltipFullscreen,
      };

  IconData get icon => switch (this) {
        BarButton.stats => Icons.bar_chart_rounded,
        BarButton.clockStyle => Icons.timelapse_rounded,
        BarButton.modes => Icons.apps_rounded,
        BarButton.switchMode => Icons.swap_horiz_rounded,
        BarButton.fullscreen => Icons.fullscreen_rounded,
      };
}

/// Which of the [BarButton]s the user chose to hide.
class BarButtons {
  static const _key = 'hidden_bar_buttons';

  static final hidden = ValueNotifier<Set<BarButton>>(<BarButton>{});

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hidden.value = {
      for (final name in prefs.getStringList(_key) ?? const <String>[])
        ...BarButton.values.where((b) => b.name == name),
    };
  }

  static Future<void> setVisible(BarButton button, bool visible) async {
    final next = {...hidden.value};
    visible ? next.remove(button) : next.add(button);
    hidden.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [for (final b in next) b.name]);
  }
}

/// Shows [child] unless the user hid [button] in the display settings.
class BarButtonVisibility extends StatelessWidget {
  const BarButtonVisibility({
    super.key,
    required this.button,
    required this.child,
  });

  final BarButton button;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<BarButton>>(
      valueListenable: BarButtons.hidden,
      builder: (context, hidden, _) =>
          hidden.contains(button) ? const SizedBox.shrink() : child,
    );
  }
}
