import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

import '../haptics/haptics.dart';
import '../l10n/locale_controller.dart';
import 'format.dart';

/// Notifications for timers and alarms.
///
/// * [show]: right now (desktop: a toast and the window comes forward).
/// * [schedule] / [cancel]: Android/iOS only. The OS fires the notification
///   at the exact time even if Enfo is closed, which is what makes an alarm
///   an alarm. On desktop the app must be running (see AlarmService).
///
/// Every call is best-effort: a missing plugin (tests, unsupported
/// platform) or a denied permission must never break the app.
class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Ongoing notification that shows the countdown of a running timer.
  static const int timerRunningId = 9000;

  /// Same, for the main Pomodoro dial (can run next to the timer mode).
  static const int pomodoroRunningId = 9004;

  /// Ongoing notification for the song that is playing.
  static const int musicId = 9003;

  /// Called when the user taps an action button on a notification (music
  /// play/pause). The app wires this to the audio service.
  static void Function(String actionId)? onAction;

  static bool get _mobile => Platform.isAndroid || Platform.isIOS;

  /// True where the ongoing cards are actually posted (mobile only), so
  /// callers can skip their refresh tickers elsewhere (desktop, tests).
  static bool get available => _mobile;

  // Android fixes a channel's vibration when it is created, so the pattern
  // and strength are part of the channel id: changing either makes a new
  // channel instead of silently keeping the old feel.
  static AndroidNotificationDetails _alarmDetails() =>
      AndroidNotificationDetails(
        'enfo_alarms_${Haptics.alarmPattern.value.name}_'
            '${Haptics.strength.value.name}',
        'Alarms',
        channelDescription: 'Alarm clock',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_stat_enfo',
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        enableVibration: Haptics.enabled.value,
        vibrationPattern: Haptics.notificationPattern(),
      );

  static AndroidNotificationDetails _timerDetails() =>
      AndroidNotificationDetails(
        'enfo_timers_${Haptics.strength.value.name}',
        'Timers',
        channelDescription: 'Timer finished',
        icon: 'ic_stat_enfo',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: Haptics.enabled.value,
        vibrationPattern: Haptics.notificationPattern(timer: true),
      );

  /// Quiet, ongoing card: the countdown ticks on its own (chronometer), so no
  /// per-second updates are needed.
  static AndroidNotificationDetails _runningTimerDetails({
    required bool paused,
    required int? whenMs,
    Duration? timeout,
    int progress = 0,
    int maxProgress = 0,
  }) =>
      AndroidNotificationDetails(
        'enfo_timer_running',
        'Timer running',
        channelDescription: 'Shows the time left while a timer runs',
        icon: 'ic_stat_enfo',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: true,
        autoCancel: false,
        silent: true,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        category: AndroidNotificationCategory.stopwatch,
        visibility: NotificationVisibility.public,
        showWhen: !paused,
        when: whenMs,
        timeoutAfter: timeout?.inMilliseconds,
        showProgress: maxProgress > 0,
        maxProgress: maxProgress,
        progress: progress,
        usesChronometer: !paused,
        chronometerCountDown: !paused,
      );

  static AndroidNotificationDetails _musicDetails({
    required bool playing,
    int progressMs = 0,
    int totalMs = 0,
  }) {
    final l10n = currentL10n();
    return AndroidNotificationDetails(
      'enfo_music',
      'Music',
      channelDescription: 'Shows the song that is playing',
      icon: 'ic_stat_enfo',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: playing,
      autoCancel: false,
      silent: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.transport,
      visibility: NotificationVisibility.public,
      showProgress: totalMs > 0,
      maxProgress: totalMs,
      progress: progressMs.clamp(0, totalMs == 0 ? 0 : totalMs),
      actions: [
        AndroidNotificationAction(
          playing ? 'music_pause' : 'music_play',
          playing ? l10n.musicActionPause : l10n.musicActionPlay,
          showsUserInterface: true,
        ),
      ],
    );
  }

  static Future<void> _ensureReady() async {
    if (_ready || !_mobile) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_enfo'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final action = response.actionId;
        if (action != null) onAction?.call(action);
      },
    );
    _ready = true;
  }

  /// Whether this platform has runtime notification permissions to ask for.
  static bool get canAskPermissions => Platform.isAndroid;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Current grant state; `true` where there is nothing to grant.
  static Future<bool> notificationsAllowed() async {
    if (!canAskPermissions) return true;
    try {
      await _ensureReady();
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (e) {
      debugPrint('Notifier.notificationsAllowed: $e');
      return false;
    }
  }

  static Future<bool> exactAlarmsAllowed() async {
    if (!canAskPermissions) return true;
    try {
      await _ensureReady();
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (e) {
      debugPrint('Notifier.exactAlarmsAllowed: $e');
      return false;
    }
  }

  static Future<bool> requestNotifications() async {
    if (!canAskPermissions) return true;
    try {
      await _ensureReady();
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notifier.requestNotifications: $e');
    }
    return notificationsAllowed();
  }

  static Future<bool> requestExactAlarms() async {
    if (!canAskPermissions) return true;
    try {
      await _ensureReady();
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Notifier.requestExactAlarms: $e');
    }
    return exactAlarmsAllowed();
  }

  /// Asks for notification + exact-alarm permission (Android 13+/12+).
  static Future<void> requestPermissions() async {
    if (!_mobile) return;
    try {
      await _ensureReady();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Notifier.requestPermissions: $e');
    }
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    bool alarm = false,
  }) async {
    try {
      if (Platform.isWindows || Platform.isLinux) {
        await localNotifier.setup(
          appName: 'enfo',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
        await LocalNotification(title: title, body: body, silent: true).show();
        await WindowManager.instance.show();
      } else if (_mobile) {
        await _ensureReady();
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: alarm ? _alarmDetails() : _timerDetails(),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
        );
      }
    } catch (e) {
      debugPrint('Notifier.show: $e');
    }
  }

  /// Ongoing card while a timer runs (or waits paused). [endsAt] drives the
  /// live countdown; when paused the remaining time is shown as plain text.
  static Future<void> showRunningTimer({
    required int id,
    required int remainingMs,
    required bool paused,
    DateTime? endsAt,
    int totalMs = 0,
  }) async {
    if (!_mobile) return;
    try {
      await _ensureReady();
      final l10n = currentL10n();
      final String title =
          paused ? l10n.timerPausedTitle : l10n.timerRunningTitle;
      final String body = paused
          ? l10n.timerPausedBody(
              formatCountdown((remainingMs / 1000).ceil().clamp(0, 1 << 31)))
          : l10n.timerRunningBody(
              DateFormat.jm(l10n.localeName).format((endsAt ?? DateTime.now()).toLocal()),
            );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: _runningTimerDetails(
            paused: paused,
            whenMs: paused ? null : (endsAt ?? DateTime.now()).millisecondsSinceEpoch,
            timeout: paused
                ? null
                : Duration(milliseconds: remainingMs + 3000),
            progress: totalMs > 0 ? (totalMs - remainingMs).clamp(0, totalMs) : 0,
            maxProgress: totalMs,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: false,
            presentBanner: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Notifier.showRunningTimer: $e');
    }
  }

  static Future<void> hideRunningTimer(int id) => cancel(id);

  /// Ongoing card for the current song, with a play/pause action.
  static Future<void> showMusic({
    required String title,
    required String artist,
    required bool playing,
    int progressMs = 0,
    int totalMs = 0,
  }) async {
    if (!_mobile) return;
    try {
      await _ensureReady();
      await _plugin.show(
        id: musicId,
        title: title,
        body: artist,
        notificationDetails: NotificationDetails(
          android: _musicDetails(
            playing: playing,
            progressMs: progressMs,
            totalMs: totalMs,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: false,
            presentBanner: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Notifier.showMusic: $e');
    }
  }

  static Future<void> hideMusic() => cancel(musicId);

  static Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    bool alarm = false,
  }) async {
    if (!_mobile || !at.isAfter(DateTime.now())) return;
    try {
      await _ensureReady();
      await _plugin.zonedSchedule(
        id: id,
        // An absolute instant: no local time-zone database needed.
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: alarm ? _alarmDetails() : _timerDetails(),
          iOS: const DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: alarm
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Notifier.schedule: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_mobile) return;
    try {
      await _ensureReady();
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Notifier.cancel: $e');
    }
  }
}
