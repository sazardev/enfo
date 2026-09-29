// Helpers for tool/store/shots_test.dart: device specs, fonts, the app
// wrapper and the PNG capture. Not part of the normal test suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/app_preferences.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/modes/app_shortcuts.dart';
import 'package:enfo/theme.dart';
import 'package:enfo/ui/design/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// One Google Play screenshot target.
class ShotDevice {
  const ShotDevice(this.name, this.orientation, this.px, this.dpr);

  final String name;
  final String orientation; // portrait | landscape
  final Size px;
  final double dpr;

  Size get logical => Size(px.width / dpr, px.height / dpr);
  FormFactor get factor => Responsive.fromSize(logical).factor;
  bool get wide => Responsive.fromSize(logical).isWide;

  String get dir => '$name/$orientation';
}

const shotDevices = <ShotDevice>[
  ShotDevice('phone', 'portrait', Size(1080, 1920), 2.7),
  ShotDevice('phone', 'landscape', Size(1920, 1080), 2.2),
  ShotDevice('tablet7', 'portrait', Size(1200, 1920), 2.0),
  ShotDevice('tablet7', 'landscape', Size(1920, 1200), 2.0),
  ShotDevice('tablet10', 'portrait', Size(1600, 2560), 2.0),
  ShotDevice('tablet10', 'landscape', Size(2560, 1600), 2.0),
];

String flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory(env).existsSync()) return env;
  final r = Process.runSync('sh', [
    '-c',
    r'dirname $(dirname $(readlink -f $(which flutter)))',
  ]);
  return (r.stdout as String).trim();
}

/// GeistMono (as the app ships it) + the Material icon font (test default
/// shows boxes).
Future<void> loadShotFonts() async {
  final geist = FontLoader('GeistMono');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    geist.addFont(rootBundle.load('assets/fonts/GeistMono-$w.ttf'));
  }
  await geist.load();

  final file = File(
      '${flutterRoot()}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final bytes = file.readAsBytesSync();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await icons.load();
}

/// MaterialApp wired like main() (see test/test_harness.dart testApp) but
/// with a chosen theme mode, wrapped in the capture boundary.
Widget shotApp(Widget home, {required bool dark, required Key boundaryKey}) {
  return RepaintBoundary(
    key: boundaryKey,
    child: AdaptiveTheme(
      light: Themes.light(Themes.accent),
      dark: Themes.dark(Themes.accent),
      initial: dark ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => ValueListenableBuilder<UiSize>(
            valueListenable: AppPreferences.uiSize,
            builder: (context, _, __) {
              final media = MediaQuery.of(context);
              final scale = Responsive.of(context).scale;
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(scale)),
                child: IconTheme.merge(
                  data: IconThemeData(size: 24 * scale),
                  child: AppShortcuts(child: child!),
                ),
              );
            },
          ),
          home: home,
        ),
      ),
    ),
  );
}

Future<void> settleShot(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Renders the boundary to a PNG file; returns the pixel size written.
Future<Size> writePng(
    WidgetTester tester, GlobalKey key, double dpr, String path) async {
  late Size size;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: dpr);
    size = Size(image.width.toDouble(), image.height.toDouble());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File(path)..createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
  return size;
}
