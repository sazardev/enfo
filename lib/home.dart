import 'dart:io';

import 'package:enfo/settings.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_preferences.dart';
import 'bar_buttons.dart';
import 'clock_style_page.dart';
import 'l10n/locale_controller.dart';
import 'modes/app_mode.dart';
import 'modes/mode_actions.dart';
import 'modes/mode_keys.dart';
import 'modes/platform_title_bar.dart';
import 'presets.dart';
import 'stats.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/atoms/chubby_icon.dart';
import 'ui/clock/clock_frame.dart';
import 'ui/clock/clock_style.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/responsive.dart';
import 'ui/molecules/primary_action_button.dart';
import 'ui/organisms/countdown_dial.dart';
import 'ui/organisms/live_clock_bar.dart';
import 'ui/templates/home_shell.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _Home();
}

class _Home extends State<Home> {
  bool _notificationsEnabled = true;
  bool _pinned = false;
  bool _loaded = false;
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;
  ClockStyle _clockStyle = ClockStyle.ring;
  final CountdownController _countdown = CountdownController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final preset = await Presets.load();
    final notificationsEnabled = await Presets.loadNotificationsEnabled();
    final clockStyle = await ClockStyle.load();
    if (!mounted) return;
    setState(() {
      _clockStyle = clockStyle;
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
      _notificationsEnabled = notificationsEnabled;
      _loaded = true;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      appPageRoute((context) => const Settings()),
    );

    await _load();
  }

  Future<void> _openClockStyles() async {
    await Navigator.of(context).push(
      appPageRoute((context) => ClockStylePage(selected: _clockStyle)),
    );

    await _load();
  }

  /// Horizontal swipe on the dial flips through the clock styles.
  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final style = _clockStyle.step(velocity < 0 ? 1 : -1);
    setState(() => _clockStyle = style);
    ClockStyle.save(style);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return ModeKeyBindings(
      mode: AppMode.pomodoro,
      actions: ModeKeyActions(
        primary: _loaded ? _countdown.toggle : null,
        reset: _loaded ? _countdown.reset : null,
      ),
      child: HomeShell(
        titleBar: platformTitleBar(),
        liveClock: ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.showClock,
          builder: (context, show, _) => show
              ? LiveClockBar(fontSize: responsive.isWide ? 22 : 14)
              : const SizedBox.shrink(),
        ),
        dial: !_loaded
            ? const SizedBox.shrink()
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: _handleSwipe,
                child: CountdownDial(
                  style: _clockStyle,
                  controller: _countdown,
                  workSeconds: _workMinutes * 60,
                  restSeconds: _restMinutes * 60,
                  notification: _notificationsEnabled,
                ),
              ),
        primaryAction: ValueListenableBuilder<ClockPhase>(
          valueListenable: _countdown,
          builder: (context, phase, _) => PrimaryActionButton(
            running: phase == ClockPhase.running,
            label: switch (phase) {
              ClockPhase.idle => context.l10n.timerStart,
              ClockPhase.running => context.l10n.timerPause,
              ClockPhase.paused => context.l10n.timerResume,
            },
            onPressed: _countdown.toggle,
            enabled: _loaded,
          ),
        ),
        actions: [
          AppIconButton(
            tooltip: context.l10n.tooltipSettings,
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          BarButtonVisibility(
            button: BarButton.stats,
            child: AppIconButton(
              tooltip: context.l10n.tooltipStats,
              onPressed: () => Navigator.of(context)
                  .push(appPageRoute((context) => const Stats())),
              icon: const Icon(Icons.bar_chart_rounded),
            ),
          ),
          // A watch keeps only settings + stats.
          if (!responsive.isWatch)
            BarButtonVisibility(
              button: BarButton.clockStyle,
              child: AppIconButton(
                tooltip: context.l10n.tooltipClockStyle,
                onPressed: _openClockStyles,
                icon: const Icon(Icons.timelapse_rounded),
              ),
            ),
          const ModeActionButtons(),
          if (Platform.isWindows && !responsive.isWatch)
            AppIconButton(
              tooltip:
                  _pinned ? context.l10n.tooltipUnpin : context.l10n.tooltipPin,
              selected: _pinned,
              onPressed: () async {
                setState(() {
                  _pinned = !_pinned;
                });
                await windowManager.setAlwaysOnTop(_pinned);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: ChubbyIcon(
                  _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  key: ValueKey(_pinned),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
