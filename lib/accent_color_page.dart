import 'package:flutter/material.dart';

import 'l10n/locale_controller.dart';
import 'theme.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/design/responsive.dart';
import 'ui/design/motion.dart';
import 'ui/design/radii.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/app_top_bar.dart';
import 'ui/organisms/accent_picker.dart';
import 'ui/molecules/countdown_ring.dart';

/// Full-page accent-color picker — a real screen (pushed via [Navigator]),
/// not a modal. The app allows zero modals: no dialogs, no bottom sheets.
///
/// A miniature home screen at the top re-themes live as colors are tried,
/// so the accent can be judged in context before it is applied. Nothing is
/// saved until "Apply" pops the chosen [Color].
class AccentColorPage extends StatefulWidget {
  const AccentColorPage({
    super.key,
    required this.colors,
    required this.selected,
  });

  final List<Color> colors;
  final Color selected;

  @override
  State<AccentColorPage> createState() => _AccentColorPageState();
}

class _AccentColorPageState extends State<AccentColorPage> {
  late Color _color = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewTheme = isDark ? Themes.dark(_color) : Themes.light(_color);

    // On a watch there is no preview or Apply step: a tap commits.
    final picker = AccentPicker(
      colors: widget.colors,
      color: _color,
      swatchSize: r.isWatch ? 44 : 52,
      allowCustom: !r.isWatch,
      onChanged: (c) =>
          r.isWatch ? Navigator.of(context).pop(c) : setState(() => _color = c),
    );

    final apply = FilledButton(
      onPressed: () => Navigator.of(context).pop(_color),
      child: Text(l10n.accentApply),
    );

    final preview = AnimatedTheme(
      data: previewTheme,
      duration: Motion.medium,
      child: const IgnorePointer(child: _HomePreview()),
    );

    // Wide screens: the preview stays put on the left while the choices
    // scroll on the right, so every change is visible as it is made.
    final Widget body;
    if (r.isWide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: SingleChildScrollView(child: preview))),
          SizedBox(width: r.pagePadding * 1.5),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  picker,
                  const SizedBox(height: AppSpacing.xxl),
                  apply,
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      body = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!r.isWatch) ...[
              preview,
              const SizedBox(height: AppSpacing.xxl)
            ],
            picker,
            if (!r.isWatch) ...[
              const SizedBox(height: AppSpacing.xxl),
              apply,
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appTopBar(context, title: Text(l10n.accentColor)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: r.isWide ? r.size.width * 0.92 : r.contentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                AppSpacing.sm,
                r.pagePadding,
                r.pagePadding,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature, non-interactive rendition of the home screen, painted with
/// whatever [Theme] it sits under (the page wraps it in an [AnimatedTheme]).
class _HomePreview extends StatelessWidget {
  const _HomePreview();

  static const _ringProgress = 0.68;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle =
        (theme.textTheme.headlineMedium ?? const TextStyle()).copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadii.lgRadius,
      ),
      child: IconTheme(
        data: IconThemeData(color: colorScheme.onSurfaceVariant),
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '09:41',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 160,
                height: 160,
                child: CountdownRing(
                  progress: _ringProgress,
                  label: '17:00',
                  labelStyle: labelStyle,
                  ringColor: colorScheme.primary,
                  trackColor: colorScheme.primary.withValues(alpha: 0.14),
                  surfaceColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppIconButton(
                    size: 36,
                    selected: true,
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const AppIconButton(
                    size: 36,
                    icon: Icon(Icons.bar_chart_rounded, size: 20),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time_rounded, size: 18),
                  Switch(value: true, onChanged: (_) {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
