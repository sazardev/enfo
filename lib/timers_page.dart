import 'dart:io';

import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'l10n/locale_controller.dart';
import 'presets.dart';
import 'ui/design/radii.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/organisms/preset_picker.dart';
import 'ui/templates/settings_shell.dart';

/// Work/rest durations: presets, or exact manual values.
class TimersPage extends StatefulWidget {
  const TimersPage({super.key});

  @override
  State<TimersPage> createState() => _TimersPageState();
}

class _TimersPageState extends State<TimersPage> {
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preset = await Presets.load();
    if (!mounted) return;
    setState(() {
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.timersTitle,
      loaded: _loaded,
      children: [
        PresetPicker(
          initialWorkMinutes: _workMinutes,
          initialRestMinutes: _restMinutes,
          onChanged: (selection) async {
            setState(() {
              _workMinutes = selection.workMinutes;
              _restMinutes = selection.restMinutes;
            });
            await Presets.save(
              workMinutes: selection.workMinutes,
              restMinutes: selection.restMinutes,
            );
            if (context.mounted) {
              SettingsPaneScope.maybeOf(context)?.onChanged();
            }
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            l10n.behaviorTitle,
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.autoStartNext,
          builder: (context, value, _) => SettingsRow(
            label: l10n.autoStartNext,
            subtitle: l10n.autoStartNextHint,
            trailing: Switch(
              value: value,
              onChanged: AppPreferences.setAutoStartNext,
            ),
          ),
        ),
        if (Platform.isAndroid || Platform.isIOS)
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.haptics,
            builder: (context, value, _) => SettingsRow(
              label: l10n.hapticFeedback,
              subtitle: l10n.hapticFeedbackHint,
              trailing: Switch(
                value: value,
                onChanged: AppPreferences.setHaptics,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.timersCycle(_workMinutes + _restMinutes),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.timersApplyHint,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
