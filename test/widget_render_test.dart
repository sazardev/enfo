import 'dart:io';
import 'dart:typed_data';

import 'package:enfo/theme.dart';
import 'package:enfo/ui/clock/clock_frame.dart';
import 'package:enfo/ui/clock/clock_style.dart';
import 'package:enfo/widgets/widget_frames.dart';
import 'package:enfo/widgets/widget_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _pngMagic = [0x89, 0x50, 0x4E, 0x47];

bool _isPng(Uint8List bytes) =>
    bytes.length > 100 &&
    [for (var i = 0; i < 4; i++) bytes[i]].toString() == _pngMagic.toString();

void main() {
  setUpAll(loadAppFonts);

  testWidgets('frames render for every clock style, light and dark',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('enfo_frames');
    addTearDown(() => dir.deleteSync(recursive: true));
    final light = Themes.light(Colors.lime).colorScheme;
    final dark = Themes.dark(Colors.lime).colorScheme;

    await tester.runAsync(() async {
      for (final style in ClockStyle.values) {
        final set = await WidgetFrames.render(
          kind: WidgetKind.timer,
          dir: dir.path,
          style: style,
          rest: false,
          phase: ClockPhase.idle,
          totalSeconds: 300,
          remainingMs: 300000,
          nowMs: 1000 + style.index,
          light: light,
          dark: dark,
          labels: const ClockLabels(),
          isCurrent: () => true,
        );
        expect(set, isNotNull, reason: style.name);
        expect(set!.times, hasLength(1));
        for (final v in ['l', 'd']) {
          final bytes =
              File('${dir.path}/${set.prefix}_${v}_0.png').readAsBytesSync();
          expect(_isPng(bytes), isTrue, reason: '${style.name} $v');
        }
      }
    });
  });

  testWidgets('a running countdown gets a timeline ending at its end',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('enfo_frames');
    addTearDown(() => dir.deleteSync(recursive: true));
    final light = Themes.light(Colors.lime).colorScheme;

    await tester.runAsync(() async {
      final set = await WidgetFrames.render(
        kind: WidgetKind.pomodoro,
        dir: dir.path,
        style: ClockStyle.ring,
        rest: false,
        phase: ClockPhase.running,
        totalSeconds: 60,
        remainingMs: 45000,
        nowMs: 10000,
        light: light,
        dark: light,
        labels: const ClockLabels(),
        isCurrent: () => true,
      );
      expect(set, isNotNull);
      expect(set!.times.first, 10000);
      expect(set.times.last, 55000);
      expect(dir.listSync(), hasLength(set.times.length * 2));
    });
  });

  testWidgets('a superseded render stops and returns nothing', (tester) async {
    final dir = Directory.systemTemp.createTempSync('enfo_frames');
    addTearDown(() => dir.deleteSync(recursive: true));
    final light = Themes.light(Colors.lime).colorScheme;
    await tester.runAsync(() async {
      final set = await WidgetFrames.render(
        kind: WidgetKind.timer,
        dir: dir.path,
        style: ClockStyle.ring,
        rest: false,
        phase: ClockPhase.idle,
        totalSeconds: 60,
        remainingMs: 60000,
        nowMs: 1,
        light: light,
        dark: light,
        labels: const ClockLabels(),
        isCurrent: () => false,
      );
      expect(set, isNull);
    });
  });

  test('prune keeps only the wanted timeline of a kind', () async {
    final dir = Directory.systemTemp.createTempSync('enfo_frames');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final name in [
      'timer_1_l_0.png',
      'timer_2_l_0.png',
      'pomodoro_1_l_0.png',
    ]) {
      File('${dir.path}/$name').writeAsBytesSync([1]);
    }
    await WidgetFrames.prune(dir.path, WidgetKind.timer, 'timer_2');
    final left = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
    expect(left, {'timer_2_l_0.png', 'pomodoro_1_l_0.png'});
    await WidgetFrames.prune(dir.path, WidgetKind.timer, null);
    expect(dir.listSync().length, 1);
  });

  group('FramePlan', () {
    test('idle or paused is a single picture', () {
      final plan = FramePlan.of(
        nowMs: 5000,
        running: false,
        totalSeconds: 100,
        remainingMs: 25000,
      );
      expect(plan.times, [5000]);
      expect(plan.progress.single, closeTo(0.75, 1e-9));
    });

    test('short countdowns get one picture per second', () {
      final plan = FramePlan.of(
        nowMs: 0,
        running: true,
        totalSeconds: 10,
        remainingMs: 10000,
      );
      expect(plan.times, [for (var i = 0; i <= 10; i++) i * 1000]);
      expect(plan.progress.first, 0);
      expect(plan.progress.last, 1);
    });

    test('long countdowns are capped and end exactly at the end', () {
      final plan = FramePlan.of(
        nowMs: 1000,
        running: true,
        totalSeconds: 3 * 3600,
        remainingMs: 3 * 3600 * 1000,
      );
      expect(plan.times.length, lessThanOrEqualTo(FramePlan.maxFrames + 1));
      expect(plan.times.last, 1000 + 3 * 3600 * 1000);
      expect(plan.times.first, 1000);
      // strictly increasing, whole-second steps
      for (var i = 1; i < plan.times.length - 1; i++) {
        expect(plan.times[i] > plan.times[i - 1], isTrue);
        expect((plan.times[i] - plan.times[i - 1]) % 1000, 0);
      }
    });

    test('an already-finished countdown is one finished picture', () {
      final plan = FramePlan.of(
        nowMs: 0,
        running: true,
        totalSeconds: 60,
        remainingMs: 0,
      );
      expect(plan.times, [0]);
      expect(plan.progress.single, 1);
    });
  });
}
