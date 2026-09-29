import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/clock/clock_frame.dart';
import '../../ui/clock/clock_style.dart';
import '../../ui/clock/clock_view.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../format.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../fullscreen.dart';
import '../app_mode.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import 'duration_wheels.dart';
import 'timer_controller.dart';

/// Countdown timer: spin the wheels (or tap a preset), press start. While
/// it runs it is drawn with the same clock designs as the Pomodoro timer.
class TimerModePage extends StatefulWidget {
  const TimerModePage({super.key});

  @override
  State<TimerModePage> createState() => _TimerModePageState();
}

class _TimerModePageState extends State<TimerModePage>
    with TickerProviderStateMixin {
  final TimerController _timer = TimerController.instance;

  /// What the clock face reads. Updated every frame while running.
  late final AnimationController _progress = AnimationController(vsync: this);
  Ticker? _ticker;
  ClockStyle _style = ClockStyle.ring;

  @override
  void initState() {
    super.initState();
    _timer.addListener(_sync);
    _sync();
    ClockStyle.load().then((style) {
      if (mounted) setState(() => _style = style);
    });
  }

  void _sync() {
    if (_timer.running) {
      _ticker ??= createTicker((_) {
        _progress.value = _timer.progress;
        _timer.check();
      })
        ..start();
    } else {
      _ticker?.dispose();
      _ticker = null;
    }
    _progress.value = _timer.progress;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.removeListener(_sync);
    _ticker?.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final style = _style.step(velocity < 0 ? 1 : -1);
    setState(() => _style = style);
    ClockStyle.save(style);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phase = _timer.phase;
    return ModeKeyBindings(
      mode: AppMode.timer,
      actions: ModeKeyActions(
        primary: () {
          if (_timer.running) {
            _timer.pause();
          } else if (_timer.phase != TimerPhase.idle ||
              _timer.totalSeconds > 0) {
            _timer.start();
          }
        },
        reset: _timer.reset,
      ),
      child: ModeScaffold(
        primaryAction: PrimaryActionButton(
          running: _timer.running,
          label: switch (phase) {
            TimerPhase.idle => l10n.timerStart,
            TimerPhase.running => l10n.timerPause,
            TimerPhase.paused => l10n.timerResume,
          },
          onPressed: _timer.running ? _timer.pause : _timer.start,
          enabled: phase != TimerPhase.idle || _timer.totalSeconds > 0,
        ),
        body: phase == TimerPhase.idle ? _idle(context) : _active(context),
      ),
    );
  }

  // ------------------------------------------------------------------ idle

  Widget _idle(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);

    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxHeight < 440;
      final showPresets = !compact && !r.isWatch;
      return Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.isWatch ? 200 : 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DurationWheels(
                  totalSeconds: _timer.totalSeconds,
                  itemExtent: r.isWatch ? 28 : (compact ? 48 : 64),
                  onChanged: _timer.setTotal,
                ),
                if (showPresets) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in _timer.presets)
                        _PresetChip(
                          label: formatDuration(p),
                          selected: p == _timer.totalSeconds,
                          onTap: () => _timer.setTotal(p),
                          onLongPress: () => _timer.removePreset(p),
                        ),
                      if (_timer.totalSeconds > 0 &&
                          !_timer.presets.contains(_timer.totalSeconds))
                        AppIconButton(
                          size: 40,
                          tooltip: l10n.timerSavePreset,
                          onPressed: () =>
                              _timer.addPreset(_timer.totalSeconds),
                          icon: const Icon(Icons.add_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.timerPresetHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------- active

  Widget _active(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final paused = _timer.phase == TimerPhase.paused;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _swipe,
            child: LiveClockView(
              style: _style,
              progress: _progress,
              totalSeconds: _timer.totalSeconds,
              isRest: false,
              phase: paused ? ClockPhase.paused : ClockPhase.running,
              wordMode: false,
            ),
          ),
        ),
        // In full screen the visual stands alone; tap reveals the chrome.
        ValueListenableBuilder<bool>(
          valueListenable: Fullscreen.active,
          builder: (context, full, _) => full
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconButton(
                        tooltip: l10n.timerReset,
                        onPressed: _timer.reset,
                        icon: const Icon(Icons.stop_rounded),
                      ),
                      SizedBox(width: r.isWatch ? 4 : AppSpacing.md),
                      if (!r.isWatch)
                        AppIconButton(
                          tooltip: l10n.timerAddMinute,
                          onPressed: () => _timer.addSeconds(60),
                          icon: const Icon(Icons.add_rounded),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BouncyTap(
      onTap: onTap,
      onLongPress: onLongPress,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
