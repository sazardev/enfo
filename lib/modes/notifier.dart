import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

import '../haptics/haptics.dart';

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

  static bool get _mobile => Platform.isAndroid || Platform.isIOS;

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
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: Haptics.enabled.value,
        vibrationPattern: Haptics.notificationPattern(timer: true),
      );

  static Future<void> _ensureReady() async {
    if (_ready || !_mobile) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('icon'),
        iOS: DarwinInitializationSettings(),
      ),
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
