import 'dart:async';

import 'package:flutter/material.dart';

import '../../haptics/haptics.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/clock/clock_frame.dart';
import '../../ui/clock/clock_style.dart';
import '../../ui/clock/clock_view.dart';
import '../../ui/design/motion.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import '../timer/duration_wheels.dart';
import 'versus_controller.dart';

/// Two-player "Turns" clock: a chess-style duel or a speakers agenda.
class VersusModePage extends StatefulWidget {
  const VersusModePage({super.key});

  @override
  State<VersusModePage> createState() => _VersusModePageState();
}

class _VersusModePageState extends State<VersusModePage>
    with SingleTickerProviderStateMixin {
  final VersusController _c = VersusController.instance;
  late final AnimationController _progress = AnimationController(vsync: this);
  Timer? _beat;
  ClockStyle _style = ClockStyle.ring;
  bool _confirmReset = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    _c.ensureLoaded();
    _c.check();
    _syncBeat();
    ClockStyle.load().then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  void _onChanged() {
    if (_c.phase == VersusPhase.setup) _confirmReset = false;
    _syncBeat();
    _syncProgress();
    if (mounted) setState(() {});
  }

  void _syncBeat() {
    if (_c.running) {
      _beat ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
        _c.check();
        _syncProgress();
        if (mounted) setState(() {});
      });
    } else {
      _beat?.cancel();
      _beat = null;
    }
  }

  void _syncProgress() {
    if (_c.kind == VersusKind.speakers && _c.inGame) {
      _progress.value =
          (1 - _c.currentRemainingMs / _c.currentPlannedMs).clamp(0.0, 1.0);
    } else {
      _progress.value = 0;
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _beat?.cancel();
    _progress.dispose();
    super.dispose();
  }

  /// The main control (Space / the bar button).
  void _primary() {
    switch (_c.phase) {
      case VersusPhase.setup:
        _c.begin();
      case VersusPhase.ready:
        _c.tapSide(0);
      case VersusPhase.running:
        _c.kind == VersusKind.duel ? _c.endTurn() : _c.next();
      case VersusPhase.paused:
        _c.resume();
      case VersusPhase.over:
        _c.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phase = _c.phase;

    return ModeKeyBindings(
      mode: AppMode.versus,
      actions: ModeKeyActions(
        primary: _primary,
        reset: _c.reset,
        // No P key exists in the global handler: L pauses / resumes.
        lap: () {
          if (_c.phase == VersusPhase.running ||
              _c.phase == VersusPhase.paused) {
            _c.togglePause();
          }
        },
      ),
      child: ModeScaffold(
        primaryAction: PrimaryActionButton(
          running: phase == VersusPhase.running,
          label: switch (phase) {
            VersusPhase.setup => l10n.timerStart,
            VersusPhase.ready => l10n.timerStart,
            VersusPhase.running => l10n.timerPause,
            VersusPhase.paused => l10n.timerResume,
            VersusPhase.over => l10n.timerReset,
          },
          onPressed: () {
            if (phase == VersusPhase.running) {
              _c.pause();
            } else {
              _primary();
            }
          },
        ),
        body: phase == VersusPhase.setup
            ? _Setup(controller: _c)
            : _c.kind == VersusKind.duel
                ? _DuelBoard(
                    controller: _c,
                    confirmReset: _confirmReset,
                    onReset: _requestReset,
                    onCancelReset: () => setState(() => _confirmReset = false),
                  )
                : _SpeakersRun(
                    controller: _c,
                    style: _style,
                    progress: _progress,
                    confirmReset: _confirmReset,
                    onReset: _requestReset,
                    onCancelReset: () => setState(() => _confirmReset = false),
                  ),
      ),
    );
  }

  void _requestReset() {
    final needsConfirm =
        _c.phase == VersusPhase.running || _c.phase == VersusPhase.paused;
    if (needsConfirm && !_confirmReset) {
      Haptics.tap();
      setState(() => _confirmReset = true);
    } else {
      _c.reset();
    }
  }
}

// ----------------------------------------------------------------- setup

class _Setup extends StatelessWidget {
  const _Setup({required this.controller});
  final VersusController controller;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final l10n = context.l10n;
    final c = controller;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.isWatch ? 200 : 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KindSwitch(
                kind: c.kind,
                onChanged: c.setKind,
                labels: [l10n.versusDuel, l10n.versusSpeakers],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (c.kind == VersusKind.duel)
                _DuelSetup(controller: c)
              else
                _SpeakersSetup(controller: c),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat two-way segmented switch: the selected side morphs into a rounder,
/// filled pill.
class _KindSwitch extends StatelessWidget {
  const _KindSwitch({
    required this.kind,
    required this.onChanged,
    required this.labels,
  });

  final VersusKind kind;
  final ValueChanged<VersusKind> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (final k in VersusKind.values)
            Expanded(
              child: BouncyTap(
                onTap: () {
                  Haptics.select();
                  onChanged(k);
                },
                pressedScale: 0.96,
                focusBorderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: reduce ? Duration.zero : Motion.medium,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: k == kind ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(k == kind ? 24 : 12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[k.index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: k == kind ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: () {
        Haptics.select();
        onTap();
      },
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(selected ? 24 : 14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DuelSetup extends StatefulWidget {
  const _DuelSetup({required this.controller});
  final VersusController controller;

  @override
  State<_DuelSetup> createState() => _DuelSetupState();
}

class _DuelSetupState extends State<_DuelSetup> {
  late final FixedExtentScrollController _minutes = FixedExtentScrollController(
      initialItem: widget.controller.baseSeconds ~/ 60 % 180);
  late final FixedExtentScrollController _increment =
      FixedExtentScrollController(
          initialItem: widget.controller.incrementSeconds % 60);

  @override
  void dispose() {
    _minutes.dispose();
    _increment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final c = widget.controller;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final extent = r.isWatch ? 28.0 : 52.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in duelPresets)
              _Chip(
                label: p.label,
                selected: !c.custom &&
                    p.base == c.baseSeconds &&
                    p.increment == c.incrementSeconds,
                onTap: () => c.setPreset(p),
              ),
            _Chip(
              label: l10n.versusCustom,
              selected: c.custom,
              onTap: () => c.setCustom(),
            ),
          ],
        ),
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Motion.medium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !c.custom
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: SizedBox(
                    height: extent * 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: extent,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: AppRadii.mdRadius,
                          ),
                        ),
                        Row(children: [
                          Expanded(
                            child: LoopWheel(
                              controller: _minutes,
                              count: 180,
                              unit: l10n.timerMinutesShort,
                              extent: extent,
                              onChanged: () => c.setCustom(
                                  minutes: _minutes.selectedItem % 180),
                            ),
                          ),
                          Expanded(
                            child: LoopWheel(
                              controller: _increment,
                              count: 60,
                              unit: '+${l10n.timerSecondsShort}',
                              extent: extent,
                              onChanged: () => c.setCustom(
                                  increment: _increment.selectedItem % 60),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${duelName(c.baseSeconds, c.incrementSeconds)}  ·  ${l10n.versusIncrement} ${c.incrementSeconds}${l10n.timerSecondsShort}',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (!r.isWatch) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.versusTapToStart,
            textAlign: TextAlign.center,
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _SpeakersSetup extends StatelessWidget {
  const _SpeakersSetup({required this.controller});
  final VersusController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < c.speakers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SpeakerRow(
              key: ValueKey(c.speakers[i].id),
              speaker: c.speakers[i],
              position: i + 1,
              canRemove: c.speakers.length > 1,
              controller: c,
            ),
          ),
        if (c.speakers.length < VersusController.maxSpeakers)
          BouncyTap(
            onTap: () {
              Haptics.select();
              c.addSpeaker();
            },
            focusBorderRadius: AppRadii.mdRadius,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: AppRadii.mdRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(l10n.versusAddSpeaker,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${l10n.versusTotal}: ${formatDuration(c.plannedSpeakerSeconds)}',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SpeakerRow extends StatefulWidget {
  const _SpeakerRow({
    super.key,
    required this.speaker,
    required this.position,
    required this.canRemove,
    required this.controller,
  });

  final Speaker speaker;
  final int position;
  final bool canRemove;
  final VersusController controller;

  @override
  State<_SpeakerRow> createState() => _SpeakerRowState();
}

class _SpeakerRowState extends State<_SpeakerRow> {
  late final TextEditingController _name =
      TextEditingController(text: widget.speaker.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final s = widget.speaker;
    final c = widget.controller;
    final r = Responsive.of(context);
    final compact = r.isWatch;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              maxLength: 30,
              onChanged: (v) => c.renameSpeaker(s.id, v.trim()),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: l10n.versusSpeakerN(widget.position),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ),
          ),
          AppIconButton(
            size: compact ? 28 : 36,
            tooltip: l10n.versusMinutesFewer,
            onPressed: s.minutes > 1
                ? () {
                    Haptics.tick();
                    c.setSpeakerMinutes(s.id, s.minutes - 1);
                  }
                : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: compact ? 38 : 56,
            child: Text(
              '${s.minutes}${l10n.timerMinutesShort}',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          AppIconButton(
            size: compact ? 28 : 36,
            tooltip: l10n.versusMinutesMore,
            onPressed: s.minutes < 180
                ? () {
                    Haptics.tick();
                    c.setSpeakerMinutes(s.id, s.minutes + 1);
                  }
                : null,
            icon: const Icon(Icons.add_rounded),
          ),
          if (!compact)
            AppIconButton(
              size: 36,
              tooltip: l10n.versusRemoveSpeaker,
              onPressed: widget.canRemove ? () => c.removeSpeaker(s.id) : null,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ duel

/// `4:59`, `0:07.3` under ten seconds.
String formatDuelTime(int ms) {
  if (ms < 10000) {
    final tenths = (ms / 100).ceil().clamp(0, 99);
    return '0:${two(tenths ~/ 10)}.${tenths % 10}';
  }
  final s = (ms / 1000).ceil();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return h > 0 ? '$h:${two(m)}:${two(s % 60)}' : '$m:${two(s % 60)}';
}

/// Reset control shared by both boards: a reset button that turns into an
/// in-place confirm / cancel pair.
class _ResetControl extends StatelessWidget {
  const _ResetControl({
    required this.confirming,
    required this.onReset,
    required this.onCancel,
    required this.size,
  });

  final bool confirming;
  final VoidCallback onReset;
  final VoidCallback onCancel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    if (!confirming) {
      return AppIconButton(
        size: size,
        tooltip: l10n.versusResetGame,
        onPressed: onReset,
        icon: const Icon(Icons.restart_alt_rounded),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          size: size,
          tooltip: l10n.versusConfirmReset,
          onPressed: onReset,
          icon: Icon(Icons.check_rounded, color: error),
        ),
        AppIconButton(
          size: size,
          tooltip: l10n.cancel,
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _DuelBoard extends StatelessWidget {
  const _DuelBoard({
    required this.controller,
    required this.confirmReset,
    required this.onReset,
    required this.onCancelReset,
  });

  final VersusController controller;
  final bool confirmReset;
  final VoidCallback onReset;
  final VoidCallback onCancelReset;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final c = controller;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, box) {
      // Portrait: two people face each other across the phone, so the top
      // half is turned around. Otherwise the sides sit left / right.
      final stacked = !r.isWatch && box.maxHeight > box.maxWidth;
      final size = r.isWatch ? 32.0 : 44.0;
      final paused = c.phase == VersusPhase.paused;

      Widget half(int side) => Expanded(
            child: _Half(
              controller: c,
              side: side,
              turned: stacked && side == 1,
              compact: r.isWatch,
            ),
          );

      final controls = Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(size),
        ),
        child: Flex(
          direction: stacked ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((c.phase == VersusPhase.running || paused) && !confirmReset)
              AppIconButton(
                size: size,
                selected: paused,
                tooltip: paused ? l10n.timerResume : l10n.timerPause,
                onPressed: c.togglePause,
                icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              ),
            _ResetControl(
              confirming: confirmReset,
              onReset: onReset,
              onCancel: onCancelReset,
              size: size,
            ),
          ],
        ),
      );

      final gap = SizedBox(
        width: stacked ? 0 : AppSpacing.sm,
        height: stacked ? AppSpacing.sm : 0,
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            children:
                stacked ? [half(1), gap, half(0)] : [half(0), gap, half(1)],
          ),
          controls,
        ],
      );
    });
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.controller,
    required this.side,
    required this.turned,
    required this.compact,
  });

  final VersusController controller;
  final int side;

  /// Rotated 180 degrees for the player sitting opposite.
  final bool turned;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final ms = c.remainingMs(side);
    final over = c.phase == VersusPhase.over;
    final lost = over && c.flagged == side;
    final won = over && c.flagged != null && c.flagged != side;
    final isActive = c.active == side &&
        (c.phase == VersusPhase.running || c.phase == VersusPhase.paused);
    final canTap = c.phase == VersusPhase.ready ||
        (c.phase == VersusPhase.running && c.active == side);

    final Color bg;
    final Color fg;
    if (lost) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else if (isActive || won) {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    } else {
      bg = scheme.surfaceContainerHigh;
      fg = scheme.onSurface.withValues(alpha: 0.6);
    }
    final radius = BorderRadius.circular(isActive || lost ? 44 : 24);

    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatDuelTime(ms),
              style: TextStyle(
                fontSize: compact ? 40 : 96,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              lost
                  ? l10n.versusTimeIsUp
                  : c.phase == VersusPhase.ready
                      ? (compact ? '' : l10n.versusTapToStart)
                      : l10n.versusMoves(c.movesBy[side]),
              style: TextStyle(color: fg, fontSize: compact ? 11 : 16),
            ),
          ],
        ),
      ),
    );

    final tile = BouncyTap(
      onTap: canTap ? () => c.tapSide(side) : null,
      pressedScale: 0.985,
      focusBorderRadius: radius,
      autofocus: false,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : Motion.medium,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        alignment: Alignment.center,
        child: content,
      ),
    );
    return turned ? RotatedBox(quarterTurns: 2, child: tile) : tile;
  }
}

// -------------------------------------------------------------- speakers

String _signed(int ms) {
  final s = (ms.abs() / 1000).ceil();
  final text = formatCountdown(s);
  return ms < 0 ? '+$text' : text;
}

class _SpeakersRun extends StatelessWidget {
  const _SpeakersRun({
    required this.controller,
    required this.style,
    required this.progress,
    required this.confirmReset,
    required this.onReset,
    required this.onCancelReset,
  });

  final VersusController controller;
  final ClockStyle style;
  final Animation<double> progress;
  final bool confirmReset;
  final VoidCallback onReset;
  final VoidCallback onCancelReset;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final over = c.phase == VersusPhase.over;
    final overtime = c.overtime;
    final paused = c.phase == VersusPhase.paused;
    final accent = overtime ? scheme.error : scheme.primary;

    // Overtime tints the dial with the error color.
    final dial = Theme(
      data: theme.copyWith(
        colorScheme: overtime ? scheme.copyWith(primary: scheme.error) : scheme,
      ),
      child: LiveClockView(
        style: style,
        progress: progress,
        totalSeconds: c.currentSpeaker.minutes * 60,
        isRest: false,
        phase: paused ? ClockPhase.paused : ClockPhase.running,
        wordMode: false,
      ),
    );

    final name = c.currentSpeaker.name.isEmpty
        ? l10n.versusSpeakerN(c.index + 1)
        : c.currentSpeaker.name;

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          over ? l10n.versusAgendaDone : name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        if (!over) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _signed(c.currentRemainingMs),
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: r.isWatch ? 32 : null,
                fontWeight: FontWeight.w600,
                color: overtime ? scheme.error : scheme.onSurface,
              ),
            ),
          ),
          if (overtime)
            Text(
              l10n.versusOvertime,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${l10n.versusTotal}: ${l10n.versusElapsedOfPlanned(formatDuration((c.totalElapsedMs / 1000).round()), formatDuration(c.plannedSpeakerSeconds))}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!over)
              Flexible(
                child: BouncyTap(
                  onTap: c.next,
                  focusBorderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.isWatch ? AppSpacing.md : AppSpacing.xl,
                        vertical: r.isWatch ? AppSpacing.xs : AppSpacing.md),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!r.isWatch) ...[
                          Flexible(
                            child: Text(
                              c.isLastSpeaker
                                  ? l10n.versusFinish
                                  : l10n.versusNext,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: overtime
                                    ? scheme.onError
                                    : scheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Icon(
                          c.isLastSpeaker
                              ? Icons.flag_rounded
                              : Icons.skip_next_rounded,
                          color: overtime ? scheme.onError : scheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            if (!over && !confirmReset)
              AppIconButton(
                selected: paused,
                tooltip: paused ? l10n.timerResume : l10n.timerPause,
                onPressed: c.togglePause,
                icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              ),
            _ResetControl(
              confirming: confirmReset,
              onReset: onReset,
              onCancel: onCancelReset,
              size: r.isWatch ? 32 : 48,
            ),
          ],
        ),
      ],
    );

    if (r.isWatch) {
      return SingleChildScrollView(child: info);
    }
    if (r.isWide || MediaQuery.sizeOf(context).aspectRatio > 1.3) {
      return Row(
        children: [
          Expanded(child: dial),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: Center(child: SingleChildScrollView(child: info))),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: dial),
        const SizedBox(height: AppSpacing.md),
        info,
      ],
    );
  }
}
