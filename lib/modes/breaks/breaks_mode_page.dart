import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_preferences.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/app_switch.dart';
import '../../ui/design/motion.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/confirm_action_row.dart';
import '../../ui/molecules/countdown_ring.dart';
import '../../ui/molecules/primary_action_button.dart';
import '../app_mode.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_keys.dart';
import '../mode_scaffold.dart';
import '../notifier.dart';
import '../world/time_format.dart';
import 'breaks_model.dart';
import 'breaks_service.dart';

/// Healthy-break reminders: a status card with the countdown to the next
/// break, today's counters, the reminders (switch + interval each), the
/// active-hours window and a note on what happens when Enfo is closed.
class BreaksModePage extends StatefulWidget {
  const BreaksModePage({super.key});

  @override
  State<BreaksModePage> createState() => _BreaksModePageState();
}

class _BreaksModePageState extends State<BreaksModePage> {
  static final _service = BreaksService.instance;

  /// Id of the reminder whose inline editor is open (custom ones only).
  String? _editing;

  /// Interval choices in minutes, walked by the steppers.
  static const _intervals = [
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    45,
    50,
    60,
    75,
    90,
    105,
    120,
    150,
    180,
    240,
  ];
  static const _durations = [10, 20, 30, 45, 60, 90, 120, 180, 300];

  static int _step(List<int> steps, int value, int dir) {
    var i = steps.indexWhere((s) => s >= value);
    if (i < 0) i = steps.length - 1;
    if (steps[i] != value && dir < 0) i = (i - 1).clamp(0, steps.length - 1);
    if (steps[i] == value) i = (i + dir).clamp(0, steps.length - 1);
    return steps[i];
  }

  Future<void> _toggle() async {
    final wasOff = !_service.running;
    await _service.toggle();
    if (wasOff && (Platform.isAndroid || Platform.isIOS)) {
      await Notifier.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);

    return ModeKeyBindings(
      mode: AppMode.breaks,
      actions: ModeKeyActions(primary: _toggle, reset: _service.restart),
      child: ListenableBuilder(
        listenable: Listenable.merge([_service, AppPreferences.clockFormat]),
        builder: (context, _) => ModeScaffold(
          primaryAction: PrimaryActionButton(
            running: _service.running,
            label: _service.running ? l10n.breaksStop : l10n.breaksStart,
            onPressed: _toggle,
          ),
          body: LayoutBuilder(builder: (context, c) {
            final wide = !r.isWatch && c.maxWidth >= 720;
            if (r.isWatch) return _watch(context);
            final status = _statusColumn(context, r);
            final list = _listColumn(context);
            return SingleChildScrollView(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 320, child: status),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(child: list),
                      ],
                    )
                  : Column(children: [status, list]),
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- watch

  Widget _watch(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        children: [
          _StatusRing(size: 110, service: _service),
          const SizedBox(height: AppSpacing.sm),
          for (final rem in _service.reminders)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(rem.icon, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _service.titleOf(rem),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSwitch(
                    value: rem.enabled,
                    onChanged: (v) => _service.setEnabled(rem.id, v),
                  ),
                ],
              ),
            ),
          Text(
            l10n.breaksTaken,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text('${_service.today.taken}'),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- status

  Widget _statusColumn(BuildContext context, Responsive r) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = _service.today;

    Widget counter(String label, int value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Column(
              children: [
                Text('$value',
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(label,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadii.lgRadius,
            ),
            child: Column(
              children: [
                _StatusRing(size: r.isWide ? 150 : 180, service: _service),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(_service.running
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(
                      _service.running ? l10n.breaksStop : l10n.breaksStart),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Text(l10n.breaksToday,
                  style: textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
          Row(
            children: [
              counter(l10n.breaksTaken, today.taken),
              const SizedBox(width: AppSpacing.md),
              counter(l10n.breaksSkipped, today.skipped),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- list

  Widget _listColumn(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mobile = Platform.isAndroid || Platform.isIOS;
    final hours = _service.hours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final rem in _service.reminders) ...[
          _ReminderCard(
            reminder: rem,
            service: _service,
            editing: _editing == rem.id,
            onEdit: () =>
                setState(() => _editing = _editing == rem.id ? null : rem.id),
            onInterval: (dir) => _service.update(rem.copyWith(
                intervalMin: _step(_intervals, rem.intervalMin, dir))),
            onDuration: (dir) => _service.update(rem.copyWith(
                durationSec: _step(_durations, rem.durationSec, dir))),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_service.reminders.where((x) => !x.builtin).length <
            BreaksService.maxCustom)
          TextButton.icon(
            onPressed: () async {
              final added =
                  await _service.addCustom(name: l10n.breaksCustomDefault);
              if (added != null && mounted) setState(() => _editing = added.id);
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.breaksAddCustom),
          ),
        const SizedBox(height: AppSpacing.lg),
        // Active hours.
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.breaksActiveHours,
                        style: textTheme.bodyLarge),
                  ),
                  AppSwitch(
                    value: hours.enabled,
                    onChanged: (v) =>
                        _service.setHours(hours.copyWith(enabled: v)),
                  ),
                ],
              ),
              Text(l10n.breaksActiveHoursHint,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              if (hours.enabled) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Stepper(
                      label: l10n.breaksFrom,
                      value: formatHourMinute(
                          context, hours.start ~/ 60, hours.start % 60),
                      minusTooltip: l10n.breaksEarlierHour,
                      plusTooltip: l10n.breaksLaterHour,
                      onMinus: () => _service.setHours(hours.copyWith(
                          start: (hours.start - 30 + 1440) % 1440)),
                      onPlus: () => _service.setHours(
                          hours.copyWith(start: (hours.start + 30) % 1440)),
                    ),
                    _Stepper(
                      label: l10n.breaksTo,
                      value: formatHourMinute(
                          context, hours.end ~/ 60, hours.end % 60),
                      minusTooltip: l10n.breaksEarlierHour,
                      plusTooltip: l10n.breaksLaterHour,
                      onMinus: () => _service.setHours(
                          hours.copyWith(end: (hours.end - 30 + 1440) % 1440)),
                      onPlus: () => _service.setHours(
                          hours.copyWith(end: (hours.end + 30) % 1440)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Background notice.
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.mdRadius,
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.breaksBackground,
                              style: textTheme.bodyLarge),
                        ),
                        AppSwitch(
                          value: _service.background,
                          onChanged: _service.setBackground,
                        ),
                      ],
                    ),
                    Text(
                      _service.background
                          ? l10n.breaksBackgroundOn
                          : l10n.breaksBackgroundOff,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                )
              : Text(
                  l10n.breaksDesktopNotice,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// The ring with the countdown to whichever break comes first.
class _StatusRing extends StatelessWidget {
  const _StatusRing({required this.size, required this.service});

  final double size;
  final BreaksService service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TimeBuilder(builder: (context, now) {
      final next = service.upcoming;
      String label;
      double progress = 0;
      String caption;
      if (!service.running) {
        label = '--:--';
        caption = l10n.breaksStatusOff;
      } else if (next == null) {
        label = '--:--';
        caption = l10n.breaksNoneEnabled;
      } else {
        final due = DateTime.fromMillisecondsSinceEpoch(next.nextDueMs!);
        final left = due.difference(now);
        // Seconds are rounded up so it never reads 00:00 before it rings.
        label = formatCountdown(
            left.isNegative ? 0 : (left.inMilliseconds + 999) ~/ 1000);
        final total = next.intervalMin * 60000;
        progress = total == 0
            ? 0
            : (left.inMilliseconds / total).clamp(0.0, 1.0).toDouble();
        caption = l10n.breaksNextName(service.titleOf(next));
      }
      return Semantics(
        label: '$caption $label',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: CountdownRing(
                progress: progress,
                label: label,
                labelStyle: (size < 140
                        ? textTheme.titleMedium
                        : textTheme.headlineSmall)!
                    .copyWith(
                        fontWeight: FontWeight.w700, color: scheme.onSurface),
                ringColor: scheme.primary,
                trackColor: scheme.primary.withValues(alpha: 0.18),
                surfaceColor: scheme.surface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    });
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({
    required this.reminder,
    required this.service,
    required this.editing,
    required this.onEdit,
    required this.onInterval,
    required this.onDuration,
  });

  final BreakReminder reminder;
  final BreaksService service;
  final bool editing;
  final VoidCallback onEdit;
  final void Function(int dir) onInterval;
  final void Function(int dir) onDuration;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  late final TextEditingController _name =
      TextEditingController(text: widget.reminder.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rem = widget.reminder;
    final service = widget.service;
    final dim = rem.enabled ? 1.0 : 0.6;

    return AnimatedContainer(
      duration: Motion.medium,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            rem.enabled ? scheme.surfaceContainerHigh : scheme.surfaceContainer,
        borderRadius: AppRadii.mdRadius,
      ),
      child: AnimatedSize(
        duration: Motion.medium,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(rem.icon,
                    color:
                        rem.enabled ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Opacity(
                    opacity: dim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.titleOf(rem),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge),
                        Text(
                          service.hintOf(rem),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!rem.builtin)
                  AppIconButton(
                    size: 40,
                    tooltip: l10n.breaksEdit,
                    selected: widget.editing,
                    onPressed: widget.onEdit,
                    icon: Icon(widget.editing
                        ? Icons.check_rounded
                        : Icons.edit_outlined),
                  ),
                AppSwitch(
                  value: rem.enabled,
                  onChanged: (v) => service.setEnabled(rem.id, v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.xs,
              children: [
                _Stepper(
                  value: l10n.breaksEveryMinutes(rem.intervalMin),
                  minusTooltip: l10n.breaksShorter,
                  plusTooltip: l10n.breaksLonger,
                  onMinus: () => widget.onInterval(-1),
                  onPlus: () => widget.onInterval(1),
                ),
                if (widget.editing)
                  _Stepper(
                    label: l10n.breaksDuration,
                    value: BreaksService.durationText(rem.durationSec),
                    minusTooltip: l10n.breaksShorterDuration,
                    plusTooltip: l10n.breaksLongerDuration,
                    onMinus: () => widget.onDuration(-1),
                    onPlus: () => widget.onDuration(1),
                  ),
              ],
            ),
            if (widget.editing && !rem.builtin) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _name,
                maxLength: 30,
                onChanged: (v) => service.update(rem.copyWith(name: v.trim())),
                decoration: InputDecoration(
                  labelText: l10n.breaksName,
                  counterText: '',
                  filled: true,
                  fillColor: scheme.surface,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.smRadius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.breaksIcon,
                  style: textTheme.labelLarge
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < breakIcons.length; i++)
                    AppIconButton(
                      size: 44,
                      selected: rem.iconIndex == i,
                      onPressed: () =>
                          service.update(rem.copyWith(iconIndex: i)),
                      icon: Icon(breakIcons[i]),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ConfirmActionRow(
                icon: Icons.delete_outline_rounded,
                label: l10n.breaksRemove,
                confirmLabel: l10n.breaksRemoveConfirm,
                hint: l10n.breaksRemoveHint,
                onConfirmed: () async {
                  widget.onEdit();
                  await service.removeCustom(rem.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `label  [-] value [+]`.
class _Stepper extends StatelessWidget {
  const _Stepper({
    this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.minusTooltip,
    this.plusTooltip,
  });

  final String? label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String? minusTooltip;
  final String? plusTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!,
              style: textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
        ],
        AppIconButton(
          size: 40,
          tooltip: minusTooltip,
          onPressed: onMinus,
          icon: const Icon(Icons.remove_rounded),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 84),
          child: Text(value,
              textAlign: TextAlign.center, style: textTheme.titleSmall),
        ),
        AppIconButton(
          size: 40,
          tooltip: plusTooltip,
          onPressed: onPlus,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
