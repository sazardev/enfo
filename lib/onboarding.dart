import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'clock_style_page.dart';
import 'modes/mode_host.dart';
import 'l10n/locale_controller.dart';
import 'presets.dart';
import 'theme.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/clock/clock_combo.dart';
import 'ui/clock/clock_style.dart';
import 'ui/design/motion.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/responsive.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/clock_combo_card.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/organisms/accent_picker.dart';
import 'ui/organisms/language_options.dart';
import 'ui/organisms/preset_picker.dart';

enum _Step { language, rhythm, look, clock, options }

/// First-run setup, as a short wizard: language, rhythm, theme + accent,
/// clock look, and the display/behavior options. Every choice is applied
/// the moment it is made (the screen re-themes, re-translates and rescales
/// as you go) and stays editable later in Settings. Watches only get the
/// two steps that matter: language and rhythm.
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  int _index = 0;
  bool _loaded = false;

  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;
  ClockStyle _style = ClockStyle.ring;
  bool _notifications = true;

  /// One shared clock for the animated combo previews; runs only while the
  /// clock step is showing.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(hours: 1),
  );
  late final Animation<double> _seconds =
      _clock.drive(Tween<double>(begin: 0, end: 3600));

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  /// When the intro is replayed, start from what is already in use rather
  /// than silently resetting it.
  Future<void> _loadCurrent() async {
    final preset = await Presets.load();
    final style = await ClockStyle.load();
    final notifications = await Presets.loadNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
      _style = style;
      _notifications = notifications;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _clock.dispose();
    super.dispose();
  }

  List<_Step> _steps(Responsive r) =>
      r.isWatch ? const [_Step.language, _Step.rhythm] : _Step.values;

  Future<void> _go(int index, List<_Step> steps) async {
    if (index < 0 || index >= steps.length) return;
    setState(() => _index = index);

    if (steps[index] == _Step.clock &&
        !MediaQuery.disableAnimationsOf(context)) {
      _clock.forward();
    } else {
      _clock.stop();
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      await _pages.animateToPage(
        index,
        duration: Motion.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await Presets.save(workMinutes: _workMinutes, restMinutes: _restMinutes);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appPageRoute((context) => const ModeHost()),
    );
  }

  void _setAccent(Color color) {
    // saveAccent assigns Themes.accent synchronously (before its first
    // await), so the rebuild below already sees the new color.
    Themes.saveAccent(color);
    AdaptiveTheme.maybeOf(context)?.setTheme(
      light: Themes.light(color),
      dark: Themes.dark(color),
    );
    setState(() {});
  }

  void _applyCombo(ClockCombo combo) {
    setState(() => _style = combo.style);
    ClockStyle.save(combo.style);
    _setAccent(combo.color);
  }

  Future<void> _browseStyles() async {
    await Navigator.of(context).push(
      appPageRoute((_) => ClockStylePage(selected: _style)),
    );
    final style = await ClockStyle.load();
    if (!mounted) return;
    setState(() => _style = style);
  }

  @override
  Widget build(BuildContext context) {
    // The pickers read their initial values once, so wait for them.
    if (!_loaded) return const Scaffold();

    final r = Responsive.of(context);
    final steps = _steps(r);
    final index = _index.clamp(0, steps.length - 1);
    final last = index == steps.length - 1;
    final l10n = context.l10n;

    Widget constrained(Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.contentWidth),
            child: child,
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            constrained(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.isWatch ? AppSpacing.sm : AppSpacing.lg,
                  r.pagePadding,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: l10n.onbStepOf(index + 1, steps.length),
                        child: Row(
                          children: [
                            for (var i = 0; i < steps.length; i++)
                              AnimatedContainer(
                                duration: Motion.medium,
                                curve: Curves.easeOutCubic,
                                height: 6,
                                width: i == index ? 28 : 10,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: i <= index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!last)
                      TextButton(
                        onPressed: _finish,
                        child: Text(l10n.onbSkip),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                // Steps hold sliders and horizontal lists: swiping the pager
                // would fight them, so navigation is buttons only.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final step in steps) _page(context, r, step),
                ],
              ),
            ),
            constrained(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  AppSpacing.sm,
                  r.pagePadding,
                  r.isWatch ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Visibility(
                      visible: index > 0,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      // A watch has no room for a text button beside Next.
                      child: r.isWatch
                          ? AppIconButton(
                              tooltip: l10n.onbBack,
                              onPressed: () => _go(index - 1, steps),
                              icon: const Icon(Icons.arrow_back_rounded),
                            )
                          : TextButton(
                              onPressed: () => _go(index - 1, steps),
                              child: Text(l10n.onbBack),
                            ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: r.isWatch
                          ? FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            )
                          : null,
                      onPressed: last ? _finish : () => _go(index + 1, steps),
                      child: Text(
                        last ? l10n.onboardingStart : l10n.onbNext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(BuildContext context, Responsive r, _Step step) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final (String title, String body, List<Widget> content) = switch (step) {
      _Step.language => (
          l10n.onbLanguageTitle,
          l10n.onbLanguageBody,
          [const LanguageOptions()],
        ),
      _Step.rhythm => (
          l10n.onbRhythmTitle,
          l10n.onbRhythmBody,
          [
            PresetPicker(
              initialWorkMinutes: _workMinutes,
              initialRestMinutes: _restMinutes,
              onChanged: (selection) => setState(() {
                _workMinutes = selection.workMinutes;
                _restMinutes = selection.restMinutes;
              }),
            ),
          ],
        ),
      _Step.look => (l10n.onbLookTitle, l10n.onbLookBody, _lookContent(r)),
      _Step.clock => (l10n.onbClockTitle, l10n.onbClockBody, _clockContent(r)),
      _Step.options => (
          l10n.onbOptionsTitle,
          l10n.onbOptionsBody,
          _optionsContent(),
        ),
    };

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: r.pagePadding,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  title,
                  style: (r.isWatch
                          ? textTheme.titleMedium
                          : textTheme.headlineMedium)
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!r.isWatch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    body,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              SizedBox(height: r.isWatch ? AppSpacing.md : AppSpacing.xxl),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _lookContent(Responsive r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      SettingsRow(
        label: context.l10n.darkTheme,
        trailing: Switch(
          value: isDark,
          onChanged: (value) {
            final theme = AdaptiveTheme.maybeOf(context);
            value ? theme?.setDark() : theme?.setLight();
            setState(() {});
          },
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AccentPicker(
        colors: Themes.colors,
        color: Themes.accent,
        swatchSize: r.isWatch ? 44 : 48,
        onChanged: _setAccent,
      ),
    ];
  }

  List<Widget> _clockContent(Responsive r) {
    return [
      SizedBox(
        height: 190 * r.scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: ClockCombo.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, i) {
            final combo = ClockCombo.values[i];
            return ClockComboCard(
              combo: combo,
              width: 148 * r.scale,
              selected: combo.style == _style &&
                  combo.color.toARGB32() == Themes.accent.toARGB32(),
              clock: _seconds,
              onTap: () => _applyCombo(combo),
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      SettingsRow(
        label: context.l10n.onbAllStyles,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _browseStyles,
      ),
    ];
  }

  List<Widget> _optionsContent() {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      ValueListenableBuilder<bool>(
        valueListenable: AppPreferences.showClock,
        builder: (context, show, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsRow(
              label: l10n.showClock,
              trailing: Switch(
                value: show,
                onChanged: AppPreferences.setShowClock,
              ),
            ),
            AnimatedSize(
              duration: Motion.medium,
              curve: Curves.easeOutCubic,
              child: show
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: ValueListenableBuilder<ClockFormat>(
                        valueListenable: AppPreferences.clockFormat,
                        builder: (context, format, _) =>
                            SegmentedButton<ClockFormat>(
                          showSelectedIcon: false,
                          // Flat: tonal fills instead of an outline.
                          style: SegmentedButton.styleFrom(
                            side: BorderSide.none,
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            foregroundColor: colorScheme.onSurface,
                            selectedBackgroundColor: colorScheme.primary,
                            selectedForegroundColor: colorScheme.onPrimary,
                          ),
                          segments: [
                            ButtonSegment(
                              value: ClockFormat.system,
                              label: Text(l10n.clockFormatAuto),
                            ),
                            ButtonSegment(
                              value: ClockFormat.h12,
                              label: Text(l10n.clockFormat12),
                            ),
                            ButtonSegment(
                              value: ClockFormat.h24,
                              label: Text(l10n.clockFormat24),
                            ),
                          ],
                          selected: {format},
                          onSelectionChanged: (s) =>
                              AppPreferences.setClockFormat(s.first),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
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
            trailing: Switch(
              value: value,
              onChanged: AppPreferences.setHaptics,
            ),
          ),
        ),
      SettingsRow(
        label: l10n.notificationsToggle,
        subtitle: l10n.notificationsHint,
        trailing: Switch(
          value: _notifications,
          onChanged: (value) {
            setState(() => _notifications = value);
            Presets.saveNotificationsEnabled(value);
          },
        ),
      ),
      ValueListenableBuilder<UiSize>(
        valueListenable: AppPreferences.uiSize,
        builder: (context, size, _) {
          final name = switch (size) {
            UiSize.small => l10n.uiSizeSmall,
            UiSize.normal => l10n.uiSizeNormal,
            UiSize.large => l10n.uiSizeLarge,
            UiSize.extraLarge => l10n.uiSizeExtraLarge,
          };
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.uiSizeTitle, style: textTheme.bodyLarge),
                    ),
                    Text(
                      name,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ),
                Slider(
                  value: size.index.toDouble(),
                  max: (UiSize.values.length - 1).toDouble(),
                  divisions: UiSize.values.length - 1,
                  label: name,
                  onChanged: (v) =>
                      AppPreferences.setUiSize(UiSize.values[v.round()]),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}
