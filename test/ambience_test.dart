import 'dart:io';
import 'dart:typed_data';

import 'package:enfo/l10n/gen/app_localizations_en.dart';
import 'package:enfo/modes/ambient/ambience_catalog.dart';
import 'package:enfo/modes/ambient/ambience_labels.dart';
import 'package:enfo/modes/ambient/ambient_service.dart';
import 'package:enfo/modes/ambient/ambient_synth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ambient_test.dart' show FakePlayer;
import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ambience catalog', () {
    test('20 nature loops first, then 20 places, ids unique', () {
      expect(ambienceLoops.length, 40);
      expect(natureLoops.length, 20);
      expect(placeLoops.length, 20);
      expect(ambienceLoops.take(20).every((l) => l.group == 'nature'), isTrue);
      final ids = {for (final l in ambienceLoops) l.id};
      expect(ids.length, 40);
    });

    test('every asset exists, is Ogg and has metadata', () {
      for (final l in ambienceLoops) {
        final f = File(l.asset);
        expect(f.existsSync(), isTrue, reason: l.asset);
        expect(String.fromCharCodes(f.readAsBytesSync().sublist(0, 4)), 'OggS',
            reason: l.asset);
        expect(l.seconds, greaterThan(10), reason: l.asset);
        expect(l.title, isNotEmpty);
        expect(l.artist, isNotEmpty);
        expect(l.licenseUrl, startsWith('http'));
        expect(l.source, contains('commons.wikimedia.org'));
        expect(l.license == 'CC0' ||
            l.license == 'Public domain' ||
            l.license.startsWith('CC BY '), isTrue, reason: l.license);
        expect(l.license.contains('NC') || l.license.contains('ND'), isFalse);
      }
    });

    test('every loop has a localized label', () {
      final en = AppLocalizationsEn();
      for (final l in ambienceLoops) {
        expect(l.label(en), isNotEmpty, reason: l.id);
      }
    });
  });

  group('service loops', () {
    late FakePlayer player;
    final service = AmbientService.instance;

    setUp(() async {
      await resetTestState();
      service.debugReset();
      player = FakePlayer();
      service.player = player;
      service.synth = (_) async => Uint8List(4);
    });
    tearDown(() async => service.stopAll());

    test('plays a recorded loop from its asset and back to a synth sound',
        () async {
      final loop = placeLoops.first;
      await service.selectLoop(loop);
      expect(service.loop, loop);
      expect(service.playing, isFalse);
      await service.play();
      expect(player.calls, ['loop:${loop.asset}']);
      expect(service.playing, isTrue);

      await service.select(AmbientSound.rain);
      expect(service.loop, isNull);
      expect(player.calls,
          ['loop:${loop.asset}', 'stop', 'start:rain']);
    });

    test('switching loops while playing keeps the sleep timer', () async {
      service.setSleepMinutes(30);
      await service.selectLoop(natureLoops.first);
      await service.play();
      final remaining = service.sleepRemaining;
      await service.selectLoop(natureLoops.elementAt(1));
      expect(player.calls.last, 'loop:${natureLoops.elementAt(1).asset}');
      expect(service.sleepRemaining, isNotNull);
      expect(
          service.sleepRemaining!.inSeconds,
          closeTo(remaining!.inSeconds, 1));
    });

    test('the breaks picker is separate from a synth bed', () async {
      service.breaksLoop = natureLoops.first;
      await service.play();
      await service.selectBreaksLoop(natureLoops.elementAt(2));
      expect(service.breaksLoop, natureLoops.elementAt(2));
      expect(player.calls, ['start:pink']); // the bed was left alone
    });

    test('the breaks picker swaps a playing nature bed', () async {
      await service.selectLoop(natureLoops.first);
      await service.play();
      await service.selectBreaksLoop(natureLoops.elementAt(3));
      expect(service.loop, natureLoops.elementAt(3));
      expect(player.calls.last, 'loop:${natureLoops.elementAt(3).asset}');
    });

    test('loop and breaks choices persist, playing does not', () async {
      await service.selectLoop(placeLoops.first);
      await service.selectBreaksLoop(natureLoops.elementAt(4));
      await service.play();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      service.debugReset();
      expect(service.loop, isNull);
      expect(service.playing, isFalse);
      await service.load();
      expect(service.loop, placeLoops.first);
      expect(service.breaksLoop, natureLoops.elementAt(4));
      expect(service.playing, isFalse);
    });
  });
}
