import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

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

  static const _alarmDetails = AndroidNotificationDetails(
    'enfo_alarms',
    'Alarms',
    channelDescription: 'Alarm clock',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    playSound: true,
    enableVibration: true,
  );

  static const _timerDetails = AndroidNotificationDetails(
    'enfo_timers',
    'Timers',
    channelDescription: 'Timer finished',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
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
            android: alarm ? _alarmDetails : _timerDetails,
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
          android: alarm ? _alarmDetails : _timerDetails,
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
