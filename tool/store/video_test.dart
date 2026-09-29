// Records the promo video: drives the REAL app (ModeHost) through a scripted
// demo and writes one PNG per frame (30 fps) to /tmp/enfo_video/<name>/app.
// Compositing (captions, cards) and encoding: tool/store/make_video.py.
//
//   ORIENT=portrait  flutter test tool/store/video_test.dart
//   ORIENT=landscape flutter test tool/store/video_test.dart
//   (STRIDE=30 saves every 30th frame only, for a quick look)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/modes/alerts.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/ambient/ambient_service.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/event/event_service.dart';
import 'package:enfo/modes/kitchen/kitchen_service.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/timer/timer_controller.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/molecules/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/ambient_test.dart' show FakePlayer;
import '../../test/test_harness.dart';

const _frameUs = 33333; // 30 fps

Future<void> _loadIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final candidates = [
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    '${Platform.environment['HOME']}/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  final file = candidates.map(File.new).firstWhere((f) => f.existsSync(),
      orElse: () => throw StateError('MaterialIcons font not found'));
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}

void main() {
  final orient = Platform.environment['ORIENT'] ?? 'portrait';
  final stride = int.tryParse(Platform.environment['STRIDE'] ?? '') ?? 1;
  final portrait = orient == 'portrait';
  final dpr = portrait ? 2.5 : 2.0;
  // App area in physical pixels (the rest of the canvas is caption band).
  final size = portrait ? const Size(1080, 1640) : const Size(1920, 930);
  final outDir = '/tmp/enfo_video/$orient/app';

  setUpAll(() async {
    await loadAppFonts();
    await _loadIcons();
  });

  testWidgets('record promo ($orient)', (tester) async {
    await resetTestState({
      'onboarded': true,
      'work_minutes': 2,
      'rest_minutes': 1,
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    final dir = Directory(outDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    // Frozen-but-advancing time, in step with what is pumped.
    final base = DateTime(2026, 9, 29, 10, 24, 30);
    var frameNo = 0;
    nowProvider = () => base.add(Duration(microseconds: frameNo * _frameUs));

    final player = FakePlayer();
    final ambient = AmbientService.instance;
    ambient.debugReset();
    ambient.player = player;
    ambient.synth = (_) async => Uint8List(4);
    KitchenService.instance.wipe();
    await EventService.instance.wipe();
    final ev = EventService.instance;
    for (final (name, days, icon) in [
      ('Summer trip', 41, 0),
      ('Launch day', 12, 1),
      ('Birthday', 3, 2),
    ]) {
      await ev.upsert(ev.create(
        name: name,
        target: DateTime(2026, 9, 29, 9).add(Duration(days: days)),
        icon: icon,
      ));
    }

    // The modes the demo cycles through, in order.
    const demo = [
      AppMode.pomodoro,
      AppMode.clock,
      AppMode.timer,
      AppMode.stopwatch,
      AppMode.intervals,
      AppMode.kitchen,
      AppMode.breathe,
      AppMode.music,
      AppMode.world,
      AppMode.sleep,
      AppMode.event,
    ];
    await ModePrefs.setOrder([
      ...demo,
      ...AppMode.values.where((m) => !demo.contains(m)),
    ]);
    for (final m in AppMode.values) {
      await ModePrefs.setEnabled(m, demo.contains(m));
    }
    await ModePrefs.setCurrent(AppMode.pomodoro);
    Themes.accent = Colors.indigo;
    await AppPreferences.setShowClock(false);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: testApp(const ModeHost()),
    ));

    // What the compositor needs to know.
    final captions = <Map<String, Object>>[];
    final touches = <Map<String, Object>>[];
    Offset? held;

    Future<void> shot() async {
      if (frameNo % stride != 0) return;
      await tester.runAsync(() async {
        final b = boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: dpr);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$outDir/frame_${frameNo.toString().padLeft(5, '0')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    Future<void> frame() async {
      frameNo++;
      if (ambient.musicPlaying) {
        player.position = Duration(microseconds: frameNo * _frameUs);
      }
      await tester.pump(const Duration(microseconds: _frameUs));
      if (held != null) {
        touches.add({
          'f': frameNo,
          'x': held!.dx * dpr,
          'y': held!.dy * dpr,
        });
      }
      await shot();
    }

    Future<void> hold(double seconds) async {
      final n = (seconds * 30).round();
      for (var i = 0; i < n; i++) {
        await frame();
      }
    }

    Duration ts() => Duration(microseconds: frameNo * _frameUs);

    Future<void> tapAt(Offset p, {int down = 5}) async {
      final g = await tester.startGesture(p);
      held = p;
      for (var i = 0; i < down; i++) {
        await frame();
      }
      await g.up(timeStamp: ts());
      await frame();
      held = null;
    }

    Future<void> tap(Finder f) async {
      final finder = f.hitTestable().first;
      expect(finder, findsOneWidget);
      await tapAt(tester.getCenter(finder));
    }

    /// A finger swipe spread across [frames] frames.
    Future<void> swipe(Offset from, Offset delta, {int frames = 7}) async {
      final g = await tester.startGesture(from);
      held = from;
      await frame();
      for (var i = 0; i < frames; i++) {
        await g.moveBy(delta / frames.toDouble(), timeStamp: ts());
        held = from + delta * ((i + 1) / frames);
        await frame();
      }
      await g.up(timeStamp: ts());
      await frame();
      held = null;
    }

    void caption(String title, String sub) => captions
        .add({'f': frameNo, 'title': title, 'sub': sub});

    final logical = size / dpr;
    final dialCenter = Offset(logical.width / 2, logical.height * .42);
    Future<void> tapTip(String tip) => tap(find.byTooltip(tip));
    Future<void> nextMode() => tapTip('Next mode');
    Future<void> primary() => tap(find.byType(PrimaryActionButton));

    // ---------------------------------------------------------------- script
    await hold(.4);
    caption('Pomodoro', 'Focus sessions with a live dial');
    await hold(.3);
    await primary(); // Start
    await hold(1.2);
    await swipe(dialCenter + const Offset(90, 0), const Offset(-190, 0));
    await hold(.7);
    await swipe(dialCenter + const Offset(90, 0), const Offset(-190, 0));
    await hold(.7);
    caption('63 clock styles', '60 ready-made style and color combos');
    await tapTip('Clock style');
    await hold(1.1);
    await tap(find.text('Sunset'));
    await hold(1.0);
    caption('Light and dark', 'Material You colors, strictly flat');
    AdaptiveTheme.of(tester.element(find.byType(ModeHost))).setDark();
    await hold(1.3);

    caption('Clock', 'A full screen desk clock');
    await nextMode();
    await hold(.7);
    await tapTip('Full screen');
    await hold(1.4);
    if (find.byTooltip('Exit full screen').hitTestable().evaluate().isEmpty) {
      await tapAt(Offset(logical.width / 2, logical.height / 2));
      await hold(.5);
    }
    await tapTip('Exit full screen');
    await hold(.4);

    caption('Timer', 'Presets, wheels, one tap');
    await nextMode();
    await hold(.8);
    await primary();
    await hold(1.6);

    caption('Stopwatch', 'Laps, best and slowest highlighted');
    await nextMode();
    await hold(.5);
    await primary();
    await hold(.9);
    for (var i = 0; i < 3; i++) {
      await tapTip('Lap');
      await hold(.7 + i * .1);
    }

    caption('Intervals', 'HIIT, Tabata and EMOM rounds');
    await nextMode();
    await hold(.5);
    await primary();
    await hold(2.0);

    caption('Kitchen', 'Several timers ticking at once');
    await nextMode();
    await hold(.4);
    await tap(find.text('Tea · 3m'));
    await hold(.6);
    await tap(find.text('Eggs · 7m'));
    await hold(.6);
    await tap(find.text('Pasta · 9m'));
    await hold(1.3);

    caption('Breathe', 'A calm orb to follow');
    await nextMode();
    await hold(.4);
    await primary();
    await hold(3.0);

    caption('Music', 'The dial dances to the rhythm');
    await nextMode();
    await hold(.4);
    await primary();
    await hold(3.4);

    caption('World clock', 'Real time zones, daylight saving');
    await nextMode();
    await hold(1.9);
    caption('Sleep', 'Wake at the end of a sleep cycle');
    await nextMode();
    await hold(1.9);
    caption('Events', 'Countdowns to what matters');
    await nextMode();
    await hold(1.9);

    caption('Enfo', 'A clock & timer toolbox');
    await nextMode(); // back to Pomodoro
    await hold(.5);
    AdaptiveTheme.of(tester.element(find.byType(ModeHost))).setLight();
    await tapTip('Clock style');
    await hold(.8);
    await tap(find.text('Fresh mint'));
    await hold(3.0);
    final heroEnd = frameNo;
    // Extra footage for the website hero loop (not part of the promo).
    await hold(9.0);
    // ----------------------------------------------------------------------

    File('/tmp/enfo_video/$orient/meta.json').writeAsStringSync(jsonEncode({
      'frames': frameNo,
      'heroEnd': heroEnd,
      'stride': stride,
      'scale': dpr,
      'captions': captions,
      'touches': touches,
    }));
    Alerts.reset();
  }, timeout: const Timeout(Duration(minutes: 60)));
}
