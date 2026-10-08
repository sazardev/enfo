import 'package:flutter/material.dart';

import 'daily_quote.dart';
import 'focus_quotes.dart';
import 'l10n/locale_controller.dart';
import 'modes/notifier.dart';
import 'presets.dart';
import 'ui/atoms/app_switch.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/molecules/time_wheels.dart';
import 'ui/templates/settings_shell.dart';

/// Notification settings: Pomodoro phase changes and the daily focus quote.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _enabled = true;
  bool _quote = false;
  int _hour = DailyQuote.defaultHour;
  int _minute = DailyQuote.defaultMinute;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await Presets.loadNotificationsEnabled();
    await DailyQuote.load();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _quote = DailyQuote.enabled;
      _hour = DailyQuote.hour;
      _minute = DailyQuote.minute;
      _loaded = true;
    });
  }

  Future<void> _toggleQuote(bool value) async {
    setState(() => _quote = value);
    if (value) await Notifier.requestNotifications();
    await DailyQuote.setEnabled(value);
    if (mounted) SettingsPaneScope.maybeOf(context)?.onChanged();
  }

  Future<void> _setTime(int hour, int minute) async {
    setState(() {
      _hour = hour;
      _minute = minute;
    });
    await DailyQuote.setTime(hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.notificationsTitle,
      loaded: _loaded,
      children: [
        SettingsRow(
          label: l10n.notificationsToggle,
          trailing: AppSwitch(
            value: _enabled,
            onChanged: (value) async {
              setState(() => _enabled = value);
              await Presets.saveNotificationsEnabled(value);
              if (context.mounted) {
                SettingsPaneScope.maybeOf(context)?.onChanged();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.notificationsHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        SettingsRow(
          label: l10n.focusQuoteToggle,
          subtitle: l10n.focusQuoteHint,
          trailing: AppSwitch(
            value: _quote,
            onChanged: _toggleQuote,
          ),
        ),
        if (_quote) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              '${l10n.focusQuoteExample} '
              '${FocusQuotes.forDate(currentL10n(), DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              l10n.focusQuoteTime,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: TimeWheels(
              hour: _hour,
              minute: _minute,
              onChanged: _setTime,
            ),
          ),
        ],
      ],
    );
  }
}
