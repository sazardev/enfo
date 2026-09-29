import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/world/meeting_planner.dart';
import 'package:enfo/modes/world/meeting_planner_page.dart';
import 'package:enfo/modes/world/world_clock_page.dart';
import 'package:enfo/modes/world/world_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

PlanZone fixed(String id, double hours) =>
    PlanZone(id, (_) => Duration(minutes: (hours * 60).round()));

const _screens = <String, Size>{
  'phone': Size(390, 844),
  'phone-landscape': Size(844, 390),
  'tablet': Size(800, 1280),
  'tv': Size(960, 540),
  'desktop': Size(1920, 1080),
};

void main() {
  setUpAll(loadAppFonts);

  group('planMeeting', () {
    final from = DateTime.utc(2026, 9, 29, 0, 0);

    test('London and New York overlap in the afternoon (London time)', () {
      final plan = planMeeting([fixed('lon', 1), fixed('nyc', -4)], from);
      expect(plan.hasOverlap, isTrue);
      expect(plan.windows.length, 1);
      // NY 09-18 = 13-22 UTC; London 09-18 = 08-17 UTC.
      expect(plan.windows.first.start, DateTime.utc(2026, 9, 29, 13));
      expect(plan.windows.first.end, DateTime.utc(2026, 9, 29, 17));
    });

    test('no overlap picks the least bad instant', () {
      final plan = planMeeting([fixed('nyc', -4), fixed('tok', 9)], from);
      expect(plan.hasOverlap, isFalse);
      expect(plan.leastBad, isNotNull);
      expect(plan.leastBadAtWork, 1);
      // Best compromise sits between the two workdays, not in the night
      // of both: check it is close to at least one zone's work hours.
      final nyc = fixed('nyc', -4);
      final tok = fixed('tok', 9);
      final t = plan.leastBad!;
      expect(nyc.minutesFromWork(t) + tok.minutesFromWork(t), lessThan(4 * 60));
    });

    test('half-hour zones work at quarter-hour precision', () {
      final plan = planMeeting([fixed('del', 5.5), fixed('lon', 1)], from);
      expect(plan.hasOverlap, isTrue);
      final w = plan.windows.first;
      // Delhi 09:00 = 03:30 UTC; London until 17:00 UTC; Delhi until 12:30.
      expect(w.start, DateTime.utc(2026, 9, 29, 8));
      expect(w.end, DateTime.utc(2026, 9, 29, 12, 30));
    });

    test('day offset relative to the reference', () {
      final tok = fixed('tok', 9);
      final nyc = fixed('nyc', -4);
      final t = DateTime.utc(2026, 9, 29, 20); // 05:00 next day in Tokyo
      expect(dayOffset(tok, nyc, t), 1);
      expect(dayOffset(nyc, tok, t), -1);
      expect(dayOffset(nyc, nyc, t), 0);
    });

    test('a window running to the end of the span is closed', () {
      final plan = planMeeting([fixed('a', 0)], DateTime.utc(2026, 9, 29, 16));
      // 16:00-18:00 today, and again 09:00-16:00 tomorrow (the span ends).
      expect(plan.windows.map((w) => w.length.inHours).toSet(), {2, 7});
    });
  });

  for (final size in _screens.entries) {
    testWidgets('planner fits on ${size.key}', (tester) async {
      await resetTestState({'onboarded': true});
      nowProvider = () => DateTime(2026, 9, 29, 10, 0);
      setScreen(tester, size.value);
      await WorldPrefs.add('Asia/Kolkata');
      await WorldPrefs.add('Australia/Sydney');
      await tester.pumpWidget(testApp(const MeetingPlannerPage()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      // Selecting a city makes it the reference; the marker moves.
      await tester.ensureVisible(find.text('Tokyo'));
      await tester.pump();
      await tester.tap(find.text('Tokyo'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Selected time in Tokyo'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('15 minutes later'));
      await tester.pump();
      await tester.tap(find.byTooltip('15 minutes later'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('world page offers the planner and opens it', (tester) async {
    await resetTestState({'onboarded': true});
    setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(testApp(const WorldClockPage()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(find.text('Plan a meeting'), 200);
    await tester.tap(find.text('Plan a meeting'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(MeetingPlannerPage), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-selected-time')), findsOneWidget);
  });
}
