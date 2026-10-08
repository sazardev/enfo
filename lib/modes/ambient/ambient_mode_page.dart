import 'dart:async';

import 'package:flutter/material.dart';

import '../../haptics/haptics.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_actions.dart';
import '../mode_scaffold.dart';
import 'ambient_service.dart';
import 'ambient_synth.dart';
import 'ambience_catalog.dart';
import 'ambience_labels.dart';
import '../../ui/clock/clock_frame.dart';
import 'audio_dial.dart';
import 'title_pager.dart';

extension AmbientSoundUi on AmbientSound {
  String label(AppLocalizations l10n) => switch (this) {
        AmbientSound.white => l10n.ambientWhite,
        AmbientSound.pink => l10n.ambientPink,
        AmbientSound.brown => l10n.ambientBrown,
        AmbientSound.rain => l10n.ambientRain,
        AmbientSound.wind => l10n.ambientWind,
        AmbientSound.ocean => l10n.ambientOcean,
      };
}

/// Background sounds, reduced to their names: swipe to choose, the bottom-bar
/// button plays and stops. One quiet line cycles the sleep timer. The sound
/// belongs to [AmbientService], so it keeps going in other modes.
class AmbientModePage extends StatefulWidget {
  const AmbientModePage({super.key});

  @override
  State<AmbientModePage> createState() => _AmbientModePageState();
}

class _AmbientModePageState extends State<AmbientModePage> {
  Timer? _debounce;
  final AudioDialController _dial = AudioDialController();

  /// The synthesized noises first, then the recorded place loops.
  static final List<Object> _entries = [
    ...AmbientSound.values,
    ...placeLoops,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  static String _label(Object entry, AppLocalizations l10n) =>
      entry is AmbientSound ? entry.label(l10n) : (entry as AmbienceLoop).label(l10n);

  void _picked(int i) {
    final s = AmbientService.instance;
    _debounce?.cancel();
    final next = _entries[i];
    if (next is AmbientSound) {
      if (next == s.sound && s.loop == null) return;
    } else if (next == s.loop) {
      return;
    }
    void apply() {
      if (next is AmbientSound) {
        s.select(next);
      } else {
        s.selectLoop(next as AmbienceLoop);
      }
    }

    if (s.playing || s.preparing) {
      _debounce = Timer(const Duration(milliseconds: 250), apply);
    } else {
      apply();
    }
  }

  static int _indexOf(AmbientService s) {
    if (s.loop != null) {
      final i = _entries.indexOf(s.loop!);
      if (i >= 0) return i;
    }
    return s.sound.index;
  }

  @override
  Widget build(BuildContext context) {
    final service = AmbientService.instance;
    final l10n = context.l10n;
    final r = Responsive.of(context);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final running = service.playing || service.preparing;
        return ModeKeyBindings(
          mode: AppMode.ambient,
          actions:
              ModeKeyActions(primary: service.toggle, reset: service.stopAll),
          child: ModeScaffold(
            actions: [ClockStyleButton(onReturn: _dial.reload)],
            primaryAction: PrimaryActionButton(
              running: running,
              label: running ? l10n.ambientStop : l10n.ambientPlay,
              onPressed: service.toggle,
            ),
            body: Column(
              children: [
                Expanded(
                  child: AudioDial(
                    controller: _dial,
                    playing: service.playing,
                    phase:
                        service.playing ? ClockPhase.running : ClockPhase.idle,
                    totalSeconds: service.sleepMinutes * 60,
                    progress: () => service.sleepProgress,
                    baseRate: 0.6,
                  ),
                ),
                SizedBox(
                  height: r.isWatch ? 44 : 92,
                  child: TitlePager(
                    onVertical: _dial.stepStyle,
                    titles: [
                      for (final e in _entries) _label(e, l10n)
                    ],
                    index: _indexOf(service),
                    onChanged: _picked,
                    fontSize: r.isWatch ? 18 : 32,
                  ),
                ),
                _SleepLine(service: service),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Off" / "30 min" (or the time left while playing); tap for the next.
class _SleepLine extends StatelessWidget {
  const _SleepLine({required this.service});

  final AmbientService service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final m = service.sleepMinutes;
    final left = service.sleepRemaining;
    final String text = service.unavailable
        ? l10n.ambientUnavailable
        : left != null
            ? l10n.ambientTimeLeft(formatCountdown(left.inSeconds))
            : m == 0
                ? l10n.ambientTimerOff
                : l10n.minutes(m);
    return Semantics(
      button: true,
      label: '${l10n.ambientSleepTimer}: $text',
      child: ExcludeSemantics(
        child: BouncyTap(
          onTap: () {
            Haptics.select();
            const c = AmbientService.sleepChoices;
            service.setSleepMinutes(c[(c.indexOf(m) + 1) % c.length]);
          },
          focusBorderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: service.unavailable
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
