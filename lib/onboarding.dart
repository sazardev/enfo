import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'haptics/haptic_events.dart';
import 'haptics/haptics.dart';
import 'clock_style_page.dart';
import 'modes/app_mode.dart';
import 'modes/clock/clock_prefs.dart';
import 'modes/clock/clock_settings_page.dart';
import 'modes/clock/faces.dart';
import 'modes/clock/time_builder.dart';
import 'modes/fullscreen.dart';
import 'modes/mode_host.dart';
import 'modes/mode_prefs.dart';
import 'modes/notifier.dart';
import 'l10n/locale_controller.dart';
import 'presets.dart';
import 'theme.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/brand/enfo_mark.dart';
import 'ui/clock/clock_combo.dart';
import 'ui/clock/clock_frame.dart';
import 'ui/clock/clock_style.dart';
import 'ui/clock/clock_style_l10n.dart';
import 'ui/clock/clock_view.dart';
import 'ui/design/motion.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/responsive.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/clock_combo_card.dart';
import 'ui/molecules/clock_style_tile.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/molecules/theme_mode_selector.dart';
import 'ui/organisms/accent_picker.dart';
import 'ui/organisms/language_options.dart';
import 'ui/organisms/preset_picker.dart';
import 'ui/atoms/app_switch.dart';

enum _Step {
  welcome,
  language,
  modes,
  rhythm,
  look,
  display,
  options,
  permissions,
}

/// First-run setup, as a wizard: language, which modes to use, rhythm,
/// theme + accent (with a live preview), clock look, display, behavior and
/// (on Android) the notification permissions. Steps that do not apply are
/// left out (no rhythm without Pomodoro, no permissions on desktop). Every
/// choice is applied the moment it is made and stays editable later in
/// Settings. Watches only get language and rhythm.
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
  bool _notifAllowed = false;
  bool _exactAllowed = false;
  bool _lastModeBlocked = false;

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
    final notifAllowed = await Notifier.notificationsAllowed();
    final exactAllowed = await Notifier.exactAlarmsAllowed();
    if (!mounted) return;
    setState(() {
      _notifAllowed = notifAllowed;
      _exactAllowed = exactAllowed;
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

  bool _on(AppMode mode) => ModePrefs.enabled.contains(mode);

  List<_Step> _steps(Responsive r) {
    if (r.isWatch) {
      return [
        _Step.welcome,
        _Step.language,
        if (_on(AppMode.pomodoro)) _Step.rhythm,
      ];
    }
    final hasOptions =
        _on(AppMode.pomodoro) || _on(AppMode.clock) || Haptics.available;
    return [
      for (final step in _Step.values)
        if (switch (step) {
          _Step.rhythm => _on(AppMode.pomodoro),
          _Step.options => hasOptions,
          _Step.permissions => Notifier.canAskPermissions,
          _ => true,
        })
          step,
    ];
  }

  /// Steps that show animated clock previews.
  bool _animated(_Step step) => step == _Step.look;

  Future<void> _go(int index, List<_Step> steps) async {
    if (index < 0 || index >= steps.length) return;
    Haptics.transition();
    setState(() => _index = index);

    if (_animated(steps[index]) && !MediaQuery.disableAnimationsOf(context)) {
      if (!_clock.isAnimating) _clock.forward();
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
    Haptics.success();
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

    if (step == _Step.welcome) return const _WelcomeHero();

    final (String title, String body, List<Widget> content) = switch (step) {
      _Step.welcome => ('', '', const <Widget>[]),
      _Step.language => (
          l10n.onbLanguageTitle,
          l10n.onbLanguageBody,
          [const LanguageOptions()],
        ),
      _Step.modes => (
          l10n.onbModesTitle,
          l10n.onbModesBody,
          _modesContent(),
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
      _Step.display => (
          l10n.onbDisplayTitle,
          l10n.onbDisplayBody,
          _displayContent(r),
        ),
      _Step.options => (
          l10n.onbOptionsTitle,
          l10n.onbOptionsBody,
          _optionsContent(),
        ),
      _Step.permissions => (
          l10n.onbPermTitle,
          l10n.onbPermBody,
          _permissionsContent(),
        ),
    };

    // The look step's preview is pinned under the scrolling picker when
    // there is height for it; otherwise it simply ends the list.
    final pinPreview = step == _Step.look && !r.isWatch && r.size.height >= 560;
    final preview = step == _Step.look
        ? _LookPreview(style: _style, clock: _seconds)
        : null;

    final scroll = SingleChildScrollView(
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
              if (preview != null && !pinPreview) ...[
                const SizedBox(height: AppSpacing.xl),
                preview,
              ],
            ],
          ),
        ),
      ),
    );

    if (!pinPreview) return scroll;
    return Column(
      children: [
        Expanded(child: scroll),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.contentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
              child: preview,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _modesContent() {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      ValueListenableBuilder<Set<AppMode>>(
        valueListenable: ModePrefs.disabled,
        builder: (context, disabled, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in AppMode.values.where((m) => m.core))
              _modeRow(mode, disabled),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.onbMoreTools,
                style: textTheme.labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            for (final mode in AppMode.values.where((m) => !m.core))
              _modeRow(mode, disabled),
          ],
        ),
      ),
      if (_lastModeBlocked)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            l10n.modesAtLeastOne,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ),
    ];
  }

  Widget _modeRow(AppMode mode, Set<AppMode> disabled) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return SettingsRow(
      label: mode.labelOf(l10n),
      subtitle: mode.descriptionOf(l10n),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          AppSwitch(
            value: !disabled.contains(mode),
            onChanged: (on) async {
              final ok = await ModePrefs.setEnabled(mode, on);
              if (!mounted) return;
              // Steps depend on the modes chosen.
              setState(() => _lastModeBlocked = !ok);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _lookContent(Responsive r) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: ThemeModeSelector(onChanged: () => setState(() {})),
      ),
      const SizedBox(height: AppSpacing.xl),
      ..._comboContent(r),
      const SizedBox(height: AppSpacing.xl),
      Padding(
        padding:
            const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.md),
        child: Text(
          context.l10n.accentColor,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
      AccentPicker(
        colors: Themes.colors,
        color: Themes.accent,
        swatchSize: r.isWatch ? 44 : 48,
        onChanged: _setAccent,
      ),
    ];
  }

  List<Widget> _comboContent(Responsive r) {
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

  List<Widget> _displayContent(Responsive r) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      if (_on(AppMode.clock)) ...[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            l10n.onbClockModeDesign,
            style: textTheme.labelLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: 170 * r.scale,
          child: TimeBuilder(
            builder: (context, now) => ValueListenableBuilder<ClockFace>(
              valueListenable: ClockPrefs.face,
              builder: (context, current, _) => ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: ClockFace.values.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) {
                  final face = ClockFace.values[i];
                  return SizedBox(
                    width: 150 * r.scale,
                    child: ClockFaceTile(
                      face: face,
                      selected: face == current,
                      data: FaceData.of(context, now, compact: true),
                      onTap: () => ClockPrefs.setFace(face),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      ValueListenableBuilder<bool>(
        valueListenable: AppPreferences.showClock,
        builder: (context, show, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsRow(
              label: l10n.showClock,
              trailing: AppSwitch(
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
                  onChanged: (v) {
                    final next = UiSize.values[v.round()];
                    if (next != size) Haptics.tick();
                    AppPreferences.setUiSize(next);
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _optionsContent() {
    final l10n = context.l10n;

    return [
      if (_on(AppMode.pomodoro))
        ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.autoStartNext,
          builder: (context, value, _) => SettingsRow(
            label: l10n.autoStartNext,
            subtitle: l10n.autoStartNextHint,
            trailing: AppSwitch(
              value: value,
              onChanged: AppPreferences.setAutoStartNext,
            ),
          ),
        ),
      if (_on(AppMode.clock))
        ValueListenableBuilder<bool>(
          valueListenable: Fullscreen.keepClockAwake,
          builder: (context, value, _) => SettingsRow(
            label: l10n.clockKeepAwake,
            subtitle: l10n.clockKeepAwakeHint,
            trailing: AppSwitch(
              value: value,
              onChanged: Fullscreen.setKeepClockAwake,
            ),
          ),
        ),
      if (Haptics.available)
        ValueListenableBuilder<bool>(
          valueListenable: Haptics.enabled,
          builder: (context, value, _) => SettingsRow(
            label: l10n.hapticFeedback,
            subtitle: l10n.hapticFeedbackHint,
            trailing: AppSwitch(
              value: value,
              // Feel the setting the moment it is turned on.
              onChanged: (on) {
                Haptics.setEnabled(on);
                if (on) Haptics.preview(HapticEvents.success);
              },
            ),
          ),
        ),
    ];
  }

  Widget _permissionButton(bool allowed, VoidCallback onPressed) {
    final l10n = context.l10n;
    if (allowed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(l10n.onbPermAllowed),
        ],
      );
    }
    return FilledButton.tonal(
        onPressed: onPressed, child: Text(l10n.onbPermAllow));
  }

  List<Widget> _permissionsContent() {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SettingsRow(
        label: l10n.onbPermNotifications,
        subtitle: l10n.onbPermNotificationsHint,
        trailing: _permissionButton(_notifAllowed, () async {
          final ok = await Notifier.requestNotifications();
          if (mounted) setState(() => _notifAllowed = ok);
        }),
      ),
      if (_on(AppMode.alarm) || _on(AppMode.timer))
        SettingsRow(
          label: l10n.onbPermExact,
          subtitle: l10n.onbPermExactHint,
          trailing: _permissionButton(_exactAllowed, () async {
            final ok = await Notifier.requestExactAlarms();
            if (mounted) setState(() => _exactAllowed = ok);
          }),
        ),
      if (_on(AppMode.pomodoro))
        SettingsRow(
          label: l10n.notificationsToggle,
          subtitle: l10n.notificationsHint,
          trailing: AppSwitch(
            value: _notifications,
            onChanged: (value) {
              setState(() => _notifications = value);
              Presets.saveNotificationsEnabled(value);
            },
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: Text(
          l10n.onbPermLater,
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    ];
  }
}

/// The current clock style, dressed in the current theme + accent, so color
/// and theme choices are seen on the real thing as they are made.
class _LookPreview extends StatelessWidget {
  const _LookPreview({required this.style, required this.clock});

  final ClockStyle style;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = ClockPalette.of(colorScheme, rest: false, paused: false);
    final still = MediaQuery.disableAnimationsOf(context);
    final labels = ClockLabels.of(l10n);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110 * r.scale,
            height: 110 * r.scale,
            child: AnimatedBuilder(
              animation: clock,
              builder: (context, _) => ClockView(
                style: style,
                fill: 0.95,
                palette: palette,
                frame: demoFrame(
                  seconds: clock.value,
                  still: still,
                  labels: labels,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onbPreview,
                  style: textTheme.labelMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  style.labelOf(l10n),
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: 8,
                  width: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The first thing a new user sees: the logo builds itself, then the welcome
/// line and the tagline rise in one after the other. Replays only when the
/// wizard is opened again; with reduced motion it simply shows the result.
class _WelcomeHero extends StatefulWidget {
  const _WelcomeHero();

  @override
  State<_WelcomeHero> createState() => _WelcomeHeroState();
}

class _WelcomeHeroState extends State<_WelcomeHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final Animation<double> _mark = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.08, 0.62),
  );
  late final Animation<double> _word = _rise(0.55, 0.72);
  late final Animation<double> _title = _rise(0.66, 0.84);
  late final Animation<double> _tagline = _rise(0.78, 0.96);
  bool _started = false;

  Animation<double> _rise(double a, double b) => CurvedAnimation(
        parent: _c,
        curve: Interval(a, b, curve: Curves.easeOutCubic),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _reveal(Animation<double> a, Widget child) => AnimatedBuilder(
        animation: a,
        builder: (context, child) => Opacity(
          opacity: a.value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - a.value)),
            child: child,
          ),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final compact = r.isWatch || r.size.height < 480;
    final markSize = compact
        ? (r.size.shortestSide * 0.36).clamp(64.0, 140.0)
        : (r.size.shortestSide * 0.4).clamp(120.0, 240.0);

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.contentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EnfoMark(progress: _mark, size: markSize),
                  SizedBox(height: markSize * 0.2),
                  _reveal(
                    _word,
                    Text(
                      'enfo',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                  _reveal(
                    _title,
                    Text(
                      l10n.onbWelcomeTitle,
                      textAlign: TextAlign.center,
                      style:
                          (r.isWatch ? text.titleMedium : text.headlineMedium)
                              ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _reveal(
                    _tagline,
                    Text(
                      l10n.onbWelcomeTagline,
                      textAlign: TextAlign.center,
                      style: text.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
