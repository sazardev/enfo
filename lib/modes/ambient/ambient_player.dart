import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// What the ambient mode needs from an audio engine. The app talks to this
/// interface only, so tests use a fake and a platform where the plugin is
/// missing degrades to an "unavailable" hint instead of crashing.
abstract interface class AmbientPlayer {
  /// Starts looping [wav] (a complete WAV file) at [volume] (0..1), replacing
  /// whatever plays. Throws if audio cannot be produced.
  Future<void> start(String id, Uint8List wav, double volume);

  /// Starts looping the bundled Ogg [asset] at [volume], streamed from disk
  /// (a recorded ambience loop is minutes long decoded). Replaces whatever
  /// plays. Throws if audio cannot be produced.
  Future<void> startAsset(String id, String asset, double volume);

  /// Sets the volume, gliding there over [fade] when given.
  Future<void> setVolume(double volume, {Duration fade = Duration.zero});

  Future<void> stop();

  // ------------------------------------------------------------ music
  // A second, independent voice: a bundled song played once (not looped),
  // mixed with whatever [start] plays, with its own volume.

  /// Plays the asset [asset] once at [volume], replacing the current song.
  /// [onEnded] runs when the song reaches its end by itself (not when it is
  /// stopped or replaced). Throws if audio cannot be produced.
  Future<void> startMusic(String asset, double volume, void Function() onEnded);

  Future<void> pauseMusic();
  Future<void> resumeMusic();

  Future<void> setMusicVolume(double volume, {Duration fade = Duration.zero});

  Future<void> stopMusic();

  /// How far into the current song we are (zero when none).
  Duration get musicPosition;
}

/// SoLoud (miniaudio) engine. Chosen over audioplayers / just_audio because
/// it needs no system media framework (GStreamer on Linux, extra platform
/// packages for just_audio on desktop) and loops a memory buffer gaplessly,
/// which noise needs: a gap or click every few seconds would ruin it.
class SoloudAmbientPlayer implements AmbientPlayer {
  AudioSource? _source;
  SoundHandle? _handle;

  AudioSource? _musicSource;
  SoundHandle? _musicHandle;
  StreamSubscription<void>? _musicEnd;

  SoLoud get _engine => SoLoud.instance;

  @override
  Future<void> start(String id, Uint8List wav, double volume) async {
    if (!_engine.isInitialized) {
      await _engine.init();
    }
    await stop();
    final source = await _engine.loadMem('ambient_$id.wav', wav);
    _source = source;
    _handle = _engine.play(source, volume: volume, looping: true);
  }

  @override
  Future<void> startAsset(String id, String asset, double volume) async {
    if (!_engine.isInitialized) {
      await _engine.init();
    }
    await stop();
    final source = await _engine.loadAsset(asset, mode: LoadMode.disk);
    _source = source;
    _handle = _engine.play(source, volume: volume, looping: true);
  }

  @override
  Future<void> setVolume(double volume, {Duration fade = Duration.zero}) async {
    final handle = _handle;
    if (handle == null || !_engine.isInitialized) return;
    if (fade > Duration.zero) {
      _engine.fadeVolume(handle, volume, fade);
    } else {
      _engine.setVolume(handle, volume);
    }
  }

  @override
  Future<void> stop() async {
    final handle = _handle;
    final source = _source;
    _handle = null;
    _source = null;
    if (!_engine.isInitialized) return;
    try {
      if (handle != null) await _engine.stop(handle);
      if (source != null) await _engine.disposeSource(source);
    } catch (_) {
      // Already gone (engine restarted): nothing left to release.
    }
  }

  // ------------------------------------------------------------ music

  @override
  Future<void> startMusic(
      String asset, double volume, void Function() onEnded) async {
    if (!_engine.isInitialized) {
      await _engine.init();
    }
    await stopMusic();
    // Streamed from disk: a decoded 3-minute song would be tens of MB.
    final source = await _engine.loadAsset(asset, mode: LoadMode.disk);
    _musicSource = source;
    _musicEnd = source.allInstancesFinished.listen((_) {
      if (identical(_musicSource, source)) onEnded();
    });
    _musicHandle = _engine.play(source, volume: volume);
  }

  @override
  Future<void> pauseMusic() async {
    final h = _musicHandle;
    if (h != null && _engine.isInitialized) _engine.setPause(h, true);
  }

  @override
  Future<void> resumeMusic() async {
    final h = _musicHandle;
    if (h != null && _engine.isInitialized) _engine.setPause(h, false);
  }

  @override
  Future<void> setMusicVolume(double volume,
      {Duration fade = Duration.zero}) async {
    final h = _musicHandle;
    if (h == null || !_engine.isInitialized) return;
    if (fade > Duration.zero) {
      _engine.fadeVolume(h, volume, fade);
    } else {
      _engine.setVolume(h, volume);
    }
  }

  @override
  Future<void> stopMusic() async {
    final handle = _musicHandle;
    final source = _musicSource;
    final end = _musicEnd;
    _musicHandle = null;
    _musicSource = null;
    _musicEnd = null;
    await end?.cancel();
    if (!_engine.isInitialized) return;
    try {
      if (handle != null) await _engine.stop(handle);
      if (source != null) await _engine.disposeSource(source);
    } catch (_) {}
  }

  @override
  Duration get musicPosition {
    final h = _musicHandle;
    if (h == null || !_engine.isInitialized) return Duration.zero;
    try {
      return _engine.getPosition(h);
    } catch (_) {
      return Duration.zero;
    }
  }
}
