import 'package:audio_service/audio_service.dart';

import 'ambient_service.dart';
import 'music_catalog.dart';

/// The system media session behind the lock-screen player. It owns the
/// notification on Android and forwards every control to [AmbientService],
/// which keeps playing while the app is in the background.
class MusicHandler extends BaseAudioHandler {
  MusicHandler() {
    AmbientService.instance.attachHandler(this);
  }

  @override
  Future<void> play() => AmbientService.instance.playMusic();

  @override
  Future<void> pause() => AmbientService.instance.pauseMusic();

  @override
  Future<void> skipToNext() => AmbientService.instance.nextTrack();

  @override
  Future<void> skipToPrevious() => AmbientService.instance.previousTrack();

  @override
  Future<void> stop() async {
    await AmbientService.instance.stopMusic();
    await super.stop();
  }

  /// Pushes the current song and playback state to the system.
  void publish({
    required MusicTrack track,
    required bool playing,
    required bool paused,
    required Duration position,
    Uri? artUri,
  }) {
    final active = playing || paused;
    mediaItem.add(MediaItem(
      id: track.asset,
      title: track.title,
      artist: track.artist,
      album: 'Enfo',
      duration: Duration(seconds: track.seconds),
      artUri: artUri,
    ));
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: active
          ? AudioProcessingState.ready
          : AudioProcessingState.idle,
      playing: playing,
      updatePosition: position,
      bufferedPosition: position,
      speed: playing ? 1.0 : 0.0,
    ));
  }
}
