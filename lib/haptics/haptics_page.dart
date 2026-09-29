import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../ui/atoms/app_switch.dart';
import '../ui/atoms/bouncy_tap.dart';
import '../ui/design/motion.dart';
import '../ui/design/spacing.dart';
import '../ui/molecules/settings_row.dart';
import '../ui/templates/settings_shell.dart';
import 'haptic_events.dart';
import 'haptics.dart';

String hapticStrengthLabel(AppLocalizations l, HapticStrength s) => switch (s) {
      HapticStrength.soft => l.hapticsSoft,
      HapticStrength.medium => l.hapticsMedium,
      HapticStrength.strong => l.hapticsStrong,
    };

String _patternLabel(AppLocalizations l, AlarmPattern p) => switch (p) {
      AlarmPattern.heartbeat => l.hapticsPatternHeartbeat,
      AlarmPattern.pulse => l.hapticsPatternPulse,
      AlarmPattern.crescendo => l.hapticsPatternCrescendo,
      AlarmPattern.ripple => l.hapticsPatternRipple,
      AlarmPattern.beacon => l.hapticsPatternBeacon,
    };

/// Vibration settings: on/off, strength, which families of feedback are on,
/// the alarm pattern, and a "try it" board to feel each sensation.
class HapticsPage extends StatelessWidget {
  const HapticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!Haptics.available) {
      return SettingsShell(
        title: l10n.hapticsTitle,
        loaded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.hapticsUnavailable,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            top: AppSpacing.xl,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            text,
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );

    Widget switchRow(String label, String hint, ValueNotifier<bool> value,
            Future<void> Function(bool) set) =>
        ValueListenableBuilder<bool>(
          valueListenable: value,
          builder: (context, on, _) => SettingsRow(
            label: label,
            subtitle: hint,
            trailing: AppSwitch(value: on, onChanged: set),
          ),
        );

    Widget radio(bool selected) => Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );

    return SettingsShell(
      title: l10n.hapticsTitle,
      loaded: true,
      children: [
        switchRow(
          l10n.hapticFeedback,
          l10n.hapticFeedbackHint,
          Haptics.enabled,
          (on) async {
            await Haptics.setEnabled(on);
            // Feel it the moment it comes on.
            if (on) Haptics.preview(HapticEvents.success);
          },
        ),
        // Everything below only matters while vibration is on.
        ValueListenableBuilder<bool>(
          valueListenable: Haptics.enabled,
          builder: (context, on, _) => AnimatedOpacity(
            duration: Motion.medium,
            opacity: on ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !on,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header(l10n.hapticsStrength),
                  ValueListenableBuilder<HapticStrength>(
                    valueListenable: Haptics.strength,
                    builder: (context, current, _) => Column(
                      children: [
                        for (final s in HapticStrength.values)
                          SettingsRow(
                            label: hapticStrengthLabel(l10n, s),
                            trailing: radio(s == current),
                            onTap: () async {
                              await Haptics.setStrength(s);
                              // A confirm at the new strength, so the choice
                              // is felt rather than described.
                              Haptics.preview(HapticEvents.confirm);
                            },
                          ),
                      ],
                    ),
                  ),
                  header(l10n.hapticsWhen),
                  switchRow(l10n.hapticsTouch, l10n.hapticsTouchHint,
                      Haptics.touch, Haptics.setTouch),
                  switchRow(l10n.hapticsMotion, l10n.hapticsMotionHint,
                      Haptics.motion, Haptics.setMotion),
                  switchRow(l10n.hapticsAlerts, l10n.hapticsAlertsHint,
                      Haptics.alerts, Haptics.setAlerts),
                  header(l10n.hapticsAlarmPattern),
                  ValueListenableBuilder<AlarmPattern>(
                    valueListenable: Haptics.alarmPattern,
                    builder: (context, current, _) => Column(
                      children: [
                        for (final p in AlarmPattern.values)
                          SettingsRow(
                            label: _patternLabel(l10n, p),
                            trailing: radio(p == current),
                            onTap: () async {
                              await Haptics.setAlarmPattern(p);
                              Haptics.preview(p.event);
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.hapticsAlarmPatternHint,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  header(l10n.hapticsTry),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _TryPill(l10n.hapticsTryTap, HapticEvents.tap),
                        _TryPill(l10n.hapticsTrySuccess, HapticEvents.success),
                        _TryPill(l10n.hapticsTryToRest, HapticEvents.toRest),
                        _TryPill(l10n.hapticsTryToWork, HapticEvents.toWork),
                        _TryPill(l10n.hapticsTryTimer, HapticEvents.timerDone),
                        _TryPill(l10n.hapticsTryWarning, HapticEvents.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A button that plays one event. It doesn't add its own press haptic, so
/// what you feel is exactly the event.
class _TryPill extends StatelessWidget {
  const _TryPill(this.label, this.event);

  final String label;
  final HapticEvent event;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: () => Haptics.preview(event),
      enableFeedback: false,
      pressedScale: 0.94,
      focusBorderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
