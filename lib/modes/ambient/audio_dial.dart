import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/clock/clock_frame.dart';
import '../../ui/clock/clock_style.dart';
import '../../ui/clock/clock_view.dart';
import '../../ui/design/motion.dart';
import '../music/music_envelope.dart';

/// Lets the page (whose pager owns the keyboard focus) step the design.
class AudioDialController {
  void Function(int delta)? _step;

  /// Next (+1) or previous (-1) clock design.
  void stepStyle(int delta) => _step?.call(delta);

  void Function()? _reload;

  /// Re-read the saved design (after the style page changed it).
  void reload() => _reload?.call();
}

/// The visual of the sound and music modes: one of the app's clock designs
/// (the same one the other modes use). Swipe it up or down, or press the
/// up / down arrows, to change the design; the choice is shared and saved.
///
/// While [playing] a ticker feeds it every frame:
///  * progress comes from [progress] (song position or sleep timer),
///  * the animation clock advances at [baseRate] plus [energyGain] times the
///    current [energy] (0..1, the song's rhythm), so animated designs speed
///    up and slow down with the music,
///  * with [pulse], the whole dial swells up to 5% on the beat.
/// Paused or stopped, everything is frozen. With reduced motion only the
/// progress moves.
class AudioDial extends StatefulWidget {
  const AudioDial({
    super.key,
    required this.playing,
    required this.phase,
    required this.totalSeconds,
    required this.progress,
    this.energy,
    this.baseRate = 0.5,
    this.energyGain = 0,
    this.pulse = false,
    this.controller,
  });

  final AudioDialController? controller;

  final bool playing;
  final ClockPhase phase;
  final int totalSeconds;
  final double Function() progress;
  final double Function()? energy;
  final double baseRate;
  final double energyGain;
  final bool pulse;

  @override
  State<AudioDial> createState() => _AudioDialState();
}

class _Live {
  const _Live(this.progress, this.time, this.pulse);
  final double progress;
  final double time;
  final double pulse;
}

class _AudioDialState extends State<AudioDial>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<_Live> _live = ValueNotifier(const _Live(0, 0, 0));
  ClockStyle _style = ClockStyle.ring;
  Duration _last = Duration.zero;
  double _time = 0;
  double _pulse = 0;

  @override
  void initState() {
    super.initState();
    _live.value = _Live(widget.progress(), 0, 0);
    ClockStyle.load().then((s) {
      if (mounted) setState(() => _style = s);
    });
    widget.controller?._step = _setStyle;
    widget.controller?._reload = _reloadStyle;
    _sync();
  }

  @override
  void didUpdateWidget(AudioDial old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._step = null;
      old.controller?._reload = null;
      widget.controller?._step = _setStyle;
      widget.controller?._reload = _reloadStyle;
    }
    _sync();
    if (!widget.playing) _live.value = _Live(widget.progress(), _time, 0);
  }

  void _reloadStyle() {
    ClockStyle.load().then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  void _sync() {
    if (widget.playing && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!widget.playing && _ticker.isActive) {
      _ticker.stop();
      _pulse = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final dt =
        (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    final still = MediaQuery.disableAnimationsOf(context);
    var e = 0.0;
    if (!still) {
      e = (widget.energy?.call() ?? 0).clamp(0.0, 1.0);
      _time += dt * (widget.baseRate + widget.energyGain * e);
      _pulse = widget.pulse ? smoothToward(_pulse, e, dt) : 0;
    }
    _live.value = _Live(widget.progress(), _time, _pulse);
  }

  void _setStyle(int delta) {
    final next = _style.step(delta);
    setState(() => _style = next);
    ClockStyle.save(next);
  }

  @override
  void dispose() {
    widget.controller?._step = null;
    _ticker.dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ClockLabels.of(context.l10n);
    final palette = ClockPalette.of(
      Theme.of(context).colorScheme,
      rest: false,
      paused: widget.phase == ClockPhase.paused,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 300) return;
        _setStyle(v < 0 ? 1 : -1);
      },
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Motion.medium,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(a),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_style),
          child: ValueListenableBuilder<_Live>(
            valueListenable: _live,
            builder: (context, live, _) => Transform.scale(
              scale: 1 + 0.05 * live.pulse,
              child: ClockView(
                style: _style,
                fill: 0.9,
                palette: palette,
                frame: ClockFrame(
                  progress: live.progress,
                  totalSeconds: widget.totalSeconds,
                  phase: widget.phase,
                  time: live.time,
                  labels: labels,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
