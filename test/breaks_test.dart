import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/breaks/breaks_mode_page.dart';
import 'package:enfo/modes/breaks/breaks_model.dart';
import 'package:enfo/modes/breaks/breaks_service.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _screens = <String, Size>{
  'watch': Size(200, 200),
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

void main() {
  final svc = BreaksService.instance;
  var now = DateTime(2026, 9, 29, 10, 0);

  setUpAll(loadAppFonts);
  setUp(() async {
    await resetTestState({'onboarded': true});
    await svc.wipe();
    now = DateTime(2026, 9, 29, 10, 0);
    nowProvider = () => now;
  });

  group('ActiveHours', () {
    test('clamp keeps times inside, moves others to the next opening', () {
      const h = ActiveHours(start: 9 * 60, end: 18 * 60);
      expect(h.clamp(DateTime(2026, 1, 1, 12)), DateTime(2026, 1, 1, 12));
      expect(h.clamp(DateTime(2026, 1, 1, 7)), DateTime(2026, 1, 1, 9));
      expect(h.clamp(DateTime(2026, 1, 1, 18)), DateTime(2026, 1, 2, 9));
      expect(h.clamp(DateTime(2026, 1, 1, 23, 59)), DateTime(2026, 1, 2, 9));
    });

    test('overnight windows and all-day', () {
      const night = ActiveHours(start: 22 * 60, end: 6 * 60);
      expect(night.contains(DateTime(2026, 1, 1, 23)), isTrue);
      expect(night.contains(DateTime(2026, 1, 1, 5)), isTrue);
      expect(night.contains(DateTime(2026, 1, 1, 12)), isFalse);
      expect(night.clamp(DateTime(2026, 1, 1, 12)), DateTime(2026, 1, 1, 22));
      const off = ActiveHours(enabled: false);
      expect(off.clamp(DateTime(2026, 1, 1, 3)), DateTime(2026, 1, 1, 3));
    });
  });

  group('BreaksService', () {
    test('starting schedules only enabled reminders', () async {
      await svc.setEnabled('water', true);
      await svc.start();
      expect(svc.reminder('eye')!.nextDueMs,
          now.add(const Duration(minutes: 20)).millisecondsSinceEpoch);
      expect(svc.reminder('water')!.nextDueMs,
          now.add(const Duration(minutes: 75)).millisecondsSinceEpoch);
      expect(svc.reminder('stretch')!.nextDueMs, isNull);
      expect(svc.upcoming!.id, 'eye');
    });

    test('a due time outside active hours waits for the window', () async {
      now = DateTime(2026, 9, 29, 17, 50);
      await svc.start();
      expect(
          DateTime.fromMillisecondsSinceEpoch(svc.reminder('eye')!.nextDueMs!),
          DateTime(2026, 9, 30, 9));
    });

    test('nothing rings before it is due, then a gentle prompt shows',
        () async {
      await svc.start();
      now = now.add(const Duration(minutes: 19, seconds: 59));
      svc.check();
      expect(Alerts.current.value, isNull);
      now = now.add(const Duration(seconds: 1));
      svc.check();
      final req = Alerts.current.value!;
      expect(req.gentle, isTrue);
      expect(req.giveUpAfter, const Duration(seconds: 20));
      // While waiting for an answer it does not ring twice.
      svc.check();
      expect(svc.reminder('eye')!.nextDueMs, isNull);
    });

    test('done counts a break and restarts the interval', () async {
      await svc.start();
      now = now.add(const Duration(minutes: 20));
      svc.check();
      Alerts.current.value!.onDismiss();
      expect(svc.today.taken, 1);
      expect(svc.reminder('eye')!.nextDueMs,
          now.add(const Duration(minutes: 20)).millisecondsSinceEpoch);
    });

    test('skip counts as skipped, snooze counts as neither', () async {
      await svc.setEnabled('stretch', true);
      await svc.start();
      now = now.add(const Duration(minutes: 50));
      svc.check(); // eye and stretch are both due
      Alerts.reset();
      svc.reminder('eye');
      // Ring stretch alone again.
      await svc.stop();
      await svc.start();
      now = now.add(const Duration(minutes: 20));
      svc.check();
      final eye = Alerts.current.value!;
      eye.onSnooze!();
      expect(svc.today.taken + svc.today.skipped, 0);
      expect(svc.reminder('eye')!.nextDueMs,
          now.add(const Duration(minutes: 5)).millisecondsSinceEpoch);
      Alerts.reset();
      now = now.add(const Duration(minutes: 5));
      svc.check();
      Alerts.current.value!.onExtra!();
      expect(svc.today.skipped, 1);
    });

    test('a long break nobody answers counts as skipped', () async {
      await svc.setEnabled('stretch', true);
      await svc.start();
      now = now.add(const Duration(minutes: 50));
      svc.check();
      // The eye break was due 30 min ago (too late): it rolled silently.
      final req = Alerts.current.value!;
      expect(req.gentle, isFalse);
      req.onExpire!();
      expect(svc.today.skipped, 1);
      expect(svc.today.taken, 0);
    });

    test('the short eye break dismissing itself counts as taken', () async {
      await svc.start();
      now = now.add(const Duration(minutes: 20));
      svc.check();
      Alerts.current.value!.onExpire!();
      expect(svc.today.taken, 1);
    });

    test('long overdue reminders roll forward without ringing', () async {
      await svc.start();
      now = now.add(const Duration(hours: 3));
      svc.check();
      expect(Alerts.current.value, isNull);
      expect(
          DateTime.fromMillisecondsSinceEpoch(svc.reminder('eye')!.nextDueMs!)
              .isAfter(now),
          isTrue);
    });

    test('stop clears the schedule; toggling off a reminder too', () async {
      await svc.start();
      await svc.setEnabled('eye', false);
      expect(svc.reminder('eye')!.nextDueMs, isNull);
      await svc.setEnabled('eye', true);
      expect(svc.reminder('eye')!.nextDueMs, isNotNull);
      await svc.stop();
      expect(svc.reminder('eye')!.nextDueMs, isNull);
      now = now.add(const Duration(hours: 1));
      svc.check();
      expect(Alerts.current.value, isNull);
    });

    test('counters are per day', () async {
      await svc.start();
      now = now.add(const Duration(minutes: 20));
      svc.check();
      Alerts.current.value!.onDismiss();
      expect(svc.today.taken, 1);
      now = now.add(const Duration(days: 1));
      expect(svc.today.taken, 0);
    });

    test('state survives a restart', () async {
      await svc.setEnabled('posture', true);
      final custom = await svc.addCustom(
          name: 'Walk', intervalMin: 40, durationSec: 60, iconIndex: 5);
      await svc.start();
      await svc.setHours(const ActiveHours(start: 8 * 60, end: 20 * 60));
      await svc.load();
      expect(svc.running, isTrue);
      expect(svc.hours.end, 20 * 60);
      expect(svc.reminder('posture')!.enabled, isTrue);
      expect(svc.reminder(custom!.id)!.name, 'Walk');
      expect(svc.reminder(custom.id)!.intervalMin, 40);
    });

    test('notification window rolls forward inside active hours', () async {
      now = DateTime(2026, 9, 29, 17, 0);
      await svc.start();
      final times = svc.upcomingTimes(svc.reminder('eye')!, now);
      expect(times.first, DateTime(2026, 9, 29, 17, 20));
      expect(times[1], DateTime(2026, 9, 29, 17, 40));
      // 18:00 is outside the window: the next one opens at 09:00.
      expect(times.contains(DateTime(2026, 9, 29, 18, 0)), isFalse);
      // ...and that is beyond the 12 h horizon, so only two are queued.
      expect(times.length, 2);
      // From the morning the whole window fits the per-reminder cap.
      now = DateTime(2026, 9, 29, 9, 0);
      await svc.restart();
      expect(svc.upcomingTimes(svc.reminder('eye')!, now).length,
          BreaksService.notificationsPerReminder);
    });

    test('custom reminders can be added and removed', () async {
      final c = await svc.addCustom(name: 'Meds');
      expect(svc.reminders.length, 5);
      await svc.removeCustom(c!.id);
      expect(svc.reminders.length, 4);
      await svc.removeCustom('eye'); // built-ins stay
      expect(svc.reminders.length, 4);
    });
  });

  for (final size in _screens.entries) {
    testWidgets('breaks page fits on ${size.key}', (tester) async {
      setScreen(tester, size.value);
      await svc.addCustom(name: 'A custom reminder with a long name');
      await svc.start();
      await ModePrefs.setEnabled(AppMode.breaks, true);
      await ModePrefs.setCurrent(AppMode.breaks);
      await tester.pumpWidget(testApp(const ModeHost()));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(BreaksModePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the break prompt shows Done, Snooze and Skip', (tester) async {
    setScreen(tester, const Size(390, 844));
    await ModePrefs.setEnabled(AppMode.breaks, true);
    await ModePrefs.setCurrent(AppMode.breaks);
    await svc.start();
    await tester.pumpWidget(testApp(const ModeHost()));
    now = now.add(const Duration(minutes: 20));
    svc.check();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Snooze 5 min'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(svc.today.taken, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle breaks page fits on the phone with big text',
      (tester) async {
    setScreen(tester, const Size(390, 844));
    await ModePrefs.setEnabled(AppMode.breaks, true);
    await ModePrefs.setCurrent(AppMode.breaks);
    await tester.pumpWidget(testApp(const ModeHost()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
