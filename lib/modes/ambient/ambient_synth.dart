import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// The sounds Enfo can make. All of them are synthesized from noise at
/// runtime: no audio assets ship with the app.
enum AmbientSound { white, pink, brown, rain, wind, ocean }

/// Builds seamlessly looping mono WAV buffers for [AmbientSound]s.
///
/// Every sound is rendered a crossfade longer than the loop and its tail is
/// folded (equal power) into its head, so the end continues into the start
/// with no click and no dip in level. Slow modulations use a whole number of
/// cycles per loop for the same reason.
abstract final class AmbientSynth {
  static const sampleRate = 22050;
  static const loopSeconds = 12;
  static const _crossfadeSeconds = 1;

  /// Renders the WAV file bytes off the UI thread.
  static Future<Uint8List> renderWavAsync(AmbientSound sound) =>
      compute(_renderWavIsolate, sound.index);

  static Uint8List _renderWavIsolate(int index) =>
      wav(render(AmbientSound.values[index]));

  /// One loop of [sound] as 16-bit PCM. Deterministic for a given [seed].
  static Int16List render(
    AmbientSound sound, {
    int seconds = loopSeconds,
    int rate = sampleRate,
    int seed = 7,
  }) {
    final n = seconds * rate;
    final fade = _crossfadeSeconds * rate;
    final rng = math.Random(seed + sound.index);
    final raw = switch (sound) {
      AmbientSound.white => _white(n + fade, rng),
      AmbientSound.pink => _pink(n + fade, rng),
      AmbientSound.brown => _brown(n + fade, rng),
      AmbientSound.rain => _rain(n + fade, rate, rng),
      AmbientSound.wind => _wind(n + fade, rate, seconds, rng),
      AmbientSound.ocean => _ocean(n + fade, rate, seconds, rng),
    };

    // Fold the tail into the head.
    final loop = Float64List(n);
    for (var i = 0; i < n; i++) {
      if (i < fade) {
        final t = math.pi / 2 * (i / fade);
        loop[i] = raw[n + i] * math.cos(t) + raw[i] * math.sin(t);
      } else {
        loop[i] = raw[i];
      }
    }

    // Even loudness across sounds (RMS), soft-clipped so peaks never wrap.
    var sum = 0.0;
    for (final v in loop) {
      sum += v * v;
    }
    final rms = math.sqrt(sum / n);
    final gain = rms == 0 ? 0.0 : _targetRms(sound) / rms;
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final v = _tanh(loop[i] * gain);
      out[i] = (v * 32000).round();
    }
    return out;
  }

  static double _targetRms(AmbientSound s) => switch (s) {
        AmbientSound.white => .16,
        AmbientSound.pink => .2,
        AmbientSound.brown => .24,
        AmbientSound.rain => .2,
        AmbientSound.wind => .22,
        AmbientSound.ocean => .22,
      };

  static double _tanh(double x) {
    if (x > 8) return 1;
    if (x < -8) return -1;
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  /// Wraps 16-bit mono PCM in a WAV container.
  static Uint8List wav(Int16List pcm, {int rate = sampleRate}) {
    final dataLen = pcm.length * 2;
    final bytes = ByteData(44 + dataLen);
    void tag(int offset, String s) {
      for (var i = 0; i < 4; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLen, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    bytes.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      bytes.setInt16(44 + i * 2, pcm[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  // ------------------------------------------------------------ generators

  static Float64List _white(int n, math.Random rng) {
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextDouble() * 2 - 1;
    }
    return out;
  }

  /// Paul Kellet's economy pink filter.
  static Float64List _pink(int n, math.Random rng) {
    final out = Float64List(n);
    var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0;
    for (var i = 0; i < n; i++) {
      final w = rng.nextDouble() * 2 - 1;
      b0 = .99886 * b0 + w * .0555179;
      b1 = .99332 * b1 + w * .0750759;
      b2 = .96900 * b2 + w * .1538520;
      b3 = .86650 * b3 + w * .3104856;
      b4 = .55000 * b4 + w * .5329522;
      b5 = -.7616 * b5 - w * .0168980;
      out[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * .5362) * .11;
      b6 = w * .115926;
    }
    return out;
  }

  static Float64List _brown(int n, math.Random rng) {
    final out = Float64List(n);
    var last = 0.0;
    for (var i = 0; i < n; i++) {
      final w = rng.nextDouble() * 2 - 1;
      last = (last + .02 * w) / 1.02;
      out[i] = last * 3.5;
    }
    return out;
  }

  /// A steady hiss plus random droplets (short damped sine bursts).
  static Float64List _rain(int n, int rate, math.Random rng) {
    final out = Float64List(n);
    // Hiss: white noise with the lows taken out, plus a faint rumble.
    var lp = 0.0, rumble = 0.0;
    for (var i = 0; i < n; i++) {
      final w = rng.nextDouble() * 2 - 1;
      lp = lp * .93 + w * .07; // one-pole low-pass
      final high = w - lp; // what is left is the top end
      rumble = rumble * .999 + w * .001;
      out[i] = high * .35 + rumble * 1.5;
    }
    // Drops.
    final drops = (n / rate * 55).round();
    for (var d = 0; d < drops; d++) {
      final start = rng.nextInt(n);
      final freq = 1500 + rng.nextDouble() * 4500;
      final tau = (.002 + rng.nextDouble() * .006) * rate;
      final amp = math.pow(rng.nextDouble(), 2) * .9 + .05;
      final len = (tau * 6).round();
      for (var k = 0; k < len && start + k < n; k++) {
        out[start + k] +=
            amp * math.exp(-k / tau) * math.sin(2 * math.pi * freq * k / rate);
      }
    }
    return out;
  }

  /// Pink noise through a resonant band-pass whose centre drifts slowly.
  static Float64List _wind(int n, int rate, int seconds, math.Random rng) {
    final src = _pink(n, rng);
    final out = Float64List(n);
    var low = 0.0, band = 0.0;
    const q = .35;
    for (var i = 0; i < n; i++) {
      final t = i / rate / seconds; // 0..1 across a loop
      final drift = .5 +
          .3 * math.sin(2 * math.pi * 2 * t) +
          .2 * math.sin(2 * math.pi * 5 * t + 1.3);
      final fc = 250 + 700 * drift;
      final f = 2 * math.sin(math.pi * fc / rate);
      low += f * band;
      final high = src[i] - low - q * band;
      band += f * high;
      final gust = .45 + .55 * (.5 + .5 * math.sin(2 * math.pi * 3 * t + .6));
      out[i] = band * gust;
    }
    return out;
  }

  /// Low rumble swelling and receding like waves, with foam on the crest.
  static Float64List _ocean(int n, int rate, int seconds, math.Random rng) {
    final brown = _brown(n, rng);
    final out = Float64List(n);
    final waves = math.max(1, (seconds / 6).round());
    var foam = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / rate / seconds;
      final swell = math.pow(.5 + .5 * math.sin(2 * math.pi * waves * t), 2);
      final crest =
          math.pow(.5 + .5 * math.sin(2 * math.pi * waves * t - .8), 3);
      final w = rng.nextDouble() * 2 - 1;
      foam = foam * .85 + w * .15;
      out[i] = brown[i] * (.25 + .75 * swell) + (w - foam) * .35 * crest;
    }
    return out;
  }
}
