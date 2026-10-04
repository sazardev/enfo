import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_preferences.dart';
import '../../haptics/haptics.dart';
import '../../history.dart';
import '../../l10n/locale_controller.dart';
import '../../modes/notifier.dart';
import '../../pomodoro_state.dart';
import '../../widgets/pomodoro_live.dart';
import '../atoms/bouncy_tap.dart';
import '../design/motion.dart';
import '../design/radii.dart';
import '../clock/clock_frame.dart';
import '../clock/clock_style.dart';
import '../clock/clock_view.dart';

enum _RunState { idle, running, paused }

/// Lets a control bar outside the dial start/pause/reset it and follow its
/// state. Its value is the dial's current [ClockPhase].
class CountdownController extends ValueNotifier<ClockPhase> {
  CountdownController() : super(ClockPhase.idle);

  VoidCallback? _toggle;
  VoidCallback? _reset;
  Object? _owner;

  /// Start, pause or resume, like tapping the dial.
  void toggle() => _toggle?.call();

  /// Back to the start of the phase, like long-pressing the dial.
  void reset() => _reset?.call();

  void _attach(Object owner, VoidCallback toggle, VoidCallback reset) {
    _owner = owner;
    _toggle = toggle;
    _reset = reset;
  }

  /// Only the dial that is currently attached may detach: a replaced dial is
  /// disposed after its successor's initState, and must not unhook it.
  void _detach(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _toggle = null;
    _reset = null;
  }

  void _report(ClockPhase phase) {
    if (value != phase) value = phase;
  }
}

/// The app's centerpiece: a self-contained work/rest countdown timer.
/// Tap to start/pause/resume, long-press to reset. Replaces the old
/// `circular_countdown_timer`-based `Clock` widget with a fully custom,
/// flat, bouncy dial.
class CountdownDial extends StatefulWidget {
  const CountdownDial({
    super.key,
    required this.workSeconds,
    required this.restSeconds,
    required this.notification,
    this.mode = false,
    this.style = ClockStyle.ring,
    this.controller,
  });

  final int workSeconds;
  final int restSeconds;
  final bool notification;

  /// false = show mm:ss, true = show "Focus"/"Relax" text labels.
  final bool mode;

  /// Visual used to draw the countdown.
  final ClockStyle style;

  /// Optional handle for an external play/pause button.
  final CountdownController? controller;

  @override
  State<CountdownDial> createState() => _CountdownDialState();
}

class _CountdownDialState extends State<CountdownDial>
    with TickerProviderStateMixin {
  /// Clear of the timer (9001), intervals (9100), kitchen (9200) and alarms.
  static const _notificationId = 9002;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late int _totalSeconds = widget.workSeconds;
  bool _rest = false;
  _RunState _runState = _RunState.idle;

  // Bookkeeping for the session-history record of the current phase. Null
  // _sessionStart means no phase has been started since the last reset.
  DateTime? _sessionStart;
  DateTime? _pauseStart;
  int _pauseCount = 0;
  Duration _pausedTotal = Duration.zero;

  /// Single source of truth for "elapsed fraction" of the current phase.
  /// stop() freezes .value exactly where it is (pause); animateTo(1.0,
  /// duration: remaining) resumes with frame-accurate, drift-free timing.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: Duration(seconds: _totalSeconds),
  )..addStatusListener(_handleProgressStatus);

  /// One-shot "pop" pulse played on phase-complete and on manual reset.
  late final AnimationController _completePulseController = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );

  late final Animation<double> _pulseScale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.12, end: 1.0)
          .chain(CurveTween(curve: Motion.bouncy)),
      weight: 65,
    ),
  ]).animate(_completePulseController);

  /// Whether the OS has a notification scheduled for the end of this phase
  /// (so it is cancelled when the phase is paused, reset or extended).
  bool _scheduled = false;

  /// Refreshes the ongoing card's progress bar while the phase runs.
  Timer? _cardTicker;

  @override
  void initState() {
    super.initState();
    _restore();
    widget.controller?._attach(this, _handleTap, _handleReset);
    PomodoroLive.toggleRequests.addListener(_onToggleRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publish();
      // Re-saves what was restored (a phase that ended while closed is now
      // the next one) and re-arms the end-of-phase notification.
      _persist();
      // A widget tap may have launched the app before this dial existed.
      _onToggleRequest();
    });
  }

  /// A home-screen widget asked to start/pause the timer.
  void _onToggleRequest() {
    if (!mounted || !PomodoroLive.pendingToggle) return;
    PomodoroLive.pendingToggle = false;
    _handleTap();
  }

  /// Mirrors the dial for the home-screen widgets.
  void _publish() {
    PomodoroLive.publish(PomodoroState(
      phase: switch (_runState) {
        _RunState.idle => ClockPhase.idle,
        _RunState.running => ClockPhase.running,
        _RunState.paused => ClockPhase.paused,
      },
      rest: _rest,
      totalSeconds: _totalSeconds,
      remainingMs: (_totalSeconds * 1000 * (1 - _progress.value)).round(),
      publishedAtMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Picks up where the last run left off: same phase, same pauses, and the
  /// time that passed while the app was closed counted in.
  void _restore() {
    final saved = PomodoroStore.snapshot;
    if (saved == null) return;
    final now = DateTime.now();

    _rest = saved.rest;
    if (saved.run == PomodoroRun.idle) {
      _totalSeconds = _rest ? widget.restSeconds : widget.workSeconds;
      _progress.duration = Duration(seconds: _totalSeconds);
      return;
    }

    _totalSeconds = saved.totalSeconds;
    _progress.duration = Duration(seconds: _totalSeconds);
    _sessionStart = saved.sessionStart;
    _pauseStart = saved.pauseStart;
    _pauseCount = saved.pauseCount;
    _pausedTotal = Duration(milliseconds: saved.pausedMs);

    if (saved.run == PomodoroRun.paused) {
      _runState = _RunState.paused;
      _progress.value = 1 - saved.remainingMs / (_totalSeconds * 1000);
      return;
    }

    final left = saved.endsAt!.difference(now);
    if (left > Duration.zero) {
      _resumeRunning(left);
      return;
    }

    // The phase ran out while the app was closed. The OS already told the
    // user (the notification was scheduled); here it is only logged, at the
    // moment it really ended.
    _finishSession(completed: true, at: saved.endsAt);
    _rest = !_rest;
    _totalSeconds = _rest ? widget.restSeconds : widget.workSeconds;
    _progress.duration = Duration(seconds: _totalSeconds);
    if (AppPreferences.autoStartNext.value) {
      // The next phase would have started right then. Carry on with it only
      // if it is still in progress: several phases the user never saw are
      // not counted as focus that may not have happened.
      final nextLeft =
          saved.endsAt!.add(Duration(seconds: _totalSeconds)).difference(now);
      if (nextLeft > Duration.zero) {
        _beginSession(at: saved.endsAt);
        _resumeRunning(nextLeft);
      }
    }
  }

  /// Running with [left] to go (the bar jumps to where it should be).
  void _resumeRunning(Duration left) {
    _runState = _RunState.running;
    _progress.value = 1 - left.inMilliseconds / (_totalSeconds * 1000);
    _progress.animateTo(1.0, duration: left, curve: Curves.linear);
  }

  int get _remainingMs =>
      (_totalSeconds * 1000 * (1 - _progress.value)).round();

  /// Saves where the dial is, and keeps the OS notification for the end of
  /// the phase in step. Call after every state change.
  void _persist() {
    final remaining = _remainingMs;
    PomodoroStore.save(switch (_runState) {
      _RunState.idle => _rest
          ? PomodoroSnapshot(
              run: PomodoroRun.idle,
              rest: true,
              totalSeconds: _totalSeconds,
            )
          : null,
      _RunState.running => PomodoroSnapshot(
          run: PomodoroRun.running,
          rest: _rest,
          totalSeconds: _totalSeconds,
          endsAt: DateTime.now().add(Duration(milliseconds: remaining)),
          sessionStart: _sessionStart,
          pauseCount: _pauseCount,
          pausedMs: _pausedTotal.inMilliseconds,
        ),
      _RunState.paused => PomodoroSnapshot(
          run: PomodoroRun.paused,
          rest: _rest,
          totalSeconds: _totalSeconds,
          remainingMs: remaining,
          sessionStart: _sessionStart,
          pauseStart: _pauseStart,
          pauseCount: _pauseCount,
          pausedMs: _pausedTotal.inMilliseconds,
        ),
    });

    if (_runState == _RunState.running && widget.notification) {
      _scheduled = true;
      final l10n = context.l10n;
      Notifier.schedule(
        id: _notificationId,
        at: DateTime.now().add(Duration(milliseconds: remaining)),
        title: _rest ? l10n.notifWorkTitle : l10n.notifRestTitle,
        body: _rest ? l10n.notifWorkBody : l10n.notifRestBody,
      );
    } else if (_scheduled) {
      _scheduled = false;
      Notifier.cancel(_notificationId);
    }

    // Ongoing card so the shade shows the phase and its countdown.
    if (_runState == _RunState.running) {
      if (Notifier.available) {
        _cardTicker ??= Timer.periodic(
          const Duration(seconds: 10),
          (_) => _refreshCard(),
        );
      }
      Notifier.showRunningTimer(
        id: Notifier.pomodoroRunningId,
        remainingMs: remaining,
        paused: false,
        endsAt: DateTime.now().add(Duration(milliseconds: remaining)),
        totalMs: _totalSeconds * 1000,
      );
    } else {
      _cardTicker?.cancel();
      _cardTicker = null;
      if (_runState == _RunState.paused) {
        Notifier.showRunningTimer(
          id: Notifier.pomodoroRunningId,
          remainingMs: remaining,
          paused: true,
          totalMs: _totalSeconds * 1000,
        );
      } else {
        Notifier.hideRunningTimer(Notifier.pomodoroRunningId);
      }
    }
  }

  /// Moves the card's progress bar without touching the saved state.
  void _refreshCard() {
    if (_runState != _RunState.running) return;
    final remaining = _remainingMs;
    Notifier.showRunningTimer(
      id: Notifier.pomodoroRunningId,
      remainingMs: remaining,
      paused: false,
      endsAt: DateTime.now().add(Duration(milliseconds: remaining)),
      totalMs: _totalSeconds * 1000,
    );
  }

  @override
  void didUpdateWidget(covariant CountdownDial oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this, _handleTap, _handleReset);
    }

    final durationChanged = oldWidget.workSeconds != widget.workSeconds ||
        oldWidget.restSeconds != widget.restSeconds;
    final notRunning = _runState != _RunState.running;

    // A new preset was picked elsewhere while the dial is idle/paused on the
    // work phase: reflect it immediately without auto-starting. A change
    // made mid-rest is intentionally left for the next work cycle.
    if (durationChanged && notRunning && !_rest) {
      _finishSession(completed: false);
      setState(() {
        _totalSeconds = widget.workSeconds;
        _runState = _RunState.idle;
        _progress.stop();
        _progress.value = 0.0;
      });
      _publish();
      _persist();
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _completePhase();
  }

  void _beginSession({DateTime? at}) {
    _sessionStart = at ?? DateTime.now();
    _pauseStart = null;
    _pauseCount = 0;
    _pausedTotal = Duration.zero;
  }

  /// Persists the phase in progress (if any) to the history. Must run
  /// before the progress/phase state is reset or toggled, since it reads
  /// them to work out how long the timer actually ran.
  void _finishSession({required bool completed, DateTime? at}) {
    final start = _sessionStart;
    if (start == null) return;
    _sessionStart = null;

    final end = at ?? DateTime.now();
    final pauseStart = _pauseStart;
    if (pauseStart != null) _pausedTotal += end.difference(pauseStart);
    _pauseStart = null;

    final focused =
        completed ? _totalSeconds : (_progress.value * _totalSeconds).round();
    // A stray tap-and-reset isn't worth a history entry.
    if (!completed && focused < 5) return;

    SessionHistory.add(PomodoroSession(
      isWork: !_rest,
      startedAt: start,
      endedAt: end,
      plannedSeconds: _totalSeconds,
      focusedSeconds: focused,
      pauseCount: _pauseCount,
      pausedSeconds: _pausedTotal.inSeconds,
      completed: completed,
    ));
  }

  void _completePhase() {
    _finishSession(completed: true);
    _rest = !_rest;
    _totalSeconds = _rest ? widget.restSeconds : widget.workSeconds;

    if (widget.notification) {
      if (_rest) {
        _notify(
          title: context.l10n.notifRestTitle,
          body: context.l10n.notifRestBody,
        );
      } else {
        _notify(
          title: context.l10n.notifWorkTitle,
          body: context.l10n.notifWorkBody,
        );
      }
    }

    setState(() {
      _runState = _RunState.idle;
      _progress.stop();
      _progress.value = 0.0;
    });

    // The scheduled notification just fired (or was replaced by the one
    // above): nothing left to cancel.
    _scheduled = false;
    _publish();
    _persist();

    // After the toggle above, _rest means focus just ended.
    Haptics.phaseComplete(toRest: _rest);

    if (!MediaQuery.disableAnimationsOf(context)) {
      _completePulseController.forward(from: 0);
    }

    if (AppPreferences.autoStartNext.value) _startPhase();
  }

  void _startPhase() {
    _beginSession();
    setState(() {
      _runState = _RunState.running;
      _progress.duration = Duration(seconds: _totalSeconds);
      _progress.forward(from: 0.0);
    });
    _publish();
    _persist();
  }

  void _handleTap() {
    switch (_runState) {
      case _RunState.idle:
        // Same language as the timer and stopwatch: starting is firm,
        // pausing/resuming is a touch, resetting warns.
        Haptics.confirm();
        _startPhase();
      case _RunState.running:
        Haptics.tap();
        _pauseStart = DateTime.now();
        _pauseCount++;
        setState(() {
          _runState = _RunState.paused;
          _progress.stop();
        });
        _publish();
        _persist();
      case _RunState.paused:
        Haptics.tap();
        final remainingSeconds = _totalSeconds * (1 - _progress.value);
        final pauseStart = _pauseStart;
        if (pauseStart != null) {
          _pausedTotal += DateTime.now().difference(pauseStart);
          _pauseStart = null;
        }
        setState(() {
          _runState = _RunState.running;
          _progress.animateTo(
            1.0,
            duration: Duration(milliseconds: (remainingSeconds * 1000).round()),
            curve: Curves.linear,
          );
        });
        _publish();
        _persist();
    }
  }

  void _handleReset() {
    Haptics.warning();
    _finishSession(completed: false);
    setState(() {
      _runState = _RunState.idle;
      _progress.stop();
      _progress.value = 0.0;
    });
    _publish();
    _persist();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _completePulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    PomodoroLive.toggleRequests.removeListener(_onToggleRequest);
    widget.controller?._detach(this);
    // The phase in progress is not abandoned: it is saved and resumes the
    // next time the dial is built, so no history record is written here.
    _progress.dispose();
    _completePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = switch (_runState) {
      _RunState.idle => ClockPhase.idle,
      _RunState.running => ClockPhase.running,
      _RunState.paused => ClockPhase.paused,
    };
    // Tell the external button (after this frame: it may be mid-build).
    final controller = widget.controller;
    if (controller != null && controller.value != phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller._report(phase);
      });
    }

    // The tap target (and its keyboard focus halo) is fitted to the face's
    // own aspect ratio, not the whole free area, so on wide screens the halo
    // hugs the dial instead of showing as a big rectangle behind it.
    final aspect = widget.style.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final double w;
        final double h;
        if (maxW / maxH > aspect) {
          h = maxH;
          w = h * aspect;
        } else {
          w = maxW;
          h = w / aspect;
        }
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: BouncyTap(
              onTap: _handleTap,
              onLongPress: _handleReset,
              // The reset carries its own (warning) haptic.
              longPressFeedback: false,
              pressedScale: 0.96,
              // Large radius clamps to a circle on the (square) round dials.
              focusBorderRadius: aspect == 1.0
                  ? const BorderRadius.all(Radius.circular(9999))
                  : AppRadii.mdRadius,
              child: AnimatedBuilder(
                animation: _pulseScale,
                builder: (context, child) =>
                    Transform.scale(scale: _pulseScale.value, child: child),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: LiveClockView(
                    style: widget.style,
                    progress: _progress,
                    totalSeconds: _totalSeconds,
                    isRest: _rest,
                    phase: phase,
                    wordMode: widget.mode,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _notify({required String title, required String body}) {
    if (Platform.isWindows || Platform.isLinux) {
      _notifyDesktop(title: title, body: body);
    } else if (Platform.isAndroid) {
      _notifyMobile(title: title, body: body);
    }
  }

  Future<void> _notifyMobile({String title = '', String body = ''}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_enfo');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '0',
      'enfo',
      icon: 'ic_stat_enfo',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _notifyDesktop({String title = '', String body = ''}) async {
    await localNotifier.setup(
      appName: 'enfo',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

    final notification = LocalNotification(
      title: title,
      body: body,
      silent: true,
    );

    notification.show();
    await WindowManager.instance.show();
  }
}
