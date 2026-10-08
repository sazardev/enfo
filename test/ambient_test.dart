import 'dart:math' as math;
import 'dart:typed_data';

import 'package:enfo/modes/ambient/ambient_mode_page.dart';
import 'package:enfo/modes/ambient/ambient_player.dart';
import 'package:enfo/modes/ambient/ambient_service.dart';
import 'package:enfo/modes/ambient/ambient_synth.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

class FakePlayer implements AmbientPlayer {
  final calls = <String>[];
  double? volume;
  Duration? fade;
  bool fail = false;

  @override
  Future<void> start(String id, Uint8List wav, double volume) async {
    if (fail) throw StateError('no audio');
    calls.add('start:$id');
    this.volume = volume;
  }

  @override
  Future<void> startAsset(String id, String asset, double volume) async {
    if (fail) throw StateError('no audio');
    calls.add('loop:$asset');
    this.volume = volume;
  }

  @override
  Future<void> setVolume(double volume, {Duration fade = Duration.zero}) async {
    calls.add('volume:$volume');
    this.volume = volume;
    this.fade = fade;
  }

  @override
  Future<void> stop() async => calls.add('stop');

  // music
  void Function()? onEnded;
  double? musicVolume;
  Duration? musicFade;
  Duration position = Duration.zero;

  @override
  Future<void> startMusic(
      String asset, double volume, void Function() onEnded) async {
    if (fail) throw StateError('no audio');
    calls.add('music:$asset');
    musicVolume = volume;
    this.onEnded = onEnded;
  }

  @override
  Future<void> pauseMusic() async => calls.add('musicPause');

  @override
  Future<void> resumeMusic() async => calls.add('musicResume');

  @override
  Future<void> setMusicVolume(double volume,
      {Duration fade = Duration.zero}) async {
    calls.add('musicVolume:$volume');
    musicVolume = volume;
    musicFade = fade;
  }

  @override
  Future<void> stopMusic() async => calls.add('musicStop');

  @override
  Duration get musicPosition => position;

  /// The song reaches its end by itself.
  void endSong() => onEnded?.call();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('synth', () {
    test('every sound: right length, audible, not clipped flat', () {
      for (final s in AmbientSound.values) {
        final pcm = AmbientSynth.render(s, seconds: 3, rate: 8000);
        expect(pcm.length, 3 * 8000, reason: s.name);
        var peak = 0, sum = 0.0;
        for (final v in pcm) {
          peak = math.max(peak, v.abs());
          sum += v * v;
        }
        expect(peak, greaterThan(2000), reason: s.name);
        expect(peak, lessThanOrEqualTo(32000), reason: s.name);
        expect(math.sqrt(sum / pcm.length), greaterThan(1000), reason: s.name);
      }
    });

    test('deterministic, and the loop joins without a jump', () {
      for (final s in AmbientSound.values) {
        final a = AmbientSynth.render(s, seconds: 3, rate: 8000);
        final b = AmbientSynth.render(s, seconds: 3, rate: 8000);
        expect(a, b, reason: s.name);
        // The step across the loop point is no bigger than typical steps.
        var maxStep = 0, avgStep = 0.0;
        for (var i = 1; i < a.length; i++) {
          final d = (a[i] - a[i - 1]).abs();
          maxStep = math.max(maxStep, d);
          avgStep += d;
        }
        avgStep /= a.length - 1;
        final seam = (a.first - a.last).abs();
        expect(seam, lessThan(math.max(maxStep, avgStep * 6) + 1),
            reason: s.name);
      }
    });

    test('sounds differ in color: brown is smoother than white', () {
      double roughness(AmbientSound s) {
        final pcm = AmbientSynth.render(s, seconds: 2, rate: 8000);
        var d = 0.0, v = 0.0;
        for (var i = 1; i < pcm.length; i++) {
          d += (pcm[i] - pcm[i - 1]).abs();
          v += pcm[i].abs();
        }
        return d / v;
      }

      expect(roughness(AmbientSound.brown),
          lessThan(roughness(AmbientSound.pink)));
      expect(roughness(AmbientSound.pink),
          lessThan(roughness(AmbientSound.white)));
    });

    test('renders a full loop in an isolate', () async {
      final wav = await AmbientSynth.renderWavAsync(AmbientSound.ocean);
      expect(wav.length,
          44 + AmbientSynth.loopSeconds * AmbientSynth.sampleRate * 2);
    });

    test('wav header', () {
      final wav = AmbientSynth.wav(Int16List.fromList([0, 1, -1, 5]));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(wav.length, 44 + 8);
      final bd = ByteData.sublistView(wav);
      expect(bd.getUint32(24, Endian.little), AmbientSynth.sampleRate);
      expect(bd.getUint32(40, Endian.little), 8);
    });
  });

  group('service', () {
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
    tearDown(() async => service.stop());

    test('plays, changes volume, stops', () async {
      await service.play();
      expect(service.playing, isTrue);
      expect(player.calls, ['start:pink']);
      service.setVolume(.3);
      expect(player.volume, .3);
      await service.stop();
      expect(service.playing, isFalse);
      expect(player.calls.last, 'stop');
    });

    test('a switch while playing changes the sound, not the timer', () async {
      service.setSleepMinutes(30);
      await service.play();
      now = now.add(const Duration(minutes: 10));
      await service.select(AmbientSound.rain);
      expect(player.calls, ['start:pink', 'stop', 'start:rain']);
      expect(service.sleepRemaining, const Duration(minutes: 20));
    });

    test('sleep timer fades over the last 10 s, then stops', () async {
      service.setSleepMinutes(15);
      await service.play();
      expect(service.sleepRemaining, const Duration(minutes: 15));

      now = now.add(const Duration(minutes: 14, seconds: 30));
      service.check();
      expect(service.fading, isFalse);

      now = now.add(const Duration(seconds: 25)); // 5 s left
      service.check();
      expect(service.fading, isTrue);
      expect(player.volume, 0);
      expect(player.fade, const Duration(seconds: 5));
      expect(service.playing, isTrue);

      now = now.add(const Duration(seconds: 5));
      service.check();
      await Future<void>.delayed(Duration.zero);
      expect(service.playing, isFalse);
      expect(player.calls.last, 'stop');
    });

    test('extending the timer during the fade restores the volume', () async {
      service.setSleepMinutes(15);
      await service.play();
      now = now.add(const Duration(minutes: 14, seconds: 55));
      service.check();
      expect(service.fading, isTrue);
      service.setSleepMinutes(30);
      expect(service.fading, isFalse);
      expect(player.volume, service.volume);
    });

    test('no timer means it plays until stopped', () async {
      await service.play();
      now = now.add(const Duration(hours: 9));
      service.check();
      expect(service.playing, isTrue);
      expect(service.sleepRemaining, isNull);
    });

    test('settings persist, playing does not', () async {
      service.setVolume(.25);
      service.setSleepMinutes(45);
      await service.select(AmbientSound.ocean);
      await service.play();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      service.debugReset();
      expect(service.playing, isFalse);
      await service.load();
      expect(service.sound, AmbientSound.ocean);
      expect(service.volume, .25);
      expect(service.sleepMinutes, 45);
      expect(service.playing, isFalse);
    });

    test('the real engine fails soft where it cannot start', () async {
      service.player = SoloudAmbientPlayer();
      await service.play().timeout(const Duration(seconds: 20));
      // No audio device / native library under `flutter test`.
      expect(service.preparing, isFalse);
      expect(service.playing || service.unavailable, isTrue);
    });

    test('degrades when the engine is missing', () async {
      player.fail = true;
      await service.play();
      expect(service.playing, isFalse);
      expect(service.unavailable, isTrue);
      expect(service.preparing, isFalse);
      service.check(); // must not throw
    });
  });

  group('page', () {
    setUpAll(loadAppFonts);
    late FakePlayer player;
    final service = AmbientService.instance;

    setUp(() async {
      await resetTestState();
      service.debugReset();
      player = FakePlayer();
      service.player = player;
      service.synth = (_) async => Uint8List(4);
      nowProvider = () => DateTime(2026, 9, 28, 23);
    });
    tearDown(() async => service.stop());

    testWidgets('swipe to a sound, cycle the timer, play', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const AmbientModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Off'), findsOneWidget);

      await tester.tap(find.text('Off'));
      await tester.pump();
      expect(service.sleepMinutes, 15);
      await tester.tap(find.text('15 min'));
      await tester.pump();
      expect(service.sleepMinutes, 30);

      for (var i = 0; i < 3; i++) {
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(service.sound, isNot(AmbientSound.pink));
      final picked = service.sound;

      ModeKeys.of(AppMode.ambient)!.primary!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.playing, isTrue);
      expect(find.text('30:00 left'), findsOneWidget);

      // Paging while playing switches after the debounce.
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.sound, isNot(picked));
      expect(service.playing, isTrue);

      ModeKeys.of(AppMode.ambient)!.reset!();
      await tester.pump(const Duration(milliseconds: 300));
      expect(service.playing, isFalse);
    });

    testWidgets('shows the unavailable hint', (tester) async {
      setScreen(tester, const Size(390, 844));
      player.fail = true;
      await tester.pumpWidget(testApp(const AmbientModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      ModeKeys.of(AppMode.ambient)!.primary!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          find.text('Sound is not available on this device.'), findsOneWidget);
    });

    testWidgets('keeps playing after the page is gone', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(testApp(const AmbientModePage()));
      await tester.pump(const Duration(milliseconds: 300));
      ModeKeys.of(AppMode.ambient)!.primary!();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(testApp(const SizedBox()));
      expect(service.playing, isTrue);
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
      for (final playing in [false, true]) {
        testWidgets('fits on ${e.key}${playing ? ' (playing)' : ''}',
            (tester) async {
          setScreen(tester, e.value);
          service.setSleepMinutes(90);
          await tester.pumpWidget(testApp(const AmbientModePage()));
          await tester.pump(const Duration(milliseconds: 300));
          if (playing) {
            ModeKeys.of(AppMode.ambient)!.primary!();
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
