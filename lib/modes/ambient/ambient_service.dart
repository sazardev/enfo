import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clock/time_builder.dart';
import '../mode_services.dart';
import 'ambient_player.dart';
import 'ambient_synth.dart';
import 'music_catalog.dart';

/// Background sound with a sleep timer. Lives outside the page so the sound
/// keeps playing while another mode is on screen; the sleep timer is an
/// absolute timestamp checked on the host's one-second heartbeat.
///
/// Two independent voices can play together: the looping noise ("sound") and
/// a lo-fi song playlist ("music"), each with its own volume. The sleep
/// timer covers both and fades both out.
///
/// Persisted: the selected sound, the volume and the timer length, plus the
/// music volume, shuffle, repeat and last song. Whether
/// something is playing is deliberately NOT: the app never starts making
/// noise on its own at boot.
class AmbientService extends ChangeNotifier implements ModeService {
  AmbientService._();
  static final AmbientService instance = AmbientService._();

  static const _soundKey = 'ambient_sound';
  static const _volumeKey = 'ambient_volume';
  static const _sleepKey = 'ambient_sleep';
  static const _musicVolumeKey = 'ambient_music_volume';
  static const _musicShuffleKey = 'ambient_music_shuffle';
  static const _musicRepeatKey = 'ambient_music_repeat';
  static const _musicTrackKey = 'ambient_music_track';

  /// Sleep timer choices in minutes (0 = off).
  static const sleepChoices = [0, 15, 30, 45, 60, 90];

  /// How long the sound takes to fade out before the timer ends it.
  static const fadeOut = Duration(seconds: 10);

  /// The audio engine. Replaced by a fake in tests.
  AmbientPlayer player = SoloudAmbientPlayer();

  /// How a sound becomes WAV bytes. Replaced in tests to skip the isolate.
  Future<Uint8List> Function(AmbientSound) synth = AmbientSynth.renderWavAsync;

  AmbientSound sound = AmbientSound.pink;
  double volume = 0.6;
  int sleepMinutes = 0;

  bool playing = false;

  // ---- music
  double musicVolume = 0.6;
  bool shuffle = false;
  bool repeat = true;

  /// Index into [musicCatalog] of the current song.
  int musicIndex = 0;

  /// A song is sounding (not paused, not stopped).
  bool musicPlaying = false;

  /// A song was started and is paused: resuming continues it.
  bool musicPaused = false;
  bool musicPreparing = false;
  Duration musicPosition = Duration.zero;

  /// Source of randomness for shuffle; tests seed it.
  math.Random random = math.Random();

  int _musicGen = 0;
  List<int> _order = [];
  int _orderPos = 0;

  /// Live playback position of the song (the engine's clock).
  Duration get livePosition {
    if (!musicPlaying) return musicPosition;
    try {
      return player.musicPosition;
    } catch (_) {
      return musicPosition;
    }
  }

  /// Elapsed share of the running sleep timer, 0 when none runs.
  double get sleepProgress {
    final ends = _sleepEndsAt;
    if (!active || ends == null || sleepMinutes == 0) return 0;
    final total = sleepMinutes * 60000;
    final left = ends.difference(nowProvider()).inMilliseconds;
    return (1 - left / total).clamp(0.0, 1.0);
  }

  MusicTrack get track => musicCatalog[musicIndex];
  Duration get trackLength => Duration(seconds: track.seconds);

  /// Anything audible (or about to be).
  bool get active => playing || preparing || musicPlaying || musicPreparing;

  /// True while the buffer is being synthesized / the engine starts.
  bool preparing = false;

  /// The engine could not produce sound (plugin missing, no device).
  bool unavailable = false;

  DateTime? _sleepEndsAt;
  bool _fading = false;
  int _generation = 0;
  final Map<AmbientSound, Uint8List> _cache = {};

  DateTime? get sleepEndsAt => _sleepEndsAt;

  /// Time left until the sleep timer stops the sound; null when none runs.
  Duration? get sleepRemaining {
    final ends = _sleepEndsAt;
    if (!active || ends == null) return null;
    final left = ends.difference(nowProvider());
    return left.isNegative ? Duration.zero : left;
  }

  bool get fading => _fading;

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_soundKey);
    sound = AmbientSound.values
        .firstWhere((s) => s.name == name, orElse: () => AmbientSound.pink);
    volume = (prefs.getDouble(_volumeKey) ?? 0.6).clamp(0.0, 1.0);
    final sleep = prefs.getInt(_sleepKey) ?? 0;
    sleepMinutes = sleepChoices.contains(sleep) ? sleep : 0;
    musicVolume = (prefs.getDouble(_musicVolumeKey) ?? 0.6).clamp(0.0, 1.0);
    shuffle = prefs.getBool(_musicShuffleKey) ?? false;
    repeat = prefs.getBool(_musicRepeatKey) ?? true;
    final asset = prefs.getString(_musicTrackKey);
    final i = musicCatalog.indexWhere((t) => t.asset == asset);
    musicIndex = i < 0 ? 0 : i;
    _buildOrder(first: musicIndex);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, sound.name);
    await prefs.setDouble(_volumeKey, volume);
    await prefs.setInt(_sleepKey, sleepMinutes);
    await prefs.setDouble(_musicVolumeKey, musicVolume);
    await prefs.setBool(_musicShuffleKey, shuffle);
    await prefs.setBool(_musicRepeatKey, repeat);
    await prefs.setString(_musicTrackKey, track.asset);
  }

  // -------------------------------------------------------------- playback

  Future<void> play() async {
    if (playing || preparing) return;
    final wasActive = active;
    final gen = ++_generation;
    preparing = true;
    unavailable = false;
    notifyListeners();
    try {
      final wav = _cache[sound] ??= await synth(sound);
      if (gen != _generation) return;
      await player.start(sound.name, wav, volume);
      if (gen != _generation) {
        await player.stop();
        return;
      }
      playing = true;
      _startTimer(wasActive);
    } catch (_) {
      if (gen == _generation) unavailable = true;
    } finally {
      if (gen == _generation) preparing = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _generation++;
    final wasActive = playing || preparing;
    playing = false;
    preparing = false;
    _clearTimerIfIdle();
    notifyListeners();
    if (!wasActive) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> toggle() => playing || preparing ? stop() : play();

  /// Picks a sound; if one is playing it switches over immediately.
  Future<void> select(AmbientSound next) async {
    if (next == sound) return;
    sound = next;
    _save();
    final keepGoing = playing;
    final remaining = sleepRemaining;
    if (keepGoing) {
      await stop();
      await play();
      // A switch must not extend the sleep timer.
      if (playing && remaining != null) {
        _sleepEndsAt = nowProvider().add(remaining);
      }
    }
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v.clamp(0.0, 1.0);
    _cancelFade();
    _save();
    if (playing) _apply(() => player.setVolume(volume));
    notifyListeners();
  }

  void setMusicVolume(double v) {
    musicVolume = v.clamp(0.0, 1.0);
    _cancelFade();
    _save();
    if (musicPlaying) _apply(() => player.setMusicVolume(musicVolume));
    notifyListeners();
  }

  /// Ends a sleep fade-out: both voices go back to their own volume.
  void _cancelFade() {
    if (!_fading) return;
    _fading = false;
    if (playing) _apply(() => player.setVolume(volume));
    if (musicPlaying) _apply(() => player.setMusicVolume(musicVolume));
  }

  void _startTimer(bool wasActive) {
    _fading = false;
    if (wasActive && _sleepEndsAt != null) return; // already counting
    _sleepEndsAt = sleepMinutes > 0
        ? nowProvider().add(Duration(minutes: sleepMinutes))
        : null;
  }

  void _clearTimerIfIdle() {
    if (active) return;
    _fading = false;
    _sleepEndsAt = null;
  }

  /// Sets the sleep timer; while playing, it restarts from now.
  void setSleepMinutes(int minutes) {
    sleepMinutes = minutes;
    _save();
    if (active) {
      _sleepEndsAt =
          minutes > 0 ? nowProvider().add(Duration(minutes: minutes)) : null;
      if (_fading) {
        _fading = false;
        const back = Duration(seconds: 1);
        if (playing) _apply(() => player.setVolume(volume, fade: back));
        if (musicPlaying) {
          _apply(() => player.setMusicVolume(musicVolume, fade: back));
        }
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- music

  /// Order in which songs are visited: the catalog order, or a shuffled
  /// cycle that visits every song once before any repeats.
  void _buildOrder({required int first}) {
    final n = musicCatalog.length;
    final rest = [
      for (var i = 0; i < n; i++)
        if (i != first) i
    ];
    if (shuffle) rest.shuffle(random);
    _order = shuffle ? [first, ...rest] : [for (var i = 0; i < n; i++) i];
    _orderPos = shuffle ? 0 : first;
  }

  /// Starts (or continues) the current song.
  Future<void> playMusic() async {
    if (musicPlaying || musicPreparing) return;
    if (musicPaused) {
      final wasActive = active;
      try {
        await player.resumeMusic();
        musicPaused = false;
        musicPlaying = true;
        _startTimer(wasActive);
        unavailable = false;
      } catch (_) {
        unavailable = true;
        musicPaused = false;
      }
      notifyListeners();
      return;
    }
    await _startTrack();
  }

  Future<void> pauseMusic() async {
    if (!musicPlaying) return;
    musicPlaying = false;
    musicPaused = true;
    _clearTimerIfIdle();
    notifyListeners();
    try {
      await player.pauseMusic();
    } catch (_) {}
  }

  Future<void> toggleMusic() =>
      musicPlaying || musicPreparing ? pauseMusic() : playMusic();

  /// Stops the song and rewinds it; the playlist position stays.
  Future<void> stopMusic() async {
    _musicGen++;
    final wasActive = musicPlaying || musicPreparing || musicPaused;
    musicPlaying = false;
    musicPreparing = false;
    musicPaused = false;
    musicPosition = Duration.zero;
    _clearTimerIfIdle();
    notifyListeners();
    if (!wasActive) return;
    try {
      await player.stopMusic();
    } catch (_) {}
  }

  /// Stops everything (the sleep timer, the reset key).
  Future<void> stopAll() async {
    await Future.wait([stop(), stopMusic()]);
  }

  /// Plays catalog song [index] now. With shuffle on this begins a fresh
  /// cycle that starts with it.
  Future<void> playTrack(int index) async {
    if (index < 0 || index >= musicCatalog.length) return;
    musicIndex = index;
    _buildOrder(first: index);
    _save();
    await _startTrack();
  }

  /// Points the playlist at [index] without playing it. A paused or
  /// stopped song is dropped so the next play starts this one; a sounding
  /// song is left alone (the caller decides when to switch, see
  /// [playTrack]).
  Future<void> selectTrack(int index) async {
    if (index < 0 || index >= musicCatalog.length || index == musicIndex) {
      return;
    }
    musicIndex = index;
    _buildOrder(first: index);
    _save();
    if (musicPaused) {
      await stopMusic();
    } else {
      notifyListeners();
    }
  }

  Future<void> nextTrack() => _advance(1, auto: false);

  /// Restarts the song when it is well underway, otherwise steps back.
  Future<void> previousTrack() async {
    if (musicPlaying || musicPaused) {
      Duration pos = musicPosition;
      try {
        pos = player.musicPosition;
      } catch (_) {}
      if (pos > const Duration(seconds: 3)) {
        await _startTrack();
        return;
      }
    }
    await _advance(-1, auto: false);
  }

  Future<void> _advance(int step, {required bool auto}) async {
    final n = _order.length;
    if (n == 0) _buildOrder(first: musicIndex);
    var pos = _orderPos + step;
    if (pos >= _order.length) {
      if (auto && !repeat) {
        // End of the list and no repeat: rest on the first song.
        _orderPos = 0;
        musicIndex = _order.first;
        await stopMusic();
        return;
      }
      if (shuffle) {
        // New cycle; the song that just played must not open it again.
        final last = _order.last;
        _order = [for (var i = 0; i < musicCatalog.length; i++) i]
          ..shuffle(random);
        if (_order.length > 1 && _order.first == last) {
          _order.add(_order.removeAt(0));
        }
      }
      pos = 0;
    } else if (pos < 0) {
      pos = _order.length - 1;
    }
    _orderPos = pos;
    musicIndex = _order[pos];
    _save();
    await _startTrack();
  }

  Future<void> _startTrack() async {
    final wasActive = active;
    final gen = ++_musicGen;
    musicPreparing = true;
    musicPaused = false;
    musicPosition = Duration.zero;
    unavailable = false;
    notifyListeners();
    try {
      await player.startMusic(track.asset, musicVolume, () {
        if (gen == _musicGen) _advance(1, auto: true);
      });
      if (gen != _musicGen) {
        await player.stopMusic();
        return;
      }
      musicPlaying = true;
      _startTimer(wasActive);
    } catch (_) {
      if (gen == _musicGen) {
        unavailable = true;
        musicPlaying = false;
      }
    } finally {
      if (gen == _musicGen) musicPreparing = false;
      notifyListeners();
    }
  }

  void setShuffle(bool on) {
    if (on == shuffle) return;
    shuffle = on;
    _buildOrder(first: musicIndex);
    _save();
    notifyListeners();
  }

  void setRepeat(bool on) {
    repeat = on;
    _save();
    notifyListeners();
  }

  void _apply(Future<void> Function() call) {
    call().catchError((_) {});
  }

  @override
  void check() {
    if (!active) return;
    if (musicPlaying) {
      try {
        musicPosition = player.musicPosition;
      } catch (_) {}
    }
    final ends = _sleepEndsAt;
    if (ends == null) {
      if (musicPlaying) notifyListeners(); // the progress bar
      return;
    }
    final left = ends.difference(nowProvider());
    if (left <= Duration.zero) {
      stopAll();
      return;
    }
    if (left <= fadeOut && !_fading) {
      _fading = true;
      if (playing) _apply(() => player.setVolume(0, fade: left));
      if (musicPlaying) _apply(() => player.setMusicVolume(0, fade: left));
    }
    notifyListeners(); // the countdown on the page
  }

  /// Back to a clean slate (tests, and data reset).
  @visibleForTesting
  void debugReset() {
    _generation++;
    playing = false;
    preparing = false;
    unavailable = false;
    _fading = false;
    _sleepEndsAt = null;
    _musicGen++;
    musicPlaying = false;
    musicPaused = false;
    musicPreparing = false;
    musicPosition = Duration.zero;
    musicVolume = 0.6;
    shuffle = false;
    repeat = true;
    musicIndex = 0;
    random = math.Random();
    _buildOrder(first: 0);
    sound = AmbientSound.pink;
    volume = 0.6;
    sleepMinutes = 0;
    _cache.clear();
  }
}
