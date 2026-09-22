import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'home.dart';
import 'onboarding.dart';
import 'presets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final prefs = await SharedPreferences.getInstance();
  final onboarded = await Presets.isOnboarded();

  Themes.defaultIndex = prefs.getInt('defaultIndex') ?? 10;

  if (Platform.isAndroid) {
    MobileAds.instance.initialize();
  }

  runApp(
    Main(
      savedThemeMode: savedThemeMode,
      onboarded: onboarded,
    ),
  );

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(450, 450),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      center: true,
      title: 'Enfo',
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(310, 280),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }
}

class Main extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final bool onboarded;

  const Main({
    super.key,
    this.savedThemeMode,
    required this.onboarded,
  });

  @override
  State<StatefulWidget> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: Themes.light(Themes.defaultIndex),
        dark: Themes.dark(Themes.defaultIndex),
        initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
        builder: (theme, darkTheme) {
          return MaterialApp(
            title: "Enfo",
            theme: theme,
            darkTheme: darkTheme,
            home: widget.onboarded ? const Home() : const Onboarding(),
          );
        });
  }
}
