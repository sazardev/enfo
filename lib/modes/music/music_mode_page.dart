import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/design/responsive.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../../ui/clock/clock_frame.dart';
import '../ambient/ambient_service.dart';
import '../ambient/audio_dial.dart';
import '../ambient/music_catalog.dart';
import '../ambient/title_pager.dart';
import '../app_mode.dart';
import '../mode_keys.dart';
import '../mode_actions.dart';
import '../mode_scaffold.dart';
import 'music_envelope.dart';

/// Lo-fi songs, reduced to their titles: swipe to choose, the bottom-bar
/// button plays and pauses. Credits live in Settings.
class MusicModePage extends StatefulWidget {
  const MusicModePage({super.key});

  @override
  State<MusicModePage> createState() => _MusicModePageState();
}

class _MusicModePageState extends State<MusicModePage> {
  Timer? _debounce;
  final AudioDialController _dial = AudioDialController();
  MusicEnvelope? _envelope;
  int _envelopeFor = -1;

  @override
  void initState() {
    super.initState();
    _loadEnvelope();
    AmbientService.instance.addListener(_loadEnvelope);
  }

  /// Keeps the rhythm envelope in step with the current song.
  void _loadEnvelope() {
    final s = AmbientService.instance;
    final i = s.musicIndex;
    if (i == _envelopeFor) return;
    _envelopeFor = i;
    _envelope = null;
    MusicEnvelope.load(musicCatalog[i]).then((e) {
      if (mounted && _envelopeFor == i) _envelope = e;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    AmbientService.instance.removeListener(_loadEnvelope);
    super.dispose();
  }

  /// A song landed in the middle. While playing, switch to it once the
  /// swipe settles so fast flicks do not start every song they pass.
  void _picked(int i) {
    final s = AmbientService.instance;
    _debounce?.cancel();
    if (i == s.musicIndex) return; // the pager following an auto-advance
    if (s.musicPlaying || s.musicPreparing) {
      _debounce = Timer(const Duration(milliseconds: 250), () {
        AmbientService.instance.playTrack(i);
      });
    } else {
      s.selectTrack(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AmbientService.instance;
    final l10n = context.l10n;
    final r = Responsive.of(context);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final running = service.musicPlaying || service.musicPreparing;
        return ModeKeyBindings(
          mode: AppMode.music,
          actions: ModeKeyActions(
            primary: service.toggleMusic,
            reset: service.stopMusic,
          ),
          child: ModeScaffold(
            actions: [ClockStyleButton(onReturn: _dial.reload)],
            primaryAction: PrimaryActionButton(
              running: running,
              label: running ? l10n.ambientMusicPause : l10n.ambientMusicPlay,
              onPressed: service.toggleMusic,
            ),
            body: Column(
              children: [
                Expanded(
                  child: AudioDial(
                    controller: _dial,
                    playing: service.musicPlaying,
                    phase: service.musicPlaying
                        ? ClockPhase.running
                        : service.musicPaused
                            ? ClockPhase.paused
                            : ClockPhase.idle,
                    totalSeconds: service.track.seconds,
                    progress: () => service.trackLength.inMilliseconds == 0
                        ? 0
                        : (service.livePosition.inMilliseconds /
                                service.trackLength.inMilliseconds)
                            .clamp(0.0, 1.0),
                    energy: () => _envelope?.sample(service.livePosition) ?? 0,
                    baseRate: 0.5,
                    energyGain: 2.5,
                    pulse: true,
                  ),
                ),
                SizedBox(
                  height: r.isWatch ? 44 : 92,
                  child: TitlePager(
                    onVertical: _dial.stepStyle,
                    titles: [for (final t in musicCatalog) t.title],
                    index: service.musicIndex,
                    onChanged: _picked,
                    fontSize: r.isWatch ? 16 : 32,
                  ),
                ),
                SizedBox(
                  height: 20,
                  child: service.unavailable
                      ? Text(l10n.ambientUnavailable,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
