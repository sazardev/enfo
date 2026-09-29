import 'package:enfo/app_preferences.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/event/event_service.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/stopwatch/stopwatch_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Regressions found while rendering store screenshots: layouts that only
/// broke with realistic content (four events, six laps) at in-between
/// sizes such as phone landscape and a 7" tablet in portrait.
const _sizes = <Size>[
  Size(711, 400),
  Size(873, 491),
  Size(600, 960),
  Size(320, 480),
  Size(360, 640),
  Size(390, 844),
  Size(844, 390),
  Size(768, 1024),
  Size(1024, 768),
  Size(1280, 800),
  Size(1920, 1080),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

final _lapTime = RegExp(r'^\d{2}:\d{2}\.\d{2}$');

void main() {
  setUpAll(loadAppFonts);
  setUp(() async {
    await resetTestState({'onboarded': true});
    nowProvider = () => DateTime(2026, 9, 28, 21, 47, 32);
  });

  for (final ui in UiSize.values) {
    for (final size in _sizes) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} ${ui.name}';

      testWidgets('events with four entries fit at $tag', (tester) async {
        setScreen(tester, size);
        await AppPreferences.setUiSize(ui);
        final e = EventService.instance;
        await e.wipe();
        final now = nowProvider();
        await e.upsert(e.create(
            name: 'Product launch',
            target: DateTime(now.year, now.month, now.day + 3, 16),
            icon: 6));
        await e.upsert(e.create(
            name: 'Anna\'s birthday',
            target: DateTime(1994, now.month, now.day + 9, 9),
            yearly: true,
            icon: 1));
        await e.upsert(e.create(
            name: 'Trip to Lisbon',
            target: DateTime(now.year, now.month, now.day + 23, 7, 30),
            icon: 3));
        await e.upsert(e.create(
            name: 'New Year',
            target: DateTime(now.year + 1, 1, 1),
            yearly: true,
            icon: 4));
        await ModePrefs.setCurrent(AppMode.event);
        await tester.pumpWidget(testApp(const ModeHost()));
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('stopwatch laps stay on one line at $tag', (tester) async {
        setScreen(tester, size);
        await AppPreferences.setUiSize(ui);
        final sw = StopwatchController.instance;
        var now = DateTime(2026, 9, 28, 21, 0);
        nowProvider = () => now;
        sw.start();
        for (final s in [41, 39, 40, 44, 35, 47, 38]) {
          now = now.add(Duration(seconds: s, milliseconds: 230));
          sw.lap();
        }
        now = now.add(const Duration(seconds: 17));
        await ModePrefs.setCurrent(AppMode.stopwatch);
        await tester.pumpWidget(testApp(const ModeHost()));
        await _settle(tester);
        expect(tester.takeException(), isNull);

        // Lap rows are the mono texts formatted mm:ss.cc; the big digits
        // and the current-lap line live in the face and are skipped by
        // looking only at texts that are not inside a CustomPaint.
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => _lapTime.hasMatch(t.data ?? ''))
            .toList();
        expect(texts, isNotEmpty);
        for (final t in texts) {
          final box = tester.renderObject<RenderBox>(find.byWidget(t).first);
          final fontSize =
              MediaQuery.textScalerOf(tester.element(find.byWidget(t).first))
                  .scale(t.style?.fontSize ?? 14);
          // One line of text is well under 2x its font size; a per-character
          // wrap would be 5+ lines tall.
          expect(box.size.height, lessThan(fontSize * 2.2 + 8),
              reason: 'lap text "${t.data}" wrapped at $tag');
        }
        sw.wipe();
      });
    }
  }
}
