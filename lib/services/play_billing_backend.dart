import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
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
    final r = await _iap.queryProductDetails({kProProductId});
    if (r.error != null && r.productDetails.isEmpty) {
      throw StateError(r.error!.message);
    }
    // One GooglePlayProductDetails per offer. Show the base-plan price;
    // buy the free-trial offer when Play offers one (eligible users only).
    final base = <String, GooglePlayProductDetails>{};
    final trial = <String, GooglePlayProductDetails>{};
    for (final d in r.productDetails.whereType<GooglePlayProductDetails>()) {
      final i = d.subscriptionIndex;
      final offers = d.productDetails.subscriptionOfferDetails;
      if (i == null || offers == null) continue;
      final o = offers[i];
      if (o.offerId == null) {
        base[o.basePlanId] = d;
      } else if (o.pricingPhases.isNotEmpty &&
          o.pricingPhases.first.priceAmountMicros == 0) {
        trial[o.basePlanId] = d;
      }
    }
    return [
      for (final e in base.entries)
        ProPlan(
          basePlanId: e.key,
          price: e.value.price,
          hasTrial: trial.containsKey(e.key),
          handle: trial[e.key] ?? e.value,
        ),
    ];
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
