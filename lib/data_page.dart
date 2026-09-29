import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'app_data.dart';
import 'history.dart';
import 'modes/tool_history.dart';
import 'l10n/locale_controller.dart';
import 'onboarding.dart';
import 'theme.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/radii.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/confirm_action_row.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

/// Stored data: how much there is, and ways to clear it — replay the
/// welcome screen, clear the history, reset settings, or erase everything.
class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  int? _sessionCount;
  String? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final sessions = await SessionHistory.load();
    final events = await ToolHistory.load();
    if (!mounted) return;
    setState(() => _sessionCount = sessions.length + events.length);
  }

  void _notifyHub() => SettingsPaneScope.maybeOf(context)?.onChanged();

  /// Puts the running theme back to light + the default accent (the theme
  /// package keeps its own storage, which a preferences wipe doesn't touch).
  void _resetTheme() {
    AdaptiveTheme.of(context)
      ..setLight()
      ..setTheme(
        light: Themes.light(Themes.accent),
        dark: Themes.dark(Themes.accent),
      );
  }

  Future<void> _clearHistory() async {
    await AppData.clearHistory();
    if (!mounted) return;
    setState(() => _status = context.l10n.dataDoneHistory);
    await _refresh();
  }

  Future<void> _resetSettings() async {
    await AppData.resetSettings();
    if (!mounted) return;
    _resetTheme();
    setState(() => _status = context.l10n.dataDoneSettings);
    _notifyHub();
  }

  Future<void> _eraseAll() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await AppData.eraseAll();
    if (!mounted) return;
    _resetTheme();
    // Back to the welcome screen with no way back into the old state.
    navigator.pushAndRemoveUntil(
      appPageRoute((_) => const Onboarding()),
      (_) => false,
    );
  }

  void _replayOnboarding() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      appPageRoute((_) => const Onboarding()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final count = _sessionCount;

    Widget note(String text) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            text,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );

    return SettingsShell(
      title: l10n.dataTitle,
      loaded: true,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Text(
            count == null ? '…' : l10n.dataSessions(count),
            style: textTheme.bodyLarge,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _status == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: AppRadii.mdRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(_status!, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsRow(
          label: l10n.dataIntro,
          subtitle: l10n.dataIntroHint,
          trailing: const Icon(Icons.waving_hand_outlined),
          onTap: _replayOnboarding,
        ),
        const SizedBox(height: AppSpacing.lg),
        ConfirmActionRow(
          icon: Icons.history_toggle_off_rounded,
          label: l10n.statsClearHistory,
          confirmLabel: l10n.dataConfirmClearHistory,
          hint: l10n.dataClearHistoryHint,
          onConfirmed: _clearHistory,
        ),
        ConfirmActionRow(
          icon: Icons.settings_backup_restore_rounded,
          label: l10n.dataResetSettings,
          confirmLabel: l10n.dataConfirmResetSettings,
          hint: l10n.dataResetSettingsHint,
          onConfirmed: _resetSettings,
        ),
        ConfirmActionRow(
          icon: Icons.delete_forever_rounded,
          label: l10n.dataEraseAll,
          confirmLabel: l10n.dataConfirmEraseAll,
          hint: l10n.dataEraseAllHint,
          onConfirmed: _eraseAll,
        ),
        note(l10n.dataCacheNote),
      ],
    );
  }
}
