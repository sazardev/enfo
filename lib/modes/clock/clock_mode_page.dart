import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../app_preferences.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/design/page_transition.dart';
import '../mode_scaffold.dart';
import 'clock_prefs.dart';
import 'clock_settings_page.dart';
import 'faces.dart';
import 'time_builder.dart';

/// Clock mode: Enfo as a beautiful clock. Swipe to change the design; use
/// the full-screen button for a desk / nightstand clock that stays on.
class ClockModePage extends StatelessWidget {
  const ClockModePage({super.key});

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    ClockPrefs.setFace(ClockPrefs.face.value.step(velocity < 0 ? 1 : -1));
  }

  @override
  Widget build(BuildContext context) {
    return ModeScaffold(
      showClockBar: false,
      actions: [
        AppIconButton(
          tooltip: context.l10n.tooltipCustomize,
          onPressed: () => Navigator.of(context)
              .push(appPageRoute((_) => const ClockSettingsPage())),
          icon: const Icon(Icons.palette_outlined),
        ),
      ],
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _swipe,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            ClockPrefs.changes,
            AppPreferences.clockFormat,
          ]),
          builder: (context, _) {
            final face = ClockPrefs.face.value;
            // Only the analog second hand needs frame-rate updates; a clock
            // left on all night shouldn't redraw 60 times a second.
            final smooth =
                face == ClockFace.analog && ClockPrefs.showSeconds.value;
            return TimeBuilder(
              smooth: smooth,
              builder: (context, now) => ClockFaceView(
                face: face,
                data: FaceData.of(context, now),
              ),
            );
          },
        ),
      ),
    );
  }
}
