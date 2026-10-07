import 'dart:async';

import 'package:enfo/donate_page.dart';
import 'package:enfo/l10n/gen/app_localizations.dart';
import 'package:enfo/l10n/locale_controller.dart';
import 'package:enfo/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show InAppPurchase;
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

class _FakeIap extends InAppPurchasePlatform {
  _FakeIap(this.products, {this.available = true});

  final List<ProductDetails> products;
  final bool available;
  final StreamController<List<PurchaseDetails>> _purchases =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<PurchaseDetails> completed = [];
  final List<PurchaseParam> bought = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [
        for (final p in products)
          if (identifiers.contains(p.id)) p,
      ],
      notFoundIDs: [
        for (final id in identifiers)
          if (!products.any((p) => p.id == id)) id,
      ],
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    bought.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  void emit(List<PurchaseDetails> purchases) => _purchases.add(purchases);
}

ProductDetails _product(String id, String title, String price) {
  return ProductDetails(
    id: id,
    title: title,
    description: 'One-time donation',
    price: price,
    rawPrice: 1,
    currencyCode: 'USD',
  );
}

Widget _app() {
  return ValueListenableBuilder<Locale?>(
    valueListenable: LocaleController.locale,
    builder: (context, locale, _) => MaterialApp(
      theme: Themes.light(Themes.accent),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DonatePage(),
    ),
  );
}

void main() {
  testWidgets('donation tiers come from the store with their prices',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      // Force the singleton first: its first creation registers the real
      // Android plugin and would otherwise overwrite the fake below.
      InAppPurchase.instance;
      InAppPurchasePlatform.instance = _FakeIap([
        _product('enfo_donate_1', 'Donate 1', r'$1.00'),
        _product('enfo_donate_5', 'Donate 5', r'$5.00'),
        _product('enfo_donate_25', 'Donate 25', r'$25.00'),
      ]);
      LocaleController.locale.value = const Locale('en');
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Donate 1'), findsOneWidget);
      expect(find.text(r'$5.00'), findsOneWidget);
      expect(find.text('Donate 25'), findsOneWidget);
      expect(find.text('Donate 3'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a purchase is completed and thanked', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final fake = _FakeIap([_product('enfo_donate_1', 'Donate 1', r'$1.00')]);
      InAppPurchasePlatform.instance = fake;
      LocaleController.locale.value = const Locale('en');
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Donate 1'));
      await tester.pumpAndSettle();
      expect(fake.bought, hasLength(1));

      final details = PurchaseDetails(
        productID: 'enfo_donate_1',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true;
      fake.emit([details]);
      await tester.pumpAndSettle();

      expect(fake.completed, hasLength(1));
      expect(find.text('Thank you for supporting Enfo!'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('without store products the page points at the coffee link',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      InAppPurchasePlatform.instance = _FakeIap(const [], available: false);
      LocaleController.locale.value = const Locale('en');
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Donations are not available right now. You can still buy me a coffee.',
        ),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
