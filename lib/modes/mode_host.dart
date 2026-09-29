import 'dart:async';

import 'package:flutter/material.dart';

import '../home.dart';
import '../ui/design/motion.dart';
import '../ui/design/page_transition.dart';
import 'alerts.dart';
import 'alarm/alarm_service.dart';
import 'app_mode.dart';
import 'fullscreen.dart';
import 'mode_pages.dart';
import 'mode_prefs.dart';
import 'mode_services.dart';
import 'ringing_page.dart';
import '../pomodoro_state.dart';
import 'timer/timer_controller.dart';

/// The app's root: shows whichever [AppMode] is current.
///
/// The Pomodoro screen is kept alive (just hidden) once it has been shown:
/// its countdown is driven by an animation controller, so tearing it down
/// on a mode switch would abandon a running session. The other modes keep
/// their state in global controllers and can be rebuilt freely.
class ModeHost extends StatefulWidget {
  const ModeHost({super.key});

  @override
  State<ModeHost> createState() => _ModeHostState();
}

class _ModeHostState extends State<ModeHost> {
  // A Pomodoro left running (or mid-rest) last time is built at once, so its
  // phase keeps time and is logged even if another mode opens first.
  bool _pomodoroShown = PomodoroStore.snapshot != null;
  bool _ringing = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    Fullscreen.wire();
    Alerts.current.addListener(_onAlert);
    // One heartbeat for everything that can go off, whichever mode is open.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      TimerController.instance.check();
      AlarmService.check();
      checkModeServices();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAlert());
  }

  @override
  void dispose() {
    _tick?.cancel();
    Alerts.current.removeListener(_onAlert);
    super.dispose();
  }

  /// Shows the front of the ring queue full screen; when it is answered the
  /// next one (if any) follows.
  void _onAlert() {
    final request = Alerts.current.value;
    if (request == null || _ringing || !mounted) return;
    _ringing = true;
    Navigator.of(context)
        .push(appPageRoute((_) => RingingPage(request: request)))
        .then((_) {
      _ringing = false;
      if (Alerts.current.value != null) _onAlert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppMode>(
      valueListenable: ModePrefs.current,
      builder: (context, mode, _) {
        final onPomodoro = mode == AppMode.pomodoro;
        if (onPomodoro) _pomodoroShown = true;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (_pomodoroShown)
              Offstage(
                offstage: !onPomodoro,
                // Hidden but ticking: the running countdown must keep time.
                child: ExcludeFocus(
                  excluding: !onPomodoro,
                  child: const Home(),
                ),
              ),
            AnimatedSwitcher(
              duration: Motion.medium,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: onPomodoro
                  ? const SizedBox.shrink(key: ValueKey('pomodoro'))
                  : KeyedSubtree(
                      key: ValueKey(mode),
                      child: modePage(mode),
                    ),
            ),
          ],
        );
      },
    );
  }
}
