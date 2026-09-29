import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/motion.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/confirm_action_row.dart';
import '../../ui/templates/settings_shell.dart';
import '../timer/duration_wheels.dart';
import 'alarm.dart';
import 'alarm_labels.dart';
import 'alarm_service.dart';
import '../../haptics/haptics.dart';

/// Create or edit an alarm: hour/minute wheels, a label and repeat days.
/// (No system time-picker dialog: the app allows no modals.)
class AlarmEditPage extends StatefulWidget {
  const AlarmEditPage({super.key, this.alarm});

  /// Null to create a new alarm.
  final Alarm? alarm;

  @override
  State<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends State<AlarmEditPage> {
  late int _hour = widget.alarm?.hour ?? (DateTime.now().hour + 1) % 24;
  late int _minute = widget.alarm?.minute ?? 0;
  late Set<int> _days = {...?widget.alarm?.days};
  late final TextEditingController _label =
      TextEditingController(text: widget.alarm?.label ?? '');

  late final FixedExtentScrollController _hourWheel =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteWheel =
      FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    _label.dispose();
    _hourWheel.dispose();
    _minuteWheel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    final existing = widget.alarm;
    final alarm = existing == null
        ? AlarmService.create(
            hour: _hour,
            minute: _minute,
            days: _days,
            label: label,
          ).copyWith(enabled: true)
        : existing.copyWith(
            hour: _hour,
            minute: _minute,
            days: _days,
            label: label,
            enabled: true,
          );
    await AlarmService.upsert(alarm);
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final extent = r.isWatch ? 40.0 : 64.0;

    return SettingsShell(
      title: widget.alarm == null ? l10n.alarmNew : l10n.alarmEditTitle,
      loaded: true,
      children: [
        SizedBox(
          height: extent * 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: extent,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadii.mdRadius,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: LoopWheel(
                      controller: _hourWheel,
                      count: 24,
                      unit: '',
                      extent: extent,
                      onChanged: () =>
                          setState(() => _hour = _hourWheel.selectedItem % 24),
                    ),
                  ),
                  Text(':', style: textTheme.displaySmall),
                  Expanded(
                    child: LoopWheel(
                      controller: _minuteWheel,
                      count: 60,
                      unit: '',
                      extent: extent,
                      onChanged: () => setState(
                          () => _minute = _minuteWheel.selectedItem % 60),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _label,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.alarmLabel,
            counterText: '',
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: const OutlineInputBorder(
              borderRadius: AppRadii.mdRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text(
            '${l10n.alarmRepeat}  ·  ${repeatSummary(context, _days)}',
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var d = 1; d <= 7; d++)
              _DayPill(
                // 2024-01-01 was a Monday.
                label: DateFormat.E(locale)
                    .format(DateTime(2024, 1, d))
                    .characters
                    .first
                    .toUpperCase(),
                full: DateFormat.EEEE(locale).format(DateTime(2024, 1, d)),
                selected: _days.contains(d),
                onTap: () => setState(() {
                  Haptics.select();
                  _days = {..._days};
                  _days.contains(d) ? _days.remove(d) : _days.add(d);
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(onPressed: _save, child: Text(l10n.alarmSave)),
        if (widget.alarm != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ConfirmActionRow(
            icon: Icons.delete_outline_rounded,
            label: l10n.alarmDelete,
            confirmLabel: l10n.alarmConfirmDelete,
            hint: l10n.alarmDeleteHint,
            onConfirmed: () async {
              await AlarmService.remove(widget.alarm!);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.full,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String full;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: full,
      selected: selected,
      button: true,
      child: BouncyTap(
        onTap: onTap,
        pressedScale: 0.9,
        focusBorderRadius: BorderRadius.circular(48),
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.snappy,
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            // Flat selection cue, like the accent swatches.
            borderRadius: BorderRadius.circular(selected ? 15 : 23),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
