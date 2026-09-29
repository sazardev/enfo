import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_preferences.dart';
import '../../l10n/locale_controller.dart';
import '../../ui/atoms/app_icon_button.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/page_transition.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../clock/time_builder.dart';
import '../format.dart';
import '../mode_scaffold.dart';
import '../notifier.dart';
import 'alarm.dart';
import 'alarm_edit_page.dart';
import 'alarm_labels.dart';
import 'alarm_service.dart';
import '../../ui/atoms/app_switch.dart';

/// Alarm list: big times with an on/off switch, the next one to ring, and
/// a nudge to grant the permissions alarms need on a phone.
class AlarmModePage extends StatelessWidget {
  const AlarmModePage({super.key});

  void _edit(BuildContext context, [Alarm? alarm]) {
    Navigator.of(context)
        .push(appPageRoute((_) => AlarmEditPage(alarm: alarm)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final mobile = Platform.isAndroid || Platform.isIOS;

    return ModeScaffold(
      actions: [
        AppIconButton(
          tooltip: l10n.alarmNew,
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([
          AlarmService.alarms,
          AppPreferences.clockFormat,
        ]),
        builder: (context, _) {
          final alarms = AlarmService.alarms.value;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!r.isWatch)
                  TimeBuilder(
                    builder: (context, now) {
                      final next = AlarmService.nextOverall(now);
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          bottom: AppSpacing.md,
                        ),
                        child: Text(
                          next == null
                              ? l10n.alarmNone
                              : l10n.alarmNext(
                                  formatDuration(
                                    next.difference(now).inSeconds + 59,
                                  ),
                                ),
                          style: textTheme.titleMedium?.copyWith(
                            color: next == null
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                if (alarms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.huge),
                    child: Text(
                      l10n.alarmEmpty,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                for (final alarm in alarms)
                  _AlarmCard(
                    alarm: alarm,
                    compact: r.isWatch,
                    onTap: () => _edit(context, alarm),
                    onToggle: (on) => AlarmService.setEnabled(alarm, on),
                  ),
                if (!r.isWatch) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      mobile ? l10n.alarmPermissionHint : l10n.alarmDesktopHint,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (mobile)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: Notifier.requestPermissions,
                        child: Text(l10n.alarmPermissionButton),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.compact,
    required this.onTap,
    required this.onToggle,
  });

  final Alarm alarm;
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final use24h = switch (AppPreferences.clockFormat.value) {
      ClockFormat.system => MediaQuery.alwaysUse24HourFormatOf(context),
      ClockFormat.h12 => false,
      ClockFormat.h24 => true,
    };
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: alarm.hour, minute: alarm.minute),
      alwaysUse24HourFormat: use24h,
    );
    final on = alarm.enabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BouncyTap(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.md : AppSpacing.lg,
            vertical: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: on
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: compact ? AppRadii.smRadius : AppRadii.mdRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: (compact
                              ? textTheme.titleLarge
                              : textTheme.headlineMedium)
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!compact)
                      Text(
                        [
                          if (alarm.label.isNotEmpty) alarm.label,
                          repeatSummary(context, alarm.days),
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              AppSwitch(value: on, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
