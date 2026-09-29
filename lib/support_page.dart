import 'dart:io';

import 'package:enfo/secret.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/locale_controller.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

/// Ways to support the app: a coffee link and (Android only) an interstitial
/// ad.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    if (!Platform.isAndroid) return;
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

  Future<void> _openCoffee() async {
    final uri = Uri.parse('https://www.buymeacoffee.com/sazarcode');
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: Platform.isAndroid
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    }
  }

  void _showAd() {
    final ad = _interstitialAd;
    if (ad == null) return;
    // The ad is single-use: drop the reference so a second tap can't show a
    // disposed ad, then preload the next one once this one closes.
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _createInterstitialAd();
      },
    );
    ad.show();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsShell(
      title: l10n.supportTitle,
      loaded: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            l10n.supportHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        SettingsRow(
          label: l10n.buyCoffee,
          onTap: _openCoffee,
          trailing: const Icon(Icons.coffee_rounded),
        ),
        if (Platform.isAndroid)
          SettingsRow(
            label: l10n.watchAd,
            onTap: _showAd,
            trailing: const Icon(Icons.attach_money_rounded),
          ),
      ],
    );
  }
}
