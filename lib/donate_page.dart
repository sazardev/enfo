import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'l10n/locale_controller.dart';
import 'ui/design/spacing.dart';
import 'ui/molecules/settings_row.dart';
import 'ui/templates/settings_shell.dart';

/// Consumable product ids, in display order. Create them in Play Console
/// (Monetise > Products > In-app products) as one-time products with the
/// same ids; the app shows whatever the store returns, with its price.
const donationProductIds = <String>[
  'enfo_donate_1',
  'enfo_donate_3',
  'enfo_donate_5',
  'enfo_donate_10',
  'enfo_donate_25',
];

/// One-time donations through Google Play Billing (Android only).
class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = const [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _subscription = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      if (!await _iap.isAvailable()) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final response =
          await _iap.queryProductDetails(donationProductIds.toSet());
      final byId = {for (final p in response.productDetails) p.id: p};
      if (!mounted) return;
      setState(() {
        _products = [
          for (final id in donationProductIds)
            if (byId[id] != null) byId[id]!,
        ];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          if (mounted) setState(() => _message = context.l10n.donateThanks);
        case PurchaseStatus.pending:
          if (mounted) setState(() => _message = context.l10n.donatePending);
        case PurchaseStatus.error:
          if (mounted) setState(() => _message = context.l10n.donateError);
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  Future<void> _buy(ProductDetails product) async {
    try {
      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      if (mounted) setState(() => _message = context.l10n.donateError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canDonate = _products.isNotEmpty;

    return SettingsShell(
      title: l10n.donateTitle,
      loaded: !_loading,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            canDonate ? l10n.donateHint : l10n.donateUnavailable,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        for (final product in _products)
          SettingsRow(
            label: product.title.isEmpty ? product.id : product.title,
            subtitle: product.description.isEmpty ? null : product.description,
            onTap: () => _buy(product),
            trailing: Text(
              product.price,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: colorScheme.primary),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              _message!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.primary),
            ),
          ),
      ],
    );
  }
}
