import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../ui/atoms/bouncy_tap.dart';
import '../ui/design/page_transition.dart';
import '../ui/design/radii.dart';
import '../ui/design/spacing.dart';
import '../ui/molecules/settings_row.dart';
import '../ui/templates/settings_shell.dart';
import 'activity_page.dart';
import 'app_mode.dart';
import 'clock/clock_settings_page.dart';
import 'mode_prefs.dart';

/// The modes menu: jump to a mode, choose which ones are on, drag to set
/// the order the quick-switch button cycles through, and pick the mode the
/// app starts in.
class ModesPage extends StatefulWidget {
  const ModesPage({super.key});

  @override
  State<ModesPage> createState() => _ModesPageState();
}

class _ModesPageState extends State<ModesPage> {
  String? _notice;

  Future<void> _toggle(AppMode mode, bool on) async {
    final ok = await ModePrefs.setEnabled(mode, on);
    if (!mounted) return;
    setState(() => _notice = ok ? null : context.l10n.modesAtLeastOne);
  }

  void _open(AppMode mode) {
    ModePrefs.setCurrent(mode);
    // Back to the host, which now shows the chosen mode.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([ModePrefs.changes, ModePrefs.startMode]),
      builder: (context, _) {
        final order = ModePrefs.order.value;

        Widget hint(String text, {bool error = false}) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color:
                      error ? colorScheme.error : colorScheme.onSurfaceVariant,
                ),
              ),
            );

        Widget startOption(String label, AppMode? mode) {
          final selected = ModePrefs.startMode.value == mode;
          return SettingsRow(
            label: label,
            onTap: () => ModePrefs.setStartMode(mode),
            trailing: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color:
                  selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          );
        }

        return SettingsShell(
          title: l10n.modesTitle,
          loaded: true,
          children: [
            hint(l10n.modesHint),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, _, __) =>
                  Material(color: Colors.transparent, child: child),
              onReorderItem: (from, to) {
                final next = List.of(order);
                next.insert(to, next.removeAt(from));
                ModePrefs.setOrder(next);
              },
              children: [
                for (var i = 0; i < order.length; i++)
                  _ModeTile(
                    key: ValueKey(order[i]),
                    index: i,
                    mode: order[i],
                    enabled: !ModePrefs.disabled.value.contains(order[i]),
                    current: ModePrefs.current.value == order[i],
                    onOpen: () => _open(order[i]),
                    onToggle: (on) => _toggle(order[i], on),
                  ),
              ],
            ),
            if (_notice != null) hint(_notice!, error: true),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                l10n.modesStart,
                style: textTheme.labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            startOption(l10n.modesStartLast, null),
            for (final m in ModePrefs.enabled) startOption(m.labelOf(l10n), m),
            const SizedBox(height: AppSpacing.xl),
            SettingsRow(
              label: '${l10n.modesCustomize}: ${l10n.modeClock}',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(appPageRoute((_) => const ClockSettingsPage())),
            ),
            SettingsRow(
              label: l10n.modesActivity,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context)
                  .push(appPageRoute((_) => const ActivityPage())),
            ),
          ],
        );
      },
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    super.key,
    required this.index,
    required this.mode,
    required this.enabled,
    required this.current,
    required this.onOpen,
    required this.onToggle,
  });

  final int index;
  final AppMode mode;
  final bool enabled;
  final bool current;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // The current mode is tinted with the container color (not the solid
    // primary) so the switch on it stays legible.
    final foreground = current ? colorScheme.onPrimaryContainer : null;
    final muted = current
        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.75)
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: BouncyTap(
          onTap: enabled ? onOpen : null,
          pressedScale: 0.98,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: current
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Row(
              children: [
                Icon(mode.icon, color: foreground),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.labelOf(l10n),
                        style: textTheme.bodyLarge?.copyWith(color: foreground),
                      ),
                      Text(
                        mode.descriptionOf(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.drag_indicator_rounded, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
