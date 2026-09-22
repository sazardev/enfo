import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:enfo/secret.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'accent_color_page.dart';
import 'presets.dart';
import 'ui/atoms/app_icon_button.dart';
import 'ui/atoms/bouncy_tap.dart';
import 'ui/design/page_transition.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/organisms/preset_picker.dart';
import 'ui/templates/settings_shell.dart';

class Settings extends StatefulWidget {
  final bool theme;
  const Settings({
    super.key,
    required this.theme,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late bool _theme = widget.theme;
  int _workMinutes = Presets.classic.workMinutes;
  int _restMinutes = Presets.classic.restMinutes;
  bool _notificationsEnabled = true;
  bool _loaded = false;
  late int _accentIndex = Themes.defaultIndex;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
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

  void _createInterstitialAd() {
    if (Platform.isAndroid) {
      InterstitialAd.load(
        adUnitId: admob_id,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitialAd = ad,
          onAdFailedToLoad: (error) =>
              debugPrint('Failed to load interstitial ad: $error'),
        ),
      );
    }
  }

  Future<void> _pickAccentColor() async {
    final index = await Navigator.of(context).push<int>(
      appPageRoute(
        (context) => AccentColorPage(
          colors: Themes.colors,
          selectedIndex: _accentIndex,
        ),
      ),
    );
    if (index == null || !mounted) return;

    setState(() {
      _accentIndex = index;
      AdaptiveTheme.of(context).setTheme(
        light: Themes.changeTheme(index, false),
        dark: Themes.changeTheme(index, true),
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultIndex', index);
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: 'Ajustes',
      loaded: _loaded,
      children: [
        SettingsRow(
          label: 'Tema oscuro',
          trailing: Switch(
            value: _theme,
            onChanged: (bool value) {
              setState(() {
                if (value) {
                  AdaptiveTheme.of(context).setDark();
                } else {
                  AdaptiveTheme.of(context).setLight();
                }
                _theme = value;
              });
            },
          ),
        ),
        SettingsRow(
          label: 'Notificaciones',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await Presets.saveNotificationsEnabled(value);
            },
          ),
        ),
        SettingsRow(
          label: 'Color de acento',
          trailing: BouncyTap(
            onTap: _pickAccentColor,
            pressedScale: 0.88,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const Divider(height: 32),
        Text(
          'Ritmo de enfoque',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        PresetPicker(
          initialWorkMinutes: _workMinutes,
          initialRestMinutes: _restMinutes,
          onChanged: (selection) async {
            setState(() {
              _workMinutes = selection.workMinutes;
              _restMinutes = selection.restMinutes;
            });
            await Presets.save(
              workMinutes: selection.workMinutes,
              restMinutes: selection.restMinutes,
            );
          },
        ),
        const Divider(height: 32),
        SettingsRow(
          label: 'Invítame un café',
          trailing: AppIconButton(
            icon: const Icon(Icons.coffee_rounded),
            onPressed: () async {
              const url = 'https://www.buymeacoffee.com/sazarcode';
              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: Platform.isAndroid
                      ? LaunchMode.externalApplication
                      : LaunchMode.platformDefault,
                );
              }
            },
          ),
        ),
        if (Platform.isAndroid)
          SettingsRow(
            label: 'Ver un anuncio para ayudar',
            trailing: AppIconButton(
              icon: const Icon(Icons.attach_money_rounded),
              onPressed: () {
                if (_interstitialAd == null) {
                  return;
                }
                _interstitialAd!.fullScreenContentCallback =
                    FullScreenContentCallback(
                  onAdDismissedFullScreenContent: (ad) {
                    ad.dispose();
                    _createInterstitialAd();
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                    ad.dispose();
                    _createInterstitialAd();
                  },
                );
                _interstitialAd!.show();
              },
            ),
          ),
      ],
    );
  }
}
