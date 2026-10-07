import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'donate_page.dart';
import 'l10n/locale_controller.dart';
import 'ui/design/page_transition.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

/// Ways to support the app: rate it, share it or buy a coffee.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.sazarcode.enfo';

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
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

  Future<void> _openDonate() async {
    await Navigator.of(context).push(appPageRoute((_) => const DonatePage()));
  }

  Future<void> _openStore() async {
    try {
      await launchUrl(
        Uri.parse(SupportPage.storeUrl),
        mode: Platform.isAndroid
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );
    } catch (_) {
      // No browser or no store: nothing else to do.
    }
  }

  /// Play's in-app review sheet on Android; the store listing elsewhere.
  Future<void> _rate() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
          return;
        }
      } catch (_) {
        // Fall through to the store listing.
      }
    }
    await _openStore();
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: l10n.shareMessage(SupportPage.storeUrl),
          subject: l10n.appTitle,
        ),
      );
    } catch (_) {
      await _openStore();
    }
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
        if (defaultTargetPlatform == TargetPlatform.android)
          SettingsRow(
            label: l10n.donateTitle,
            subtitle: l10n.donateSubtitle,
            onTap: _openDonate,
            trailing: const Icon(Icons.volunteer_activism_outlined),
          ),
        SettingsRow(
          label: l10n.rateApp,
          onTap: _rate,
          trailing: const Icon(Icons.star_outline_rounded),
        ),
        SettingsRow(
          label: l10n.shareApp,
          onTap: _share,
          trailing: const Icon(Icons.ios_share_rounded),
        ),
        SettingsRow(
          label: l10n.buyCoffee,
          onTap: _openCoffee,
          trailing: const Icon(Icons.coffee_rounded),
        ),
      ],
    );
  }
}
