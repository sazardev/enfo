import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/tool_history.dart';
import 'package:enfo/modes/tracker/tracker_mode_page.dart';
import 'package:enfo/modes/tracker/tracker_service.dart';
import 'package:enfo/modes/tracker/tracker_stats.dart';
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
  setUpAll(loadAppFonts);
  late DateTime now;
  setUp(() async {
    await resetTestState({'onboarded': true});
    now = DateTime(2026, 9, 28, 10, 0);
    nowProvider = () => now;
    await TrackerService.instance.wipe();
  });

  ToolEvent ev(String label, DateTime at, int seconds) =>
      ToolEvent(kind: ToolKind.tracker, at: at, seconds: seconds, label: label);

  test('dailyTotals buckets by start day and ignores others', () {
    final today = DateTime(2026, 9, 28, 12);
    final totals = dailyTotals([
      ev('Study', DateTime(2026, 9, 28, 8), 600),
      ev('Study', DateTime(2026, 9, 28, 9), 300),
      ev('Study', DateTime(2026, 9, 22, 23, 59), 60),
      ev('Study', DateTime(2026, 9, 21, 10), 999), // 8 days ago: out
      ev('Code', DateTime(2026, 9, 28, 8), 5000), // other activity
      ToolEvent(kind: ToolKind.timer, at: DateTime(2026, 9, 28), seconds: 77),
    ], label: 'Study', today: today);
    expect(totals, [60, 0, 0, 0, 0, 0, 900]);
    expect(totalOnDay([ev('Code', DateTime(2026, 9, 28, 1), 30)], today), 30);
  });

  test('one activity at a time; switching saves; short sessions dropped',
      () async {
    final t = TrackerService.instance;
    await t.start('d-study');
    now = now.add(const Duration(minutes: 30));
    await t.start('d-code'); // stops study
    expect(t.runningId, 'd-code');
    now = now.add(const Duration(seconds: 5));
    await t.stop(); // too short
    final events = await ToolHistory.load();
    expect(events, hasLength(1));
    expect(events.single.label, 'Study');
    expect(events.single.seconds, 1800);
    expect(events.single.kind, ToolKind.tracker);
    expect(t.running, isFalse);
  });

  test('running activity survives a restart', () async {
    final t = TrackerService.instance;
    await t.start('d-reading');
    now = now.add(const Duration(minutes: 5));
    // Simulate a restart: state comes back from prefs.
    t.runningId = null;
    t.startedAt = null;
    await t.load();
    expect(t.runningId, 'd-reading');
    expect(t.elapsedSeconds, 300);
  });

  test('toggleLast, manual time, create and delete', () async {
    final t = TrackerService.instance;
    await t.toggleLast();
    expect(t.runningId, 'd-study');
    now = now.add(const Duration(minutes: 1));
    await t.toggleLast();
    expect(t.running, isFalse);
    await t.addManual('d-code', 20);
    expect(t.events.last.seconds, 1200);
    final a = await t.create(Colors.red.toARGB32());
    await t.update(a.copyWith(name: 'Piano'));
    expect(t.byId(a.id)!.displayName, 'Piano');
    await t.delete(a.id);
    expect(t.byId(a.id), isNull);
  });

  for (final size in _screens.entries) {
    testWidgets('tracker page fits on ${size.key}', (tester) async {
      setScreen(tester, size.value);
      final t = TrackerService.instance;
      await t.start('d-study');
      now = now.add(const Duration(minutes: 12));
      await t.stop();
      await t.addManual('d-study', 45);
      await t.start('d-code');
      now = now.add(const Duration(seconds: 90));
      await tester.pumpWidget(testApp(const TrackerModePage()));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('01:30'), findsOneWidget);

      // Open the editor of the selected activity.
      if (size.key != 'watch') {
        await tester.tap(find.byTooltip('Edit activity'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await t.stop();
    });
  }
}
