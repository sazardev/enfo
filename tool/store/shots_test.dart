// Store screenshot generator (NOT part of `flutter test`, which only scans
// test/). Renders the real app to PNGs at Google Play sizes:
//
//   flutter test tool/store/shots_test.dart
//   flutter test tool/store/shots_test.dart \
//       --dart-define=SHOTS_SCENES=01,hero --dart-define=SHOTS_DEVICES=phone
//
// Filters (all optional, comma separated):
//   SHOTS_SCENES   scene numbers or ids        (default: all)
//   SHOTS_DEVICES  phone|tablet7|tablet10 or phone/portrait  (default: all)
//   SHOTS_LANGS    en,es,...                   (default: en,es)
//   SHOTS_THEMES   dark|light                  (default: each scene's own)
//   SHOTS_OUT      output dir                  (default: store/raw)
import 'dart:convert';
import 'dart:io';

import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/modes/app_mode.dart';
import 'package:enfo/modes/clock/time_builder.dart';
import 'package:enfo/modes/mode_host.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/test_harness.dart';
import 'scene_def.dart';
import 'scenes.dart';
import 'shot_harness.dart';

const _fScenes = String.fromEnvironment('SHOTS_SCENES');
const _fDevices = String.fromEnvironment('SHOTS_DEVICES');
const _fLangs = String.fromEnvironment('SHOTS_LANGS', defaultValue: 'en,es');
const _fThemes = String.fromEnvironment('SHOTS_THEMES');
const _fStyle = String.fromEnvironment('SHOTS_STYLE');
const _fAccent = String.fromEnvironment('SHOTS_ACCENT');
const _fOut = String.fromEnvironment('SHOTS_OUT', defaultValue: 'store/raw');

List<String> _list(String s) =>
    s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

bool _sceneWanted(Scene s) {
  final f = _list(_fScenes);
  return f.isEmpty ||
      f.contains(s.id) ||
      f.contains(s.n.toString().padLeft(2, '0')) ||
      f.contains(s.n.toString());
}

bool _deviceWanted(ShotDevice d) {
  final f = _list(_fDevices);
  return f.isEmpty || f.contains(d.name) || f.contains(d.dir);
}

Map<String, Object> _basePrefs(Scene s, ShotCtx c, ShotDevice d) {
  return {
    'onboarded': true,
    'mode_order': AppMode.values.map((m) => m.name).join(','),
    'mode_seen': AppMode.values.map((m) => m.name).join(','),
    'mode_disabled': '',
    'mode_current': (s.mode ?? AppMode.pomodoro).name,
    'accent_color': s.accent.toARGB32(),
    'show_clock': false,
    if (s.smallOn.contains(d.dir)) 'ui_size': 'small',
    ...?s.prefs?.call(c),
    if (_fStyle.isNotEmpty) 'clock_style': _fStyle,
    if (_fAccent.isNotEmpty) 'accent_color': int.parse(_fAccent, radix: 16),
  };
}

String fileName(Scene s, String theme, String lang) =>
    '${s.n.toString().padLeft(2, '0')}_${s.id}_${theme}_$lang.png';

void main() {
  setUpAll(loadShotFonts);

  final today = DateTime.now();
  final frozen = DateTime(today.year, today.month, today.day, 10, 9, 0);
  final formLog = <String, String>{};
  final issues = <String>[];

  for (final scene in allScenes.where(_sceneWanted)) {
    final other = scene.theme == 'dark' ? 'light' : 'dark';
    var themes = scene.both ? [scene.theme, other] : [scene.theme];
    final tf = _list(_fThemes);
    if (tf.isNotEmpty) themes = tf;

    for (final dev in shotDevices.where(_deviceWanted)) {
      for (final theme in themes) {
        for (final lang in _list(_fLangs)) {
          final name = '${scene.n} ${scene.id} ${dev.dir} $theme $lang';
          testWidgets(name, (tester) async {
            final ctx = ShotCtx(lang, theme == 'dark', frozen);
            await resetTestState(_basePrefs(scene, ctx, dev));
            await Themes.loadAccent();
            LocaleController.locale.value = Locale(lang);
            nowProvider = () => frozen;
            await scene.seed?.call(ctx);

            tester.view.physicalSize = dev.px;
            tester.view.devicePixelRatio = dev.dpr;
            addTearDown(tester.view.reset);

            final key = GlobalKey();
            await tester.pumpWidget(shotApp(
              scene.home?.call(ctx) ?? const ModeHost(),
              dark: theme == 'dark',
              boundaryKey: key,
            ));
            await settleShot(tester);
            await scene.drive?.call(tester, ctx);
            for (var i = 0; i < scene.settleMore; i++) {
              await settleShot(tester);
            }
            final problem = tester.takeException();
            if (problem != null) {
              final first = problem.toString().split('\n').first;
              issues.add('$name: $first');
            }

            final path = '$_fOut/${dev.dir}/${fileName(scene, theme, lang)}';
            final size = await writePng(tester, key, dev.dpr, path);
            formLog['${dev.dir}'] =
                '${dev.factor.name}${dev.wide ? '+wide' : ''} '
                '${dev.logical.width.toStringAsFixed(0)}x'
                '${dev.logical.height.toStringAsFixed(0)}dp';
            expect(size, dev.px, reason: 'unexpected PNG size for $path');

            // Unmount so timers/tickers are disposed inside the test.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 50));
          });
        }
      }
    }
  }

  tearDownAll(() {
    if (formLog.isNotEmpty) {
      File('$_fOut/form_factors.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(formLog));
    }
    final log = File('$_fOut/issues.txt');
    if (issues.isNotEmpty) {
      log.createSync(recursive: true);
      log.writeAsStringSync('${issues.join('\n')}\n');
    } else if (log.existsSync()) {
      log.deleteSync();
    }
    writeManifest(_fOut);
  });
}
