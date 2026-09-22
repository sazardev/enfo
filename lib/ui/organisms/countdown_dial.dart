import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

import '../atoms/bouncy_tap.dart';
import '../design/motion.dart';
import '../molecules/countdown_ring.dart';

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
    required this.mode,
  });

  final int workSeconds;
  final int restSeconds;
  final bool notification;

  /// false = show mm:ss, true = show "Focus"/"Relax" text labels.
  final bool mode;

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

  void _completePhase() {
    _rest = !_rest;
    _totalSeconds = _rest ? widget.restSeconds : widget.workSeconds;

    if (widget.notification) {
      if (_rest) {
        _notify(title: 'Time to rest', body: 'Take a break.');
      } else {
        _notify(title: 'Time to work', body: "Let's continue with the work!");
      }
    }

    setState(() {
      _runState = _RunState.idle;
      _progress.stop();
      _progress.value = 0.0;
    });

    if (!MediaQuery.disableAnimationsOf(context)) {
      _completePulseController.forward(from: 0);
    }
  }

  void _handleTap() {
    switch (_runState) {
      case _RunState.idle:
        setState(() {
          _runState = _RunState.running;
          _progress.duration = Duration(seconds: _totalSeconds);
          _progress.forward(from: 0.0);
        });
      case _RunState.running:
        setState(() {
          _runState = _RunState.paused;
          _progress.stop();
        });
      case _RunState.paused:
        final remainingSeconds = _totalSeconds * (1 - _progress.value);
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
    setState(() {
      _runState = _RunState.idle;
      _progress.stop();
      _progress.value = 0.0;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      _completePulseController.forward(from: 0);
    }
  }

  String _label() {
    if (_runState == _RunState.paused) return 'Paused';
    if (widget.mode) return _rest ? 'Relax' : 'Focus';

    final remaining =
        (_totalSeconds * (1 - _progress.value)).round().clamp(0, _totalSeconds);
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _progress.dispose();
    _completePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // CountdownRing paints its label via a raw TextPainter (CustomPainter),
    // which doesn't participate in the widget tree's DefaultTextStyle
    // inheritance — a bare TextStyle() here would silently fall back to the
    // platform system font instead of the app's Geist Mono. Base it on a
    // real themed TextStyle so fontFamily carries through.
    final baseLabelStyle =
        Theme.of(context).textTheme.headlineMedium ?? const TextStyle();

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialSize = constraints.biggest.shortestSide / 1.2;
        return Center(
          child: BouncyTap(
            onTap: _handleTap,
            onLongPress: _handleReset,
            pressedScale: 0.96,
            child: AnimatedBuilder(
              animation: Listenable.merge([_progress, _pulseScale]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: CountdownRing(
                      progress: _progress.value,
                      label: _label(),
                      labelStyle: baseLabelStyle.copyWith(
                        fontSize: dialSize / 6,
                        fontWeight: FontWeight.w700,
                        color: _runState == _RunState.paused
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                      ringColor: colorScheme.primary,
                      trackColor: colorScheme.primary.withValues(alpha: 0.14),
                      surfaceColor: colorScheme.surfaceContainerHigh,
                    ),
                  ),
                );
              },
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
