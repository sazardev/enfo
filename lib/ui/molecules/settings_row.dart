import 'package:flutter/material.dart';

import '../atoms/bouncy_tap.dart';
import '../design/radii.dart';
import '../design/spacing.dart';

/// Flat row: label (+ optional subtitle) on the left, a trailing control on
/// the right. Replaces [ListTile] usage in settings — no ripple, rounded,
/// tap-bounces the whole row when [onTap] is given.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: textTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      ),
    );

    if (onTap == null) return content;

    return BouncyTap(
      onTap: onTap,
      pressedScale: 0.98,
      child: ClipRRect(borderRadius: AppRadii.mdRadius, child: content),
    );
  }
}
