import 'dart:io';
import 'dart:math' as math;

import 'package:enfo/modes/ambient/ambient_mode_page.dart';
import 'package:enfo/modes/ambient/audio_dial.dart';
import 'package:enfo/modes/music/music_credits_page.dart';
import 'package:enfo/modes/music/music_envelope.dart';
import 'package:enfo/ui/clock/clock_frame.dart';
import 'package:enfo/ui/clock/clock_style.dart';
import 'package:enfo/ui/clock/clock_view.dart';
import 'package:enfo/modes/music/music_mode_page.dart';
import 'package:flutter/services.dart';
import 'package:enfo/modes/ambient/ambient_service.dart';
import 'package:enfo/modes/ambient/music_catalog.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ambient_test.dart' show FakePlayer;
import 'test_harness.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final n = musicCatalog.length;

  group('catalog', () {
    test('every asset exists and is an Ogg file', () {
      for (final t in musicCatalog) {
        final f = File(t.asset);
        expect(f.existsSync(), isTrue, reason: t.asset);
        expect(String.fromCharCodes(f.readAsBytesSync().sublist(0, 4)), 'OggS',
            reason: t.asset);
        expect(t.seconds, greaterThan(10), reason: t.asset);
        expect(t.title, isNotEmpty);
        expect(t.artist, isNotEmpty);
      }
    });

    test('licenses are CC0 or CC BY, and credit is required for BY', () {
      final assets = <String>{};
      for (final t in musicCatalog) {
        expect(assets.add(t.asset), isTrue, reason: 'duplicate ${t.asset}');
        expect(t.license == 'CC0' || t.license.startsWith('CC BY '), isTrue,
            reason: t.license);
        expect(t.license.contains('NC') || t.license.contains('ND'), isFalse);
        expect(t.needsCredit, t.license != 'CC0', reason: t.title);
        expect(t.licenseUrl, startsWith('http'));
        expect(t.source, contains('commons.wikimedia.org'));
      }
    });

    test('every asset is registered in pubspec.yaml', () {
      expect(
          File('pubspec.yaml').readAsStringSync(), contains('assets/music/'));
    });
  });

  group('envelope', () {
    test('samples with interpolation and is silent outside the song', () {
      final e = MusicEnvelope(Uint8List.fromList([0, 255, 0, 51]));
      expect(e.sample(Duration.zero), 0);
      expect(e.sample(const Duration(milliseconds: 50)), 1); // frame 1
      expect(e.sample(const Duration(milliseconds: 25)), closeTo(.5, 1e-9));
      expect(e.sample(const Duration(milliseconds: 150)), closeTo(.2, 1e-9));
      expect(e.sample(const Duration(seconds: 5)), 0);
      expect(e.sample(const Duration(seconds: -1)), 0);
      expect(MusicEnvelope(Uint8List(0)).sample(const Duration(seconds: 1)), 0);
    });

    test('smoothing rises fast, falls slowly, never overshoots', () {
      var v = 0.0;
      v = smoothToward(v, 1, .05);
      expect(v, inExclusiveRange(.5, 1));
      final rise = v;
      var w = 1.0;
      w = smoothToward(w, 0, .05);
      expect(1 - w, lessThan(rise)); // falling is slower than rising
      for (var i = 0; i < 200; i++) {
        v = smoothToward(v, .3, .016);
        expect(v, inInclusiveRange(.3, 1));
      }
      expect(v, closeTo(.3, .01));
      expect(smoothToward(.4, 1, 0), .4);
    });

    test('every song ships an envelope of the right length', () {
      for (final t in musicCatalog) {
        final f = File(MusicEnvelope.assetOf(t));
        expect(f.existsSync(), isTrue, reason: f.path);
        final n = f.lengthSync();
        expect((n - t.seconds * MusicEnvelope.fps).abs(),
            lessThanOrEqualTo(MusicEnvelope.fps * 2),
            reason: t.title);
        final bytes = f.readAsBytesSync();
        expect(bytes.reduce(math.max), greaterThan(200), reason: t.title);
        expect(bytes.fold<int>(0, (a, b) => a + b) / n, greaterThan(10));
      }
    });
  });

  testWidgets('every clock style draws with no total (ambient, no timer)',
      (tester) async {
    setScreen(tester, const Size(400, 400));
    for (final style in ClockStyle.values) {
      await tester.pumpWidget(MaterialApp(
          home: ClockView(
        style: style,
        palette: ClockPalette.of(ThemeData().colorScheme,
            rest: false, paused: false),
        frame: const ClockFrame(
            progress: 0, totalSeconds: 0, phase: ClockPhase.idle, time: 3),
      )));
      expect(tester.takeException(), isNull, reason: style.name);
    }
  });

  group('playlist', () {
    late FakePlayer player;
    late DateTime now;
    final service = AmbientService.instance;

    setUp(() async {
      await resetTestState();
      service.debugReset();
      player = FakePlayer();
      service.player = player;
      service.synth = (_) async => Uint8List(4);
      now = DateTime(2026, 9, 28, 23);
      nowProvider = () => now;
    });
    tearDown(() async => service.stopAll());

    test('plays the first song, pauses, resumes', () async {
      await service.playMusic();
      expect(service.musicPlaying, isTrue);
      expect(player.calls, ['music:${musicCatalog[0].asset}']);
      await service.pauseMusic();
      expect(service.musicPlaying, isFalse);
      expect(service.musicPaused, isTrue);
      await service.toggleMusic();
      expect(service.musicPlaying, isTrue);
      expect(player.calls.sublist(1), ['musicPause', 'musicResume']);
    });

    test('advances when a song ends and wraps at the end', () async {
      await service.playMusic();
      player.endSong();
      await settle();
      expect(service.musicIndex, 1);
      expect(player.calls.last, 'music:${musicCatalog[1].asset}');
      await service.playTrack(n - 1);
      player.endSong();
      await settle();
      expect(service.musicIndex, 0);
      expect(service.musicPlaying, isTrue);
    });

    test('without repeat the list ends and rests on the first song', () async {
      service.setRepeat(false);
      await service.playTrack(n - 1);
      player.endSong();
      await settle();
      expect(service.musicPlaying, isFalse);
      expect(service.musicIndex, 0);
      expect(player.calls.last, 'musicStop');
    });

    test('next / previous wrap; previous restarts a song past 3 s', () async {
      await service.previousTrack();
      expect(service.musicIndex, n - 1);
      await service.nextTrack();
      expect(service.musicIndex, 0);
      await service.nextTrack();
      expect(service.musicIndex, 1);
      player.position = const Duration(seconds: 10);
      service.check();
      await service.previousTrack();
      expect(service.musicIndex, 1, reason: 'restarted, not stepped back');
      player.position = const Duration(seconds: 1);
      service.check();
      await service.previousTrack();
      expect(service.musicIndex, 0);
    });

    test('a stale end callback from a replaced song is ignored', () async {
      await service.playMusic();
      final stale = player.onEnded!;
      await service.playTrack(4);
      stale();
      await settle();
      expect(service.musicIndex, 4);
    });

    test('shuffle visits every song once before repeating any', () async {
      service.random = math.Random(7);
      service.setShuffle(true);
      await service.playTrack(5);
      final seen = <int>[service.musicIndex];
      for (var i = 0; i < n - 1; i++) {
        player.endSong();
        await settle();
        seen.add(service.musicIndex);
      }
      expect(seen.toSet().length, n, reason: '$seen');
      expect(seen.first, 5);
      // The next cycle never opens with the song that just ended.
      final last = seen.last;
      player.endSong();
      await settle();
      expect(service.musicIndex, isNot(last));
      expect(service.musicPlaying, isTrue);
    });

    test('volumes are independent and both voices can play', () async {
      await service.play();
      await service.playMusic();
      service.setVolume(.2);
      service.setMusicVolume(.7);
      expect(player.volume, .2);
      expect(player.musicVolume, .7);
      expect(service.playing && service.musicPlaying, isTrue);
      await service.stop();
      expect(service.musicPlaying, isTrue);
    });

    test('the sleep timer fades and ends both voices', () async {
      service.setSleepMinutes(15);
      await service.play();
      await service.playMusic();
      expect(service.sleepRemaining, const Duration(minutes: 15));
      now = now.add(const Duration(minutes: 14, seconds: 55));
      service.check();
      expect(service.fading, isTrue);
      expect(player.volume, 0);
      expect(player.musicVolume, 0);
      expect(player.musicFade, const Duration(seconds: 5));
      now = now.add(const Duration(seconds: 5));
      service.check();
      await settle();
      expect(service.playing, isFalse);
      expect(service.musicPlaying, isFalse);
      expect(player.calls.last, anyOf('stop', 'musicStop'));
    });

    test('music alone starts the timer; pausing it clears it', () async {
      service.setSleepMinutes(30);
      await service.playMusic();
      expect(service.sleepRemaining, const Duration(minutes: 30));
      await service.pauseMusic();
      expect(service.sleepRemaining, isNull);
    });

    test('settings persist, playing does not', () async {
      service.setMusicVolume(.35);
      service.setShuffle(true);
      service.setRepeat(false);
      await service.playTrack(3);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      service.debugReset();
      await service.load();
      expect(service.musicVolume, .35);
      expect(service.shuffle, isTrue);
      expect(service.repeat, isFalse);
      expect(service.musicIndex, 3);
      expect(service.musicPlaying, isFalse);
    });

    test('a missing engine shows the hint instead of throwing', () async {
      player.fail = true;
      await service.playMusic();
      expect(service.musicPlaying, isFalse);
      expect(service.musicPreparing, isFalse);
      expect(service.unavailable, isTrue);
      service.check();
    });
  });

  group('pages', () {
    setUpAll(loadAppFonts);
    late FakePlayer player;
    final service = AmbientService.instance;

    setUp(() async {
      await resetTestState();
      service.debugReset();
      player = FakePlayer();
      service.player = player;
      nowProvider = () => DateTime(2026, 9, 28, 23);
    });
    tearDown(() async => service.stopAll());

    testWidgets('shows only titles; the action plays and pauses',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(musicCatalog[0].title), findsOneWidget);
      // No metadata on the page.
      expect(find.textContaining(musicCatalog[0].artist), findsNothing);
      expect(find.textContaining('CC'), findsNothing);
      expect(find.byType(Slider), findsNothing);

      ModeKeys.of(AppMode.music)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.musicPlaying, isTrue);
      expect(player.calls.last, 'music:${musicCatalog[0].asset}');
      ModeKeys.of(AppMode.music)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.musicPlaying, isFalse);
      expect(service.musicPaused, isTrue);
    });

    testWidgets('swiping selects while paused, switches when playing',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicModePage()));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.musicIndex, greaterThan(0));
      expect(service.musicPlaying, isFalse);
      expect(player.calls.where((c) => c.startsWith('music:')), isEmpty);

      ModeKeys.of(AppMode.music)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      final first = service.musicIndex;
      expect(player.calls.last, 'music:${musicCatalog[first].asset}');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.musicIndex, first + 1);
      expect(player.calls.last, 'music:${musicCatalog[first + 1].asset}');
    });

    testWidgets('the dial is there; vertical swipe and arrows change style',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AudioDial), findsOneWidget);
      expect(await ClockStyle.load(), ClockStyle.ring);

      await tester.fling(find.byType(AudioDial), const Offset(0, -300), 1500);
      await tester.pump(const Duration(milliseconds: 400));
      final after = await tester.runAsync(ClockStyle.load);
      expect(after, ClockStyle.ring.step(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 400));
      expect(await tester.runAsync(ClockStyle.load), ClockStyle.ring);
      // The song did not change.
      expect(service.musicIndex, 0);
    });

    testWidgets('the dial reads the song clock and freezes when paused',
        (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      ModeKeys.of(AppMode.music)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      player.position = Duration(seconds: musicCatalog[0].seconds ~/ 2);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final frame = tester.widget<ClockView>(find.byType(ClockView)).frame;
      expect(frame.progress, closeTo(.5, .02));
      expect(frame.totalSeconds, musicCatalog[0].seconds);

      ModeKeys.of(AppMode.music)!.primary!(); // pause
      await tester.pump(const Duration(milliseconds: 300));
      final t0 = tester.widget<ClockView>(find.byType(ClockView)).frame.time;
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<ClockView>(find.byType(ClockView)).frame.time, t0);
    });

    testWidgets('a song ending moves the pager', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      ModeKeys.of(AppMode.music)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      player.endSong();
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.musicIndex, 1);
      expect(find.text(musicCatalog[1].title), findsOneWidget);
      // The pager following must not restart the song.
      await tester.pump(const Duration(milliseconds: 400));
      expect(player.calls.where((c) => c.startsWith('music:')).length, 2);
    });

    testWidgets('credits page lists every song', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const MusicCreditsPage()));
      await tester.pump(const Duration(milliseconds: 300));
      for (final t in musicCatalog) {
        expect(find.text('${t.title} — ${t.artist} · ${t.license}'),
            findsOneWidget,
            reason: t.title);
      }
    });

    const screens = <String, Size>{
      'watch': Size(200, 200),
      'watch-tall': Size(192, 240),
      'phone': Size(390, 844),
      'phone-landscape': Size(844, 390),
      'tablet': Size(800, 1280),
      'tv': Size(960, 540),
      'desktop': Size(1920, 1080),
    };
    for (final e in screens.entries) {
      for (final music in [false, true]) {
        testWidgets('${music ? 'music' : 'sounds'} fits on ${e.key}',
            (tester) async {
          setScreen(tester, e.value);
          service.setSleepMinutes(90);
          await tester.pumpWidget(
              testApp(music ? const MusicModePage() : const AmbientModePage()));
          await tester.pump(const Duration(milliseconds: 300));
          (music
              ? ModeKeys.of(AppMode.music)!.primary!
              : ModeKeys.of(AppMode.ambient)!.primary!)();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
