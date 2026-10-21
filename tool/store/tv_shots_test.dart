// TV store screenshot generator (NOT part of `flutter test`).
//
//   flutter test tool/store/tv_shots_test.dart
//   flutter test tool/store/tv_shots_test.dart --dart-define=TV_SHOTS_LANGS=en
//
// Renders the real app at 1920x1080 (960x540 dp, 2x) with the TV focus ring,
// overscan padding and hint bar. Output: store/tv/screenshots/<lang>/.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/clock_prefs.dart';
import 'package:enfo/modes/fullscreen.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/modes/mode_prefs.dart';
import 'package:enfo/modes/modes_page.dart';
import 'package:enfo/modes/timer/timer_mode_page.dart';
import 'package:enfo/settings.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/tv/tv_focus_hint.dart';
import 'package:enfo/tv/tv_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/test_harness.dart';
import 'shot_harness.dart';

const _langs = String.fromEnvironment('TV_SHOTS_LANGS', defaultValue: 'en,es');
const _out = String.fromEnvironment(
  'TV_SHOTS_OUT',
  defaultValue: 'store/tv/screenshots',
);

List<String> _list(String s) =>
    s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

class _Shot {
  const _Shot(this.id, this.build, {this.settle = 0, this.seed});

  final String id;
  final Widget Function() build;
  final int settle;
  final Future<void> Function()? seed;
}

final _shots = <_Shot>[
  _Shot('01_pomodoro', () => const ModeHost()),
  _Shot('02_timer', () => const TimerModePage()),
  _Shot('03_settings', () => const Settings()),
  _Shot('04_modes', () => const ModesPage()),
  _Shot('05_fullscreen_clock', () {
    ModePrefs.current.value = AppMode.clock;
    Fullscreen.active.value = true;
    return const ModeHost();
  }, seed: () async {
    await ClockPrefs.load();
  }, settle: 5),
];

void main() {
  setUpAll(loadShotFonts);

  for (final lang in _list(_langs)) {
    for (final shot in _shots) {
      testWidgets('${shot.id}_$lang', (tester) async {
        TvMode.debugIsTv = true;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        TvFocusHint.reset();
        addTearDown(() {
          TvMode.debugIsTv = null;
          Fullscreen.active.value = false;
          TvFocusHint.reset();
        });
        await resetTestState({
          'onboarded': true,
          'mode_order': AppMode.values.map((m) => m.name).join(','),
          'mode_seen': AppMode.values.map((m) => m.name).join(','),
          'mode_disabled':
              AppMode.values.where((m) => !m.core).map((m) => m.name).join(','),
          'mode_current': AppMode.pomodoro.name,
          'accent_color': Themes.defaultAccent.toARGB32(),
          'show_clock': true,
        });
        await shot.seed?.call();
        LocaleController.locale.value = Locale(lang);
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final key = GlobalKey();
        await tester.pumpWidget(
          shotApp(shot.build(), dark: true, boundaryKey: key),
        );
        await settleShot(tester);
        for (var i = 0; i < shot.settle; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);

        final path = '$_out/$lang/${shot.id}.png';
        final size = await writePng(tester, key, 2, path);
        expect(size, const Size(1920, 1080));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
        TvMode.debugIsTv = null;
        Fullscreen.active.value = false;
        TvFocusHint.reset();
      });
    }
  }
}
