import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../modes/app_mode.dart';
import '../ui/atoms/app_icon_button.dart';
import '../ui/atoms/app_switch.dart';
import '../ui/atoms/bouncy_tap.dart';
import '../ui/design/spacing.dart';
import '../ui/molecules/settings_row.dart';
import '../ui/templates/settings_shell.dart';
import 'widget_bridge.dart';
import 'widget_prefs.dart';

/// Android home-screen widgets: add them from here, and choose whether they
/// wear the system's Material You colors or Enfo's accent.
class WidgetsPage extends StatefulWidget {
  const WidgetsPage({super.key});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  bool _loaded = false;
  bool _canPin = false;
  bool _hasSystemColors = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final canPin = await WidgetBridge.canPin();
    final seed = await WidgetBridge.systemSeed();
    if (!mounted) return;
    setState(() {
      _canPin = canPin;
      _hasSystemColors = seed != null;
      _loaded = true;
    });
  }

  ({String name, String description, IconData icon}) _describe(
    WidgetKind kind,
  ) {
    final l10n = context.l10n;
    return switch (kind) {
      WidgetKind.pomodoro => (
          name: AppMode.pomodoro.labelOf(l10n),
          description: AppMode.pomodoro.descriptionOf(l10n),
          icon: AppMode.pomodoro.icon,
        ),
      WidgetKind.timer => (
          name: AppMode.timer.labelOf(l10n),
          description: AppMode.timer.descriptionOf(l10n),
          icon: AppMode.timer.icon,
        ),
      WidgetKind.stopwatch => (
          name: AppMode.stopwatch.labelOf(l10n),
          description: AppMode.stopwatch.descriptionOf(l10n),
          icon: AppMode.stopwatch.icon,
        ),
      WidgetKind.alarm => (
          name: AppMode.alarm.labelOf(l10n),
          description: AppMode.alarm.descriptionOf(l10n),
          icon: AppMode.alarm.icon,
        ),
      WidgetKind.world => (
          name: AppMode.world.labelOf(l10n),
          description: AppMode.world.descriptionOf(l10n),
          icon: AppMode.world.icon,
        ),
      WidgetKind.clock => (
          name: AppMode.clock.labelOf(l10n),
          description: AppMode.clock.descriptionOf(l10n),
          icon: AppMode.clock.icon,
        ),
      WidgetKind.analog => (
          name: l10n.faceAnalog,
          description: AppMode.clock.descriptionOf(l10n),
          icon: Icons.access_time_rounded,
        ),
      WidgetKind.music => (
          name: AppMode.music.labelOf(l10n),
          description: AppMode.music.descriptionOf(l10n),
          icon: AppMode.music.icon,
        ),
      WidgetKind.focus => (
          name: l10n.statsTodayFocus,
          description: l10n.widgetsFocusSubtitle,
          icon: Icons.local_fire_department_rounded,
        ),
      WidgetKind.quote => (
          name: l10n.focusQuoteToggle,
          description: l10n.widgetsQuoteSubtitle,
          icon: Icons.format_quote_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget hint(String text) => Padding(
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
      title: l10n.widgetsTitle,
      loaded: _loaded,
      children: [
        if (_hasSystemColors) ...[
          ValueListenableBuilder<bool>(
            valueListenable: WidgetPrefs.dynamicColor,
            builder: (context, on, _) => SettingsRow(
              label: l10n.widgetsDynamicColor,
              subtitle: l10n.widgetsDynamicColorHint,
              trailing: AppSwitch(
                value: on,
                onChanged: WidgetPrefs.setDynamicColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        const _QuoteStyleRow(),
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            l10n.widgetsAddHeader,
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        for (final kind in WidgetKind.values)
          Builder(builder: (context) {
            final info = _describe(kind);
            return SettingsRow(
              label: info.name,
              subtitle: info.description,
              onTap: _canPin ? () => WidgetBridge.pin(kind) : null,
              trailing: _canPin
                  ? AppIconButton(
                      tooltip: l10n.widgetsAdd,
                      onPressed: () => WidgetBridge.pin(kind),
                      icon: const Icon(Icons.add_rounded),
                    )
                  : Icon(info.icon, color: colorScheme.primary),
            );
          }),
        if (!_canPin) hint(l10n.widgetsManualHint),
        hint(l10n.widgetsStyleHint),
        hint(l10n.widgetsTapHint),
      ],
    );
  }
}

/// Decoration of the quote widget: a plain card with the big quote mark, or
/// a filled accent card; the app's palette follows the Material You switch.
class _QuoteStyleRow extends StatelessWidget {
  const _QuoteStyleRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<int>(
      valueListenable: WidgetPrefs.quoteStyle,
      builder: (context, style, _) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.widgetsQuoteStyle,
              style: textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _StyleChip(
                  label: l10n.widgetsQuoteClassic,
                  selected: style == 0,
                  onTap: () => WidgetPrefs.setQuoteStyle(0),
                ),
                _StyleChip(
                  label: l10n.widgetsQuoteAccent,
                  selected: style == 1,
                  onTap: () => WidgetPrefs.setQuoteStyle(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
