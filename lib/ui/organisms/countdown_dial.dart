import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_preferences.dart';
import '../../history.dart';
import '../../l10n/locale_controller.dart';
import '../atoms/bouncy_tap.dart';
import '../design/motion.dart';
import '../clock/clock_frame.dart';
import '../clock/clock_style.dart';
import '../clock/clock_view.dart';

enum _RunState { idle, running, paused }

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
  });

  final int workSeconds;
  final int restSeconds;
  final bool notification;

  /// false = show mm:ss, true = show "Focus"/"Relax" text labels.
  final bool mode;

  /// Visual used to draw the countdown.
  final ClockStyle style;

  @override
  State<CountdownDial> createState() => _CountdownDialState();
}

class _CountdownDialState extends State<CountdownDial>
    with TickerProviderStateMixin {
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

  @override
  void didUpdateWidget(covariant CountdownDial oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _completePhase();
  }

  void _beginSession() {
    _sessionStart = DateTime.now();
    _pauseStart = null;
    _pauseCount = 0;
    _pausedTotal = Duration.zero;
  }

  /// Persists the phase in progress (if any) to the history. Must run
  /// before the progress/phase state is reset or toggled, since it reads
  /// them to work out how long the timer actually ran.
  void _finishSession({required bool completed}) {
    final start = _sessionStart;
    if (start == null) return;
    _sessionStart = null;

    final end = DateTime.now();
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

    if (AppPreferences.haptics.value) HapticFeedback.heavyImpact();

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
  }

  void _handleTap() {
    switch (_runState) {
      case _RunState.idle:
        _startPhase();
      case _RunState.running:
        _pauseStart = DateTime.now();
        _pauseCount++;
        setState(() {
          _runState = _RunState.paused;
          _progress.stop();
        });
      case _RunState.paused:
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
    }
  }

  void _handleReset() {
    _finishSession(completed: false);
    setState(() {
      _runState = _RunState.idle;
      _progress.stop();
      _progress.value = 0.0;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _completePulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _finishSession(completed: false);
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

    return Center(
      child: BouncyTap(
        onTap: _handleTap,
        onLongPress: _handleReset,
        pressedScale: 0.96,
        child: AnimatedBuilder(
          animation: _pulseScale,
          builder: (context, child) =>
              Transform.scale(scale: _pulseScale.value, child: child),
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
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
        AndroidInitializationSettings('icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '0',
      'enfo',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      id: 0,
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
