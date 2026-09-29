import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/event/event_editor.dart';
import 'package:enfo/modes/event/event_logic.dart';
import 'package:enfo/modes/event/event_mode_page.dart';
import 'package:enfo/modes/event/event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

CountdownEvent ev(
  DateTime target, {
  int id = 1,
  DateTime? created,
  bool yearly = false,
  String name = 'E',
  bool notify = false,
  bool dayBefore = false,
}) =>
    CountdownEvent(
      id: id,
      name: name,
      targetMs: target.millisecondsSinceEpoch,
      createdMs: (created ?? DateTime(2026, 1, 1)).millisecondsSinceEpoch,
      yearly: yearly,
      notify: notify,
      dayBefore: dayBefore,
    );

void main() {
  final now = DateTime(2026, 9, 28, 12, 0);

  group('logic', () {
    test('upcoming splits into days, hours, minutes', () {
      final v = viewOf(ev(DateTime(2026, 10, 3, 15, 30)), now);
      expect(v.phase, EventPhase.upcoming);
      expect((v.days, v.hours, v.minutes), (5, 3, 30));
    });

    test('same day, later: still upcoming; earlier: Today!', () {
      expect(viewOf(ev(DateTime(2026, 9, 28, 18)), now).phase,
          EventPhase.upcoming);
      expect(viewOf(ev(DateTime(2026, 9, 28, 8)), now).phase, EventPhase.today);
    });

    test('past counts calendar days ago', () {
      final v = viewOf(ev(DateTime(2026, 9, 25, 23, 59)), now);
      expect(v.phase, EventPhase.past);
      expect(v.daysAgo, 3);
    });

    test('yearly rolls to next year the day after', () {
      final e = ev(DateTime(1990, 9, 27, 9), yearly: true);
      expect(viewOf(e, now).target, DateTime(2027, 9, 27, 9));
      // On the day itself it stays "Today!".
      final today = viewOf(ev(DateTime(1990, 9, 28, 9), yearly: true), now);
      expect(today.phase, EventPhase.today);
      expect(today.target, DateTime(2026, 9, 28, 9));
    });

    test('29 February falls back to the 28th', () {
      final e = ev(DateTime(2024, 2, 29, 10), yearly: true);
      expect(viewOf(e, now).target, DateTime(2027, 2, 28, 10));
      expect(
        viewOf(e, DateTime(2027, 12, 1)).target,
        DateTime(2028, 2, 29, 10),
      );
    });

    test('progress runs from creation to target', () {
      final e = ev(
        DateTime(2026, 9, 30),
        created: DateTime(2026, 9, 26),
      );
      final v = viewOf(e, DateTime(2026, 9, 28));
      expect(v.progress, closeTo(0.5, 1e-9));
    });

    test('yearly progress starts at the previous occurrence', () {
      final e = ev(DateTime(2000, 9, 28, 12), yearly: true);
      final v = viewOf(e, DateTime(2026, 3, 28, 12));
      expect(v.start, DateTime(2025, 9, 28, 12));
      expect(v.target, DateTime(2026, 9, 28, 12));
      expect(v.progress, closeTo(0.5, 0.01));
    });

    test('ordering: today, then nearest upcoming, then most recent past', () {
      final list = orderedViews([
        ev(DateTime(2026, 9, 1), id: 1),
        ev(DateTime(2026, 12, 1), id: 2),
        ev(DateTime(2026, 10, 1), id: 3),
        ev(DateTime(2026, 9, 28, 6), id: 4),
        ev(DateTime(2026, 9, 20), id: 5),
      ], now);
      expect([for (final v in list) v.event.id], [4, 3, 2, 5, 1]);
    });

    test('face reading lands exactly on days:hours', () {
      final v = viewOf(
        ev(DateTime(2026, 10, 10, 17), created: DateTime(2026, 9, 1)),
        now,
      );
      final r = v.face;
      expect(r.daysMode, isTrue);
      expect(r.remainingUnits, 12 * 60 + 5);
      final remaining = (r.totalUnits * (1 - r.progress)).ceil();
      expect(remaining, r.remainingUnits);
    });

    test('face reading under a day is hours:minutes', () {
      final v = viewOf(ev(DateTime(2026, 9, 28, 14, 20)), now);
      final r = v.face;
      expect(r.daysMode, isFalse);
      expect(r.remainingUnits, 2 * 60 + 20);
    });

    test('shortRemaining', () {
      String s(Duration d) =>
          shortRemaining(d, dayUnit: 'd', hourUnit: 'h', minuteUnit: 'm');
      expect(s(const Duration(days: 3, hours: 4)), '3d 4h');
      expect(s(const Duration(hours: 5, minutes: 12)), '5h 12m');
      expect(s(const Duration(minutes: 12)), '12m');
    });
  });

  group('service', () {
    setUp(() async {
      await resetTestState({'onboarded': true});
      nowProvider = () => now;
      await EventService.instance.wipe();
    });

    test('persists and reloads', () async {
      final s = EventService.instance;
      await s.upsert(s.create(name: 'Trip', target: DateTime(2026, 12, 24)));
      s.events.value = [];
      await s.load();
      expect(s.events.value.single.name, 'Trip');
    });

    test('ids stay unique after a removal', () async {
      final s = EventService.instance;
      await s.upsert(s.create(name: 'A', target: DateTime(2026, 12, 24)));
      await s.upsert(s.create(name: 'B', target: DateTime(2026, 12, 25)));
      await s.remove(s.events.value.first);
      await s.upsert(s.create(name: 'C', target: DateTime(2026, 12, 26)));
      final ids = s.events.value.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('notification times: target and the day before, future only', () {
      final e = ev(DateTime(2026, 9, 29, 10), notify: true, dayBefore: true);
      final times = EventService.notificationTimes(e, now);
      // The day-before moment (28th 10:00) already passed.
      expect(times.map((t) => t.at), [DateTime(2026, 9, 29, 10)]);
      final later =
          ev(DateTime(2026, 10, 5, 10), notify: true, dayBefore: true);
      expect(EventService.notificationTimes(later, now).length, 2);
    });

    test('yearly events schedule several years ahead', () {
      final e = ev(DateTime(1990, 12, 1, 8), yearly: true, notify: true);
      final times = EventService.notificationTimes(e, now);
      expect(times.map((t) => t.at.year), [2026, 2027, 2028]);
    });

    test('nothing to notify when off', () {
      expect(
        EventService.notificationTimes(ev(DateTime(2026, 12, 1)), now),
        isEmpty,
      );
    });

    test('check marks a passed moment handled once', () async {
      final s = EventService.instance;
      // Mobile-safe path: on the test host (Linux) Notifier.show is
      // best-effort and swallows the missing plugin.
      await s.upsert(s
          .create(
            name: 'Soon',
            target: DateTime(2026, 9, 28, 12, 30),
          )
          .copyWith(notify: true));
      s.checkAt(DateTime(2026, 9, 28, 12, 31));
      expect(s.events.value.single.firedMs,
          DateTime(2026, 9, 28, 12, 30).millisecondsSinceEpoch);
      final before = s.events.value.single;
      s.checkAt(DateTime(2026, 9, 28, 12, 32));
      expect(identical(s.events.value.single, before), isTrue);
    });

    test('saving an already-past event does not fire it', () async {
      final s = EventService.instance;
      await s.upsert(s
          .create(name: 'Old', target: DateTime(2026, 9, 28, 11))
          .copyWith(notify: true));
      expect(s.events.value.single.firedMs, greaterThan(0));
    });
  });

  group('widgets', () {
    const screens = <String, Size>{
      'watch': Size(200, 200),
      'phone': Size(390, 844),
      'landscape': Size(844, 390),
      'tablet': Size(800, 1280),
      'tv': Size(960, 540),
      'desktop': Size(1920, 1080),
    };

    setUpAll(loadAppFonts);
    setUp(() async {
      await resetTestState({'onboarded': true});
      nowProvider = () => now;
      await EventService.instance.wipe();
      final s = EventService.instance;
      for (final t in [
        DateTime(2026, 10, 3, 15, 30),
        DateTime(2026, 9, 28, 8),
        DateTime(2026, 9, 1),
        DateTime(2027, 2, 14, 20),
      ]) {
        await s.upsert(
            s.create(name: 'Event ${t.month}/${t.day}', target: t, icon: 2));
      }
    });

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    for (final size in screens.entries) {
      testWidgets('list fits on ${size.key}', (tester) async {
        setScreen(tester, size.value);
        await tester.pumpWidget(testApp(const EventModePage()));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Event'), findsWidgets);
      });

      testWidgets('editor fits on ${size.key}', (tester) async {
        setScreen(tester, size.value);
        await tester.pumpWidget(testApp(const EventModePage()));
        await settle(tester);
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await settle(tester);
        expect(find.byType(EventEditor), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty state fits on ${size.key}', (tester) async {
        await EventService.instance.wipe();
        setScreen(tester, size.value);
        await tester.pumpWidget(testApp(const EventModePage()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('create an event through the form', (tester) async {
      setScreen(tester, const Size(390, 844));
      await EventService.instance.wipe();
      await tester.pumpWidget(testApp(const EventModePage()));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Concert');
      await tester.pump();
      await tester.ensureVisible(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      final events = EventService.instance.events.value;
      expect(events.single.name, 'Concert');
      // Default: tomorrow 09:00.
      expect(events.single.target, DateTime(2026, 9, 29, 9));
      expect(find.byType(EventEditor), findsNothing);
    });

    testWidgets('the Today! state is shown', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const EventModePage()));
      await settle(tester);
      expect(find.text('Today!'), findsWidgets);
    });

    testWidgets('an animated style does not overflow', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const EventModePage()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull);
    });

    test('icon lookup clamps', () {
      expect(eventIconOf(99), eventIcons.last);
      expect(eventIconOf(-1), eventIcons.first);
    });
  });
}
