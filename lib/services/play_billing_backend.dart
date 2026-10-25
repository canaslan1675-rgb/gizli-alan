import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show ProductType;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'pro_billing.dart';

/// [BillingBackend] on the official `in_app_purchase` plugin (Play Billing).
class PlayBillingBackend implements BillingBackend {
  PlayBillingBackend([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<ProPlan>> loadPlans() async {
    // Only the one-time product is sold (0.5.8+); the legacy subscription
    // is still recognised in ownedPurchases() but no longer offered.
    final r = await _iap.queryProductDetails({kProLifetimeId});
    if (r.error != null && r.productDetails.isEmpty) {
      throw StateError(r.error!.message);
    }
    final out = <ProPlan>[];
    for (final d in r.productDetails.whereType<GooglePlayProductDetails>()) {
      if (d.id == kProLifetimeId &&
          d.productDetails.productType == ProductType.inapp) {
        out.add(ProPlan(basePlanId: kPlanLifetime, price: d.price, handle: d));
      }
    }
    return out;
  }

  @override
  Stream<List<BillingPurchase>> get updates =>
      _iap.purchaseStream.map((l) => l.map(_map).toList());

  static BillingPurchase _map(PurchaseDetails p) => BillingPurchase(
    productId: p.productID,
    status: switch (p.status) {
      PurchaseStatus.pending => BillingStatus.pending,
      PurchaseStatus.purchased => BillingStatus.purchased,
      PurchaseStatus.restored => BillingStatus.restored,
      PurchaseStatus.canceled => BillingStatus.canceled,
      PurchaseStatus.error => BillingStatus.error,
    },
    // Past purchases come without pendingCompletePurchase: acknowledge any
    // owned purchase Play still reports as unacknowledged.
    needsCompletion:
        p.pendingCompletePurchase ||
        (p is GooglePlayPurchaseDetails &&
            !p.billingClientPurchase.isAcknowledged &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored)),
    raw: p,
  );

  @override
  Future<void> buy(ProPlan plan) async {
    final d = plan.handle as GooglePlayProductDetails;
    await _iap.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: d,
        // null for the one-time (INAPP) product.
        offerToken: d.offerToken,
      ),
    );
  }

  @override
  Future<List<BillingPurchase>?> ownedPurchases() async {
    final add = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final r = await add.queryPastPurchases();
    if (r.error != null) return null;
    return r.pastPurchases.map(_map).toList();
  }

  @override
  Future<void> complete(BillingPurchase p) async {
    final raw = p.raw;
    if (raw is PurchaseDetails) await _iap.completePurchase(raw);
  }
}
