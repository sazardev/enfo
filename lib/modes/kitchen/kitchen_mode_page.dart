import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import '../timer/duration_wheels.dart';
import 'kitchen_service.dart';

/// Several named timers at once. Quick-add chips on top, one flat card per
/// running timer below, the soonest to finish first.
class KitchenModePage extends StatefulWidget {
  const KitchenModePage({super.key});

  @override
  State<KitchenModePage> createState() => _KitchenModePageState();
}

class _KitchenModePageState extends State<KitchenModePage>
    with SingleTickerProviderStateMixin {
  final KitchenService _svc = KitchenService.instance;
  final TextEditingController _name = TextEditingController();
  late final Ticker _ticker = createTicker(_onFrame);
  int _shownSecond = -1;
  bool _customOpen = false;
  int _customSeconds = 300;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChanged);
    _ticker.start();
  }

  void _onFrame(Duration _) {
    final sec = nowProvider().millisecondsSinceEpoch ~/ 1000;
    if (sec != _shownSecond) {
      _shownSecond = sec;
      if (_svc.timers.isNotEmpty && mounted) setState(() {});
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _svc.removeListener(_onChanged);
    _ticker.dispose();
    _name.dispose();
    super.dispose();
  }

  List<(String, int)> _quick(BuildContext context) {
    final l10n = context.l10n;
    return [
      (l10n.kitchenPasta, 9 * 60),
      (l10n.kitchenEggs, 7 * 60),
      (l10n.kitchenTea, 3 * 60),
      (l10n.kitchenRice, 15 * 60),
      (l10n.kitchenOven, 25 * 60),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final soonest = _svc.soonest;

    return ModeKeyBindings(
      mode: AppMode.kitchen,
      actions: ModeKeyActions(
        primary: () {
          final s = _svc.soonest;
          if (s != null) _svc.toggle(s.id);
        },
      ),
      child: ModeScaffold(
        primaryAction: PrimaryActionButton(
          running: soonest?.running ?? false,
          label: soonest?.running ?? false ? l10n.timerPause : l10n.timerResume,
          enabled: soonest != null,
          onPressed: () {
            final s = _svc.soonest;
            if (s != null) _svc.toggle(s.id);
          },
        ),
        body: r.isWatch
            ? _watch(context)
            : LayoutBuilder(builder: (context, c) {
                final sideBySide = c.maxWidth >= 720;
                if (sideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340,
                        child: SingleChildScrollView(child: _adder(context)),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: _list(context, scroll: true)),
                    ],
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _adder(context),
                          const SizedBox(height: AppSpacing.lg),
                          _list(context, scroll: false),
                        ],
                      ),
                    ),
                  ),
                );
              }),
      ),
    );
  }

  // ---------------------------------------------------------------- adding

  Widget _adder(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (name, seconds) in _quick(context))
              _Chip(
                label: '$name · ${formatDuration(seconds)}',
                onTap: () => _svc.add(name, seconds),
              ),
            _Chip(
              label: l10n.kitchenCustom,
              icon: Icons.add_rounded,
              selected: _customOpen,
              onTap: () => setState(() => _customOpen = !_customOpen),
            ),
          ],
        ),
        if (_customOpen) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: l10n.kitchenNameHint,
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.smRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DurationWheels(
                  totalSeconds: _customSeconds,
                  itemExtent: 44,
                  onChanged: (v) => _customSeconds = v,
                ),
                const SizedBox(height: AppSpacing.sm),
                _Chip(
                  label: l10n.kitchenAdd,
                  icon: Icons.play_arrow_rounded,
                  selected: true,
                  onTap: () {
                    if (_svc.add(_name.text, _customSeconds) != null) {
                      setState(() {
                        _name.clear();
                        _customOpen = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------------ list

  Widget _list(BuildContext context, {required bool scroll}) {
    final l10n = context.l10n;
    final timers = _svc.timers;
    if (timers.isEmpty) {
      final empty = Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          l10n.kitchenEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
      return scroll ? Center(child: empty) : empty;
    }
    final cards = [
      for (final t in timers)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _TimerCard(key: ValueKey(t.id), timer: t, svc: _svc),
        ),
    ];
    return scroll
        ? ListView(children: cards)
        : Column(mainAxisSize: MainAxisSize.min, children: cards);
  }

  // ----------------------------------------------------------------- watch

  Widget _watch(BuildContext context) {
    final s = _svc.soonest;
    if (s == null) {
      return Center(
        child: SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final (name, seconds) in _quick(context).take(4))
                _Chip(
                  dense: true,
                  label: '$name ${formatDuration(seconds)}',
                  onTap: () => _svc.add(name, seconds),
                ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        child:
            _TimerCard(key: ValueKey(s.id), timer: s, svc: _svc, dense: true),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    super.key,
    required this.timer,
    required this.svc,
    this.dense = false,
  });

  final KitchenTimer timer;
  final KitchenService svc;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final secs = (timer.remainingMs / 1000).ceil();
    final size = dense ? 34.0 : 40.0;
    final color = timer.running ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(dense ? AppSpacing.sm : AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  timer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (dense ? text.bodyMedium : text.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatCountdown(secs),
                style: (dense ? text.titleMedium : text.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: scheme.surface)),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: timer.progress,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: dense ? AppSpacing.xs : AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!dense)
                AppIconButton(
                  size: size,
                  tooltip: l10n.timerAddMinute,
                  onPressed: () => svc.addMinute(timer.id),
                  icon: const Icon(Icons.add_rounded),
                ),
              AppIconButton(
                size: size,
                tooltip: timer.running ? l10n.timerPause : l10n.timerResume,
                selected: !timer.running,
                onPressed: () => svc.toggle(timer.id),
                icon: Icon(timer.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
              ),
              AppIconButton(
                size: size,
                tooltip: l10n.kitchenDelete,
                onPressed: () => svc.remove(timer.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12 : null,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
