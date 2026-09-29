import 'package:flutter/material.dart';

import '../atoms/bouncy_tap.dart';
import '../atoms/chubby_icon.dart';
import '../design/radii.dart';
import '../design/responsive.dart';
import '../design/spacing.dart';

/// Row that leads to a settings sub-page: tinted icon badge, title, a
/// subtitle summarising the current value, and a chevron. Bounces on tap.
///
/// On a watch it collapses to icon + title (no subtitle/chevron). When
/// [selected] (master-detail on wide screens) it fills with the accent.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final watch = Responsive.of(context).isWatch;

    final background =
        selected ? colorScheme.primary : colorScheme.surfaceContainerHigh;
    final foreground = selected ? colorScheme.onPrimary : null;
    final muted = selected
        ? colorScheme.onPrimary.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;
    final badge = watch ? 32.0 : 40.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BouncyTap(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(watch ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            borderRadius: watch ? AppRadii.smRadius : AppRadii.mdRadius,
          ),
          child: Row(
            children: [
              Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.onPrimary.withValues(alpha: 0.18)
                      : colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: AppRadii.smRadius,
                ),
                child: ChubbyIcon(
                  icon,
                  size: badge * 0.55,
                  color: selected ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
              SizedBox(width: watch ? AppSpacing.md : AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (watch ? textTheme.bodyMedium : textTheme.bodyLarge)
                              ?.copyWith(color: foreground),
                    ),
                    if (subtitle != null && !watch) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (!watch) Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
