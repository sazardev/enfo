import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../ambient/music_catalog.dart';

/// A song's rhythm as loudness/onset strength, one byte per 1/[fps] second,
/// precomputed by tools/analyze_music.py. Sampled with the playback position
/// so the dial can move to the beat without listening to the audio.
class MusicEnvelope {
  const MusicEnvelope(this.data);

  static const fps = 20;

  final Uint8List data;

  /// Strength 0..1 at [position], interpolated between frames. Zero outside
  /// the song and for an empty envelope.
  double sample(Duration position) {
    if (data.isEmpty || position.isNegative) return 0;
    final f = position.inMicroseconds / Duration.microsecondsPerSecond * fps;
    final i = f.floor();
    if (i >= data.length) return 0;
    final frac = f - i;
    final a = data[i] / 255;
    final b = (i + 1 < data.length ? data[i + 1] : data[i]) / 255;
    return a + (b - a) * frac;
  }

  /// Where the envelope of [track] lives.
  static String assetOf(MusicTrack track) {
    final name = track.asset.split('/').last.replaceAll('.ogg', '.bin');
    return 'assets/music/envelopes/$name';
  }

  /// Null when the file is missing or unreadable: the dial then just runs
  /// at a steady pace.
  static Future<MusicEnvelope?> load(MusicTrack track,
      {AssetBundle? bundle}) async {
    try {
      final bytes = await (bundle ?? rootBundle).load(assetOf(track));
      return MusicEnvelope(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    } catch (_) {
      return null;
    }
  }
}

/// One step of exponential smoothing toward [target] over [dt] seconds:
/// quick to rise ([attack] seconds) and slower to fall ([release]).
double smoothToward(double current, double target, double dt,
    {double attack = 0.04, double release = 0.22}) {
  if (dt <= 0) return current;
  final tau = target > current ? attack : release;
  final k = 1 - math.exp(-dt / tau);
  return current + (target - current) * k;
}
