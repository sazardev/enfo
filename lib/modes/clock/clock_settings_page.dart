import 'package:flutter/material.dart';

import '../../l10n/locale_controller.dart';
import '../../ui/atoms/bouncy_tap.dart';
import '../../ui/design/motion.dart';
import '../../ui/design/radii.dart';
import '../../ui/design/responsive.dart';
import '../../ui/design/spacing.dart';
import '../../ui/molecules/settings_row.dart';
import '../../ui/templates/settings_shell.dart';
import '../fullscreen.dart';
import 'clock_prefs.dart';
import 'faces.dart';
import 'time_builder.dart';
import '../../ui/atoms/app_switch.dart';

/// Pick the clock design (live previews) and what it shows.
class ClockSettingsPage extends StatelessWidget {
  const ClockSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget switchRow(
            String label, ValueNotifier<bool> value, ValueChanged<bool> set,
            {String? hint}) =>
        ValueListenableBuilder<bool>(
          valueListenable: value,
          builder: (context, on, _) => SettingsRow(
            label: label,
            subtitle: hint,
            trailing: AppSwitch(value: on, onChanged: set),
          ),
        );

    return SettingsShell(
      title: l10n.clockSettingsTitle,
      loaded: true,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text(
            l10n.clockFaceTitle,
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        // One shared time source for all previews.
        TimeBuilder(
          builder: (context, now) => ValueListenableBuilder<ClockFace>(
            valueListenable: ClockPrefs.face,
            builder: (context, current, _) => GridView.count(
              crossAxisCount: r.isWatch ? 1 : (r.contentWidth > 560 ? 3 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
              children: [
                for (final face in ClockFace.values)
                  ClockFaceTile(
                    face: face,
                    selected: face == current,
                    data: FaceData.of(context, now, compact: true),
                    onTap: () => ClockPrefs.setFace(face),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        switchRow(l10n.clockShowSeconds, ClockPrefs.showSeconds,
            ClockPrefs.setShowSeconds),
        switchRow(
            l10n.clockShowDate, ClockPrefs.showDate, ClockPrefs.setShowDate),
        switchRow(l10n.clockBlinkColon, ClockPrefs.blinkColon,
            ClockPrefs.setBlinkColon),
        switchRow(
          l10n.clockKeepAwake,
          Fullscreen.keepClockAwake,
          Fullscreen.setKeepClockAwake,
          hint: l10n.clockKeepAwakeHint,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.clockFullscreenHint,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Selectable clock-design tile with a live preview.
class ClockFaceTile extends StatelessWidget {
  const ClockFaceTile({
    super.key,
    required this.face,
    required this.selected,
    required this.data,
    required this.onTap,
  });

  final ClockFace face;
  final bool selected;
  final FaceData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.95,
      focusBorderRadius: AppRadii.lgRadius,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.snappy,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(selected ? 44 : 28),
        ),
        child: Column(
          children: [
            Expanded(child: ClockFaceView(face: face, data: data)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              face.labelOf(context.l10n),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? colorScheme.onPrimaryContainer : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
