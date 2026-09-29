import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/clock/clock_frame.dart';
import '../../ui/clock/clock_style.dart';
import '../../ui/clock/clock_view.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../format.dart';
import '../fullscreen.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import '../timer/duration_wheels.dart';
import 'interval_plan.dart';
import 'intervals_service.dart';

/// HIIT / interval trainer: pick a preset or edit the plan, press start. The
/// dial is drawn with the chosen clock style and follows the current phase.
class IntervalsModePage extends StatefulWidget {
  const IntervalsModePage({super.key});

  @override
  State<IntervalsModePage> createState() => _IntervalsModePageState();
}

enum _Field { warmUp, work, rest, coolDown }

class _IntervalsModePageState extends State<IntervalsModePage>
    with TickerProviderStateMixin {
  final IntervalsService _svc = IntervalsService.instance;
  late final AnimationController _progress = AnimationController(vsync: this);
  Ticker? _ticker;
  ClockStyle _style = ClockStyle.ring;
  _Field? _editing;
  int _shownSecond = -1;
  int _shownSegment = -1;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_sync);
    _sync();
    ClockStyle.load().then((style) {
      if (mounted) setState(() => _style = style);
    });
  }

  void _sync() {
    if (_svc.running) {
      _ticker ??= createTicker(_onFrame)..start();
    } else {
      _ticker?.dispose();
      _ticker = null;
    }
    _progress.value = _svc.phaseProgress;
    if (mounted) setState(() {});
  }

  void _onFrame(Duration _) {
    _progress.value = _svc.phaseProgress;
    final sec = (_svc.segmentRemainingMs / 1000).ceil();
    final seg = _svc.segment?.startMs ?? -1;
    if (sec != _shownSecond || seg != _shownSegment) {
      _shownSecond = sec;
      _shownSegment = seg;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_sync);
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
    final status = _svc.status;
    return ModeKeyBindings(
      mode: AppMode.intervals,
      actions: ModeKeyActions(primary: _svc.toggle, reset: _svc.reset),
      child: ModeScaffold(
        primaryAction: PrimaryActionButton(
          running: _svc.running,
          label: switch (status) {
            IntervalStatus.idle => l10n.timerStart,
            IntervalStatus.running => l10n.timerPause,
            IntervalStatus.paused => l10n.timerResume,
          },
          onPressed: _svc.toggle,
          enabled: status != IntervalStatus.idle || _svc.plan.isValid,
        ),
        body: status == IntervalStatus.idle ? _idle(context) : _active(context),
      ),
    );
  }

  // ------------------------------------------------------------------ idle

  Widget _idle(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final plan = _svc.plan;

    final presets = Wrap(
      alignment: WrapAlignment.center,
      spacing: r.isWatch ? AppSpacing.xs : AppSpacing.sm,
      runSpacing: r.isWatch ? AppSpacing.xs : AppSpacing.sm,
      children: [
        for (final p in IntervalPreset.values)
          _Chip(
            label: p.label(l10n),
            selected: p == _svc.preset,
            dense: r.isWatch,
            onTap: () => setState(() {
              _editing = null;
              _svc.selectPreset(p);
            }),
          ),
      ],
    );

    final summary = Text(
      '${plan.rounds} × ${formatDuration(plan.work)}'
      '${plan.rest > 0 ? ' / ${formatDuration(plan.rest)}' : ''}'
      ' · ${l10n.intervalsTotal(formatDuration(plan.totalSeconds))}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
    );

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.isWatch ? 200 : 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              presets,
              const SizedBox(height: AppSpacing.md),
              if (r.isWatch)
                summary
              else ...[
                _timeRow(_Field.warmUp, l10n.intervalsWarmUp, plan.warmUp),
                _timeRow(_Field.work, l10n.intervalsWork, plan.work),
                _timeRow(_Field.rest, l10n.intervalsRest, plan.rest),
                _roundsRow(plan),
                _timeRow(
                    _Field.coolDown, l10n.intervalsCoolDown, plan.coolDown),
                const SizedBox(height: AppSpacing.md),
                summary,
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.intervalsHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IntervalPlan _with(IntervalPlan p, _Field f, int v) => switch (f) {
        _Field.warmUp => p.copyWith(warmUp: v),
        _Field.work => p.copyWith(work: v < 1 ? 1 : v),
        _Field.rest => p.copyWith(rest: v),
        _Field.coolDown => p.copyWith(coolDown: v),
      };

  Widget _timeRow(_Field field, String label, int seconds) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final open = _editing == field;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: open ? scheme.surfaceContainerHigh : Colors.transparent,
          borderRadius: AppRadii.mdRadius,
        ),
        child: Column(
          children: [
            BouncyTap(
              onTap: () => setState(() => _editing = open ? null : field),
              pressedScale: 0.98,
              focusBorderRadius: AppRadii.mdRadius,
              child: _RowFace(
                label: label,
                value:
                    seconds == 0 ? l10n.intervalsOff : formatDuration(seconds),
                highlighted: open,
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: DurationWheels(
                  key: ValueKey(field),
                  totalSeconds: seconds,
                  itemExtent: 40,
                  onChanged: (v) => _svc.edit(_with(_svc.plan, field, v)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundsRow(IntervalPlan plan) {
    final l10n = context.l10n;
    void set(int n) =>
        _svc.edit(plan.copyWith(rounds: n.clamp(1, IntervalPlan.maxRounds)));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child:
                _RowFace(label: l10n.intervalsRounds, value: '${plan.rounds}'),
          ),
          AppIconButton(
            size: 40,
            tooltip: '-',
            onPressed: plan.rounds > 1 ? () => set(plan.rounds - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            size: 40,
            tooltip: '+',
            onPressed: plan.rounds < IntervalPlan.maxRounds
                ? () => set(plan.rounds + 1)
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- active

  Widget _active(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final seg = _svc.segment;
    if (seg == null) return const SizedBox.shrink();
    final plan = _svc.activePlan;
    final paused = _svc.status == IntervalStatus.paused;
    final remaining = (_svc.segmentRemainingMs / 1000).ceil();
    final color = seg.kind.isRest ? scheme.tertiary : scheme.primary;

    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxHeight < 420 || r.isWatch;
      final labelStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: r.isWatch ? 18 : (compact ? 24 : 32),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: color,
          );
      final timeStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
        fontSize: r.isWatch ? 28 : (compact ? 36 : 52),
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

      final label = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                seg.kind.label(l10n).toUpperCase(),
                style: labelStyle,
                maxLines: 1,
              ),
            ),
          ),
          if (seg.round > 0 && !r.isWatch) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              '${seg.round}/${plan.rounds}',
              style: labelStyle?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      );

      final time = Text(
        formatCountdown(remaining),
        textAlign: TextAlign.center,
        style: timeStyle,
      );

      final dial = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _swipe,
        child: LiveClockView(
          style: _style,
          progress: _progress,
          totalSeconds: seg.durationMs ~/ 1000,
          isRest: seg.kind.isRest,
          phase: paused ? ClockPhase.paused : ClockPhase.running,
          wordMode: false,
        ),
      );

      return Column(
        children: [
          label,
          const SizedBox(height: AppSpacing.xs),
          Expanded(child: dial),
          const SizedBox(height: AppSpacing.xs),
          time,
          if (r.isWatch && seg.round > 0)
            Text(
              l10n.intervalsRound(seg.round, plan.rounds),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          if (!r.isWatch) ...[
            const SizedBox(height: AppSpacing.sm),
            _OverallBar(value: _svc.overallProgress, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatCountdown((_svc.elapsedMs / 1000).floor())}'
              ' / ${formatCountdown(plan.totalSeconds)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          ValueListenableBuilder<bool>(
            valueListenable: Fullscreen.active,
            builder: (context, full, _) => full || r.isWatch
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconButton(
                          tooltip: l10n.timerReset,
                          onPressed: _svc.reset,
                          icon: const Icon(Icons.stop_rounded),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        AppIconButton(
                          tooltip: l10n.intervalsSkip,
                          onPressed: _svc.skip,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _OverallBar extends StatelessWidget {
  const _OverallBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
                child: ColoredBox(color: scheme.surfaceContainerHigh)),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowFace extends StatelessWidget {
  const _RowFace({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlighted ? scheme.primary : scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.md : AppSpacing.lg,
          vertical: dense ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: dense ? 12 : null,
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
