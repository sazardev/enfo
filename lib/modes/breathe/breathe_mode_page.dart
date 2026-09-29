import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../haptics/haptics.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import '../tool_history.dart';
import 'breathe_model.dart';
import 'breathe_prefs.dart';

/// Guided breathing: pick a rhythm and a length, press start, and follow the
/// shape as it swells and settles. Everything is derived from the session's
/// start timestamp ([breatheAt]), so a dropped frame never desynchronizes it.
class BreatheModePage extends StatefulWidget {
  const BreatheModePage({super.key});

  @override
  State<BreatheModePage> createState() => _BreatheModePageState();
}

class _BreatheModePageState extends State<BreatheModePage>
    with SingleTickerProviderStateMixin {
  BreatheSettings _settings = BreatheSettings();
  late BreatheSession _session = _newSession();
  late final Ticker _ticker = createTicker((_) => _frame());
  final ValueNotifier<int> _repaint = ValueNotifier(0);

  ({int breath, BreathePhase phase})? _cue;
  int _uiKey = -1;
  bool _reduced = false;
  bool _disposed = false;

  BreatheSession _newSession() => BreatheSession(
        pattern: _settings.active,
        plannedSeconds: _settings.plannedSeconds,
      );

  @override
  void initState() {
    super.initState();
    BreatheSettings.load().then((s) {
      if (_disposed || _session.state != BreatheState.idle) return;
      setState(() {
        _settings = s;
        _session = _newSession();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _disposed = true;
    // Leaving mid-session counts as an interrupted one.
    _logIfWorthIt(completed: false);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- session

  bool get _running => _session.state == BreatheState.running;
  bool get _active =>
      _session.state == BreatheState.running ||
      _session.state == BreatheState.paused;

  void _frame() {
    final now = nowProvider();
    if (_session.completeIfDue(now)) {
      _finish();
      return;
    }
    final p = _session.pointAt(now);
    final cue = (breath: p.breath, phase: p.phase);
    if (cue != _cue) {
      if (_cue != null) _cueHaptic(p.phase);
      _cue = cue;
    }
    // Reduced motion only needs the text (phase, seconds) to repaint.
    final key = _reduced
        ? Object.hash(
            p.phase, p.breath, p.secondsLeft, _session.remainingSeconds(now))
        : now.microsecondsSinceEpoch;
    if (key != _uiKey) {
      _uiKey = key;
      _repaint.value++;
    }
  }

  void _cueHaptic(BreathePhase phase) {
    switch (phase) {
      case BreathePhase.inhale:
        Haptics.breatheIn();
      case BreathePhase.exhale:
        Haptics.breatheOut();
      case BreathePhase.holdFull:
      case BreathePhase.holdEmpty:
        Haptics.breatheHold();
    }
  }

  void _start() {
    if (_session.state == BreatheState.done) {
      _session = _newSession();
      _logged = false;
    }
    Haptics.confirm();
    final resuming = _session.state == BreatheState.paused;
    _session.start(nowProvider());
    if (!resuming) {
      final p = _session.pointAt(nowProvider());
      _cue = (breath: p.breath, phase: p.phase);
    }
    if (!_ticker.isActive) _ticker.start();
    _uiKey = -1;
    setState(() {});
  }

  void _pause() {
    Haptics.tap();
    _session.pause(nowProvider());
    _ticker.stop();
    _repaint.value++;
    setState(() {});
  }

  void _toggle() => _running ? _pause() : _start();

  /// Ends the session without finishing it.
  void _reset() {
    if (_session.state == BreatheState.idle) return;
    if (_active) Haptics.warning();
    _logIfWorthIt(completed: _session.plannedSeconds == null);
    _ticker.stop();
    _cue = null;
    _logged = false;
    setState(() => _session = _newSession());
  }

  void _finish() {
    _ticker.stop();
    Haptics.success();
    _logIfWorthIt(completed: true);
    _repaint.value++;
    if (mounted) setState(() {});
  }

  bool _logged = false;

  void _logIfWorthIt({required bool completed}) {
    final s = _session;
    if (s.state == BreatheState.idle || s.startedAt == null) return;
    if (s.state == BreatheState.done && _logged) return;
    final now = nowProvider();
    final seconds = s.elapsedMs(now) ~/ 1000;
    if (seconds < 10 && !completed) return;
    if (s.state == BreatheState.done) _logged = true;
    ToolHistory.add(ToolEvent(
      kind: ToolKind.breathe,
      at: s.startedAt!,
      seconds: seconds,
      planned: s.plannedSeconds,
      completed: completed,
      label: _label(currentL10n(), s.pattern),
    ));
  }

  // -------------------------------------------------------------- settings

  void _update(void Function() change) {
    if (_active) return;
    setState(() {
      change();
      _session = _newSession();
      _logged = false;
    });
    _settings.save();
  }

  String _name(AppLocalizations l10n, BreathePattern p) => switch (p.id) {
        'box' => l10n.breathePatternBox,
        '478' => p.timings,
        'coherent' => l10n.breathePatternCoherent,
        'calm' => l10n.breathePatternCalm,
        _ => l10n.breathePatternCustom,
      };

  /// History label: `Box 4-4-4-4`, `4-7-8`.
  String _label(AppLocalizations l10n, BreathePattern p) =>
      p.id == '478' ? p.timings : '${_name(l10n, p)} ${p.timings}';

  String _cueText(AppLocalizations l10n, BreathePhase phase) => switch (phase) {
        BreathePhase.inhale => l10n.breatheInhale,
        BreathePhase.holdFull || BreathePhase.holdEmpty => l10n.breatheHold,
        BreathePhase.exhale => l10n.breatheExhale,
      };

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = _session.state;
    return ModeKeyBindings(
      mode: AppMode.breathe,
      actions: ModeKeyActions(primary: _toggle, reset: _reset),
      child: ModeScaffold(
        actions: [
          if (state != BreatheState.idle)
            AppIconButton(
              tooltip: l10n.breatheReset,
              onPressed: _reset,
              icon: const Icon(Icons.stop_rounded),
            ),
        ],
        primaryAction: PrimaryActionButton(
          running: _running,
          label: switch (state) {
            BreatheState.idle || BreatheState.done => l10n.breatheStart,
            BreatheState.running => l10n.breathePause,
            BreatheState.paused => l10n.breatheResume,
          },
          onPressed: _toggle,
        ),
        body: _active || state == BreatheState.done
            ? _live(context)
            : _idle(context),
      ),
    );
  }

  Widget _live(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: _repaint,
      builder: (context, _, __) {
        final now = nowProvider();
        final done = _session.state == BreatheState.done;
        final p = _session.pointAt(now);
        final fill = _reduced ? 0.75 : (done ? 0.5 : p.fill);
        final cue = done ? l10n.breatheDone : _cueText(l10n, p.phase);
        final paused = _session.state == BreatheState.paused;
        final remaining = _session.plannedSeconds == null
            ? formatCountdown(_session.elapsedMs(now) ~/ 1000)
            : formatCountdown(_session.remainingSeconds(now));

        return Column(
          children: [
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, c) {
                  final side = c.biggest.shortestSide;
                  return Semantics(
                    label: cue,
                    child: CustomPaint(
                      size: Size.square(side),
                      painter: _OrbPainter(
                        fill: fill,
                        guide: scheme.surfaceContainerHigh,
                        color: paused
                            ? scheme.primary.withValues(alpha: 0.5)
                            : scheme.primary,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              cue,
              style: (r.isWatch ? text.titleLarge : text.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (!done)
              Text(
                '${p.secondsLeft}',
                style: (r.isWatch ? text.titleMedium : text.headlineSmall)
                    ?.copyWith(color: scheme.primary),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (!r.isWatch)
              _ProgressBar(
                value: done ? 1 : _session.progress(now),
                color: scheme.primary,
                track: scheme.surfaceContainerHigh,
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              remaining,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _idle(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final orb = CustomPaint(
      size: Size.square(r.isWatch ? 80 : 150),
      painter: _OrbPainter(
        fill: 0.6,
        guide: scheme.surfaceContainerHigh,
        color: scheme.primary,
      ),
    );

    if (r.isWatch) {
      // Tap the name to cycle patterns; the length stays as saved.
      final all = [...BreathePattern.presets, BreathePattern.custom];
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            orb,
            const SizedBox(height: AppSpacing.sm),
            _Pill(
              label: _name(l10n, _settings.pattern),
              selected: true,
              onTap: () {
                final i = all.indexWhere((p) => p.id == _settings.pattern.id);
                _update(() => _settings.pattern = all[(i + 1) % all.length]);
              },
            ),
          ],
        ),
      );
    }

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in [...BreathePattern.presets, BreathePattern.custom])
              _Pill(
                label: _name(l10n, p),
                selected: _settings.pattern.id == p.id,
                onTap: () => _update(() => _settings.pattern = p),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _settings.active.timings,
          style: text.titleMedium?.copyWith(color: scheme.primary),
        ),
        if (_settings.pattern.id == 'custom') ...[
          const SizedBox(height: AppSpacing.sm),
          _customSteppers(l10n),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.breatheSession,
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final m in BreatheSettings.lengths)
              _Pill(
                label: m == 0 ? l10n.breatheEndless : l10n.minutes(m),
                selected: _settings.minutes == m,
                onTap: () => _update(() => _settings.minutes = m),
              ),
          ],
        ),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 640 && c.maxWidth > c.maxHeight * 1.3;
      return Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: wide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      orb,
                      const SizedBox(width: AppSpacing.xxxl),
                      Flexible(child: controls),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      orb,
                      const SizedBox(height: AppSpacing.lg),
                      controls,
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _customSteppers(AppLocalizations l10n) {
    final c = _settings.custom;
    Widget stepper(
        String label, int value, int min, int max, void Function(int) set) {
      return _Stepper(
        label: label,
        value: value,
        min: min,
        max: max,
        onChanged: (v) => _update(() {
          set(v);
        }),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        stepper(l10n.breatheInhale, c.inhale, 1, 12,
            (v) => _settings.custom = c.copyWith(inhale: v)),
        stepper(l10n.breatheHold, c.holdFull, 0, 12,
            (v) => _settings.custom = c.copyWith(holdFull: v)),
        stepper(l10n.breatheExhale, c.exhale, 1, 12,
            (v) => _settings.custom = c.copyWith(exhale: v)),
        stepper(l10n.breatheHold, c.holdEmpty, 0, 12,
            (v) => _settings.custom = c.copyWith(holdEmpty: v)),
      ],
    );
  }
}

/// The breathing shape: a resting guide disc (the full size) and a filled
/// shape that grows from a rounded square into a circle as the lungs fill.
class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.fill, required this.guide, required this.color});

  final double fill;
  final Color guide;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final full = size.shortestSide;
    canvas.drawCircle(c, full / 2, Paint()..color = guide);
    final d = full * (0.34 + 0.62 * fill);
    final radius = d / 2 * (0.6 + 0.4 * fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: d, height: d),
        Radius.circular(radius),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.fill != fill || old.color != color || old.guide != guide;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar(
      {required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: Stack(children: [
            Positioned.fill(child: ColoredBox(color: track)),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: color),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
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

/// Label, value and − / + buttons in one compact row.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        AppIconButton(
          size: 36,
          tooltip: '-1',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 20),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        AppIconButton(
          size: 36,
          tooltip: '+1',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
      ],
    );
  }
}
