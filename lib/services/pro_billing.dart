import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analytics.dart';
import 'settings_service.dart';

/// Legacy Google Play subscription product (docs/PLAY_BILLING_SETUP.md).
/// No longer sold (0.5.8+), but an active subscription still grants Pro.
const String kProProductId = 'gizlialan_pro';

/// One-time (non-consumable, INAPP) Pro purchase sold from 0.5.8.
const String kProLifetimeId = 'gizlialan_pro_lifetime';

/// [ProPlan.basePlanId] used for the one-time product.
const String kPlanLifetime = 'lifetime';

/// Shown only when Play's formatted price could not be loaded.
const String kProFallbackPrice = '499 TL';

/// Products that grant Pro: the one-time purchase and the legacy
/// subscription (existing subscribers keep Pro).
bool isProProduct(String id) => id == kProProductId || id == kProLifetimeId;

/// The purchasable Pro product as reported by Play (only the one-time
/// [kProLifetimeId] is offered; the name is historical). [price] is Play's
/// localized base-plan price string (never hardcoded in the app).
class ProPlan {
  const ProPlan({
    required this.basePlanId,
    required this.price,
    this.hasTrial = false,
    this.handle,
  });

  final String basePlanId;
  final String price;

  /// Play returned a free-trial offer for this base plan (only returned
  /// when the user is eligible).
  final bool hasTrial;

  /// Backend-specific object used by [BillingBackend.buy].
  final Object? handle;
}

enum BillingStatus { pending, purchased, restored, canceled, error }

/// A purchase update, reduced to what the entitlement logic needs.
class BillingPurchase {
  const BillingPurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
    this.raw,
  });

  final String productId;
  final BillingStatus status;

  /// Must be completed/acknowledged (Play refunds unacknowledged purchases
  /// after 3 days).
  final bool needsCompletion;
  final Object? raw;
}

/// Thin seam over the billing plugin so the entitlement logic is testable.
abstract class BillingBackend {
  Future<bool> isAvailable();

  /// The one-time Pro product ([kProLifetimeId]). Throws when Play can't
  /// be queried.
  Future<List<ProPlan>> loadPlans();

  Stream<List<BillingPurchase>> get updates;

  /// Starts the Play purchase flow; the result arrives on [updates].
  Future<void> buy(ProPlan plan);

  /// Purchases Play currently reports as owned (the one-time product, or a
  /// legacy subscription still active), or
  /// null when Play couldn't be asked (offline, service error).
  Future<List<BillingPurchase>?> ownedPurchases();

  Future<void> complete(BillingPurchase p);
}

/// Last user-visible outcome, shown once by the paywall.
enum BillingNotice {
  purchased,
  pending,
  canceled,
  error,
  unavailable,
  restored,
  nothingToRestore,
  offline,
}

/// Pro entitlement for the `play` flavor, backed by Google Play Billing.
///
/// No server: Play's own purchase state is the source of truth. The result
/// is cached in [SettingsService.playProActive] so Pro works offline and at
/// startup; [sync] (on start and on "Restore") re-queries Play and turns the
/// cache off when the subscription is gone. Pending payments never grant Pro.
class ProBilling extends ChangeNotifier {
  ProBilling(this.settings, this.backend);

  /// Set in main() for the play flavor (null in tests / full builds).
  static ProBilling? instance;

  final SettingsService settings;
  final BillingBackend backend;

  StreamSubscription<List<BillingPurchase>>? _sub;
  Completer<void>? _buying;

  bool available = false;
  bool loading = false;
  List<ProPlan> plans = const [];
  BillingNotice? notice;

  bool get isPro => settings.playProActive;

  /// Pro currently comes from the legacy subscription ([kProProductId]),
  /// as last reported by Play (only then is "manage in Play" useful).
  bool legacySubscriptionActive = false;

  ProPlan? plan(String basePlanId) {
    for (final p in plans) {
      if (p.basePlanId == basePlanId) return p;
    }
    return null;
  }

  Future<void> start() async {
    _sub ??= backend.updates.listen(
      _onUpdates,
      onError: (Object _) {
        notice = BillingNotice.error;
        _finishBuy();
        notifyListeners();
      },
    );
    loading = true;
    notifyListeners();
    try {
      available = await backend.isAvailable();
      if (available) {
        try {
          plans = await backend.loadPlans();
        } catch (_) {
          plans = const [];
        }
        await sync();
      }
    } catch (_) {
      available = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Re-queries Play. Returns false when Play couldn't be reached (the
  /// cached entitlement is kept).
  Future<bool> sync() async {
    List<BillingPurchase>? owned;
    try {
      owned = await backend.ownedPurchases();
    } catch (_) {
      owned = null;
    }
    if (owned == null) return false;
    var pro = false;
    var legacy = false;
    for (final p in owned) {
      final ok =
          isProProduct(p.productId) &&
          (p.status == BillingStatus.purchased ||
              p.status == BillingStatus.restored);
      if (ok) pro = true;
      if (ok && p.productId == kProProductId) legacy = true;
      if (ok && p.needsCompletion) await _complete(p);
    }
    legacySubscriptionActive = legacy;
    await _setPro(pro);
    return true;
  }

  Future<void> _setPro(bool v) async {
    if (settings.playProActive == v) return;
    await settings.setPlayProActive(v);
    notifyListeners();
  }

  Future<void> _complete(BillingPurchase p) async {
    try {
      await backend.complete(p);
    } catch (_) {
      // Retried on the next sync / update (Play redelivers).
    }
  }

  Future<void> _onUpdates(List<BillingPurchase> list) async {
    for (final p in list) {
      if (!isProProduct(p.productId)) {
        if (p.needsCompletion) await _complete(p);
        continue;
      }
      switch (p.status) {
        case BillingStatus.pending:
          notice = BillingNotice.pending;
        case BillingStatus.purchased:
        case BillingStatus.restored:
          if (p.productId == kProProductId) legacySubscriptionActive = true;
          await _setPro(true);
          // Pro purchase event (AppMetrica + TikTok): only a fresh,
          // not-yet-acknowledged purchase from the purchase stream — never
          // restores or re-deliveries. Analytics can't break the flow.
          if (p.status == BillingStatus.purchased &&
              p.needsCompletion &&
              p.productId == kProLifetimeId) {
            unawaited(Analytics.logProPurchase(productId: p.productId));
          }
          notice = p.status == BillingStatus.purchased
              ? BillingNotice.purchased
              : BillingNotice.restored;
        case BillingStatus.canceled:
          notice = BillingNotice.canceled;
        case BillingStatus.error:
          notice = BillingNotice.error;
      }
      if (p.needsCompletion) await _complete(p);
      if (p.status != BillingStatus.pending) _finishBuy();
    }
    if (list.any((p) => p.status == BillingStatus.pending)) _finishBuy();
    notifyListeners();
  }

  void _finishBuy() {
    final c = _buying;
    _buying = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Starts the purchase; completes when Play answered (or [timeout]).
  Future<void> buy(
    ProPlan plan, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (!available) {
      notice = BillingNotice.unavailable;
      notifyListeners();
      return;
    }
    final c = _buying = Completer<void>();
    try {
      await backend.buy(plan);
    } catch (_) {
      notice = BillingNotice.error;
      _finishBuy();
      notifyListeners();
      return;
    }
    await c.future.timeout(timeout, onTimeout: () {});
  }

  /// "Restore purchases": re-query Play for the account's Pro purchase
  /// (one-time product, or a still-active legacy subscription).
  Future<void> restore() async {
    if (!available) {
      available = await backend.isAvailable().catchError((_) => false);
      if (!available) {
        notice = BillingNotice.unavailable;
        notifyListeners();
        return;
      }
      if (plans.isEmpty) {
        try {
          plans = await backend.loadPlans();
        } catch (_) {}
      }
    }
    final reached = await sync();
    notice = !reached
        ? BillingNotice.offline
        : (isPro ? BillingNotice.restored : BillingNotice.nothingToRestore);
    notifyListeners();
  }

  /// Paywall consumes the notice once.
  BillingNotice? takeNotice() {
    final n = notice;
    notice = null;
    return n;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
