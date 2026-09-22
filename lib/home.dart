import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/settings.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'presets.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/design/page_transition.dart';
import 'ui/organisms/countdown_dial.dart';
import 'ui/organisms/live_clock_bar.dart';
import 'ui/organisms/window_title_bar.dart';
import 'ui/templates/home_shell.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _Home();
}

class _Home extends State<Home> {
  bool _mode = false;
  bool _notificationsEnabled = true;
  bool _pinned = false;
  bool _loaded = false;
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preset = await Presets.load();
    final notificationsEnabled = await Presets.loadNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _workMinutes = preset.workMinutes;
      _restMinutes = preset.restMinutes;
      _notificationsEnabled = notificationsEnabled;
      _loaded = true;
    });
  }

  Future<void> _openSettings() async {
    final isDark =
        await AdaptiveTheme.getThemeMode().then((value) => value!.isDark);

    if (!mounted) return;
    await Navigator.of(context).push(
      appPageRoute((context) => Settings(theme: isDark)),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeShell(
      titleBar: Platform.isWindows
          ? WindowTitleBar(
              title: 'Enfo',
              onMinimize: () async {
                await windowManager.minimize();
              },
              onMaximize: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              onClose: () async {
                await windowManager.close();
              },
            )
          : null,
      liveClock: const LiveClockBar(),
      dial: !_loaded
          ? const SizedBox.shrink()
          : CountdownDial(
              mode: _mode,
              workSeconds: _workMinutes * 60,
              restSeconds: _restMinutes * 60,
              notification: _notificationsEnabled,
            ),
      bottomControls: Row(
        children: [
          AppIconButton(
            tooltip: 'Ajustes',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          if (Platform.isWindows)
            AppIconButton(
              tooltip: _pinned
                  ? 'Quitar de siempre visible'
                  : 'Mantener siempre visible',
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
                child: Icon(
                  _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  key: ValueKey(_pinned),
                ),
              ),
            ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              _mode ? Icons.title_rounded : Icons.access_time_rounded,
              key: ValueKey(_mode),
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Switch(
            value: _mode,
            onChanged: (value) {
              setState(() {
                _mode = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
