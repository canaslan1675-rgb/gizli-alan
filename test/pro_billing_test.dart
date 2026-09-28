import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/services/pro_billing.dart';
import 'package:gizlialan/services/pro_entitlement.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/widgets/pro_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBilling implements BillingBackend {
  bool available = true;
  bool plansThrow = false;
  List<BillingPurchase>? owned = const [];
  bool buyThrows = false;
  final bought = <String>[];
  final completed = <BillingPurchase>[];
  final ctrl = StreamController<List<BillingPurchase>>.broadcast();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProPlan>> loadPlans() async {
    if (plansThrow) throw StateError('offline');
    return const [
      ProPlan(basePlanId: kPlanMonthly, price: '₺150,00', hasTrial: true),
      ProPlan(basePlanId: kPlanYearly, price: '₺999,00'),
    ];
  }

  @override
  Stream<List<BillingPurchase>> get updates => ctrl.stream;

  @override
  Future<void> buy(ProPlan plan) async {
    if (buyThrows) throw StateError('x');
    bought.add(plan.basePlanId);
  }

  @override
  Future<List<BillingPurchase>?> ownedPurchases() async => owned;

  @override
  Future<void> complete(BillingPurchase p) async => completed.add(p);
}

BillingPurchase pur(BillingStatus s, {bool ack = false, String? id}) =>
    BillingPurchase(
      productId: id ?? kProProductId,
      status: s,
      needsCompletion: ack,
    );

void main() {
  late SettingsService settings;
  late FakeBilling fake;
  late ProBilling billing;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsService.create();
    fake = FakeBilling();
    billing = ProBilling(settings, fake);
  });
  tearDown(() {
    billing.dispose();
    Flavor.debugOverride = null;
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('start: loads Play prices, no owned purchase → not Pro', () async {
    await billing.start();
    expect(billing.available, isTrue);
    expect(billing.plan(kPlanMonthly)!.price, '₺150,00');
    expect(billing.plan(kPlanMonthly)!.hasTrial, isTrue);
    expect(billing.plan(kPlanYearly)!.price, '₺999,00');
    expect(billing.isPro, isFalse);
  });

  test(
    'start: owned subscription → Pro, unacknowledged gets acknowledged',
    () async {
      fake.owned = [pur(BillingStatus.purchased, ack: true)];
      await billing.start();
      expect(billing.isPro, isTrue);
      expect(settings.playProActive, isTrue);
      expect(fake.completed, hasLength(1));
    },
  );

  test('start: subscription gone → cached Pro turned off', () async {
    await settings.setPlayProActive(true);
    fake.owned = const [];
    await billing.start();
    expect(billing.isPro, isFalse);
  });

  test('offline: cache kept, prices missing, Play unavailable', () async {
    await settings.setPlayProActive(true);
    fake.owned = null; // query failed
    fake.plansThrow = true;
    await billing.start();
    expect(billing.isPro, isTrue);
    expect(billing.plans, isEmpty);

    fake.available = false;
    final b2 = ProBilling(settings, fake);
    await b2.start();
    expect(b2.available, isFalse);
    expect(settings.playProActive, isTrue);
    await b2.buy(const ProPlan(basePlanId: kPlanMonthly, price: 'x'));
    expect(b2.takeNotice(), BillingNotice.unavailable);
    expect(fake.bought, isEmpty);
    b2.dispose();
  });

  test(
    'purchase flow: pending does not grant Pro, then purchased does',
    () async {
      await billing.start();
      final done = billing.buy(billing.plan(kPlanYearly)!);
      await tick();
      expect(fake.bought, [kPlanYearly]);
      fake.ctrl.add([pur(BillingStatus.pending)]);
      await done; // buy returns once Play answered
      expect(billing.isPro, isFalse);
      expect(billing.takeNotice(), BillingNotice.pending);

      fake.ctrl.add([pur(BillingStatus.purchased, ack: true)]);
      await tick();
      await tick();
      expect(billing.isPro, isTrue);
      expect(billing.takeNotice(), BillingNotice.purchased);
      expect(fake.completed, hasLength(1));
    },
  );

  test('cancelled / error keep Pro off and report', () async {
    await billing.start();
    var done = billing.buy(billing.plan(kPlanMonthly)!);
    await tick();
    fake.ctrl.add([pur(BillingStatus.canceled)]);
    await done;
    expect(billing.isPro, isFalse);
    expect(billing.takeNotice(), BillingNotice.canceled);

    done = billing.buy(billing.plan(kPlanMonthly)!);
    await tick();
    fake.ctrl.add([pur(BillingStatus.error)]);
    await done;
    expect(billing.isPro, isFalse);
    expect(billing.takeNotice(), BillingNotice.error);

    fake.buyThrows = true;
    await billing.buy(billing.plan(kPlanMonthly)!);
    expect(billing.takeNotice(), BillingNotice.error);
  });

  test('other product ids never grant Pro', () async {
    await billing.start();
    fake.ctrl.add([pur(BillingStatus.purchased, id: 'something_else')]);
    await tick();
    expect(billing.isPro, isFalse);
  });

  test('restore: found / nothing / offline', () async {
    await billing.start();
    fake.owned = [pur(BillingStatus.restored)];
    await billing.restore();
    expect(billing.isPro, isTrue);
    expect(billing.takeNotice(), BillingNotice.restored);

    fake.owned = const [];
    await billing.restore();
    expect(billing.isPro, isFalse);
    expect(billing.takeNotice(), BillingNotice.nothingToRestore);

    await settings.setPlayProActive(true);
    fake.owned = null;
    await billing.restore();
    expect(billing.isPro, isTrue);
    expect(billing.takeNotice(), BillingNotice.offline);
  });

  test('ProEntitlement: play uses Play state, full keeps the stub', () async {
    Flavor.debugOverride = AppFlavor.play;
    expect(ProEntitlement.available, isTrue);
    expect(ProEntitlement.viaPlayBilling, isTrue);
    await settings.setProStubActive(true);
    expect(ProEntitlement.isActive(settings), isFalse); // stub ignored
    await settings.setPlayProActive(true);
    expect(ProEntitlement.isActive(settings), isTrue);

    Flavor.debugOverride = AppFlavor.full;
    expect(ProEntitlement.viaPlayBilling, isFalse);
    await settings.setProStubActive(false);
    expect(ProEntitlement.isActive(settings), isFalse); // Play state ignored
    await settings.setProStubActive(true);
    expect(ProEntitlement.isActive(settings), isTrue);
  });

  test('no hardcoded prices in the paywall', () {
    // Prices must come from Play (ProPlan.price).
    final src = StringBuffer();
    for (final f in ['lib/screens/paywall_screen.dart']) {
      src.write(File(f).readAsStringSync());
    }
    expect(src.toString(), isNot(contains('TL')));
    expect(src.toString(), isNot(contains('₺')));
  });

  test('free item limit: 50, never negative, Pro unlimited', () {
    expect(ItemLimit.freeItemLimit, 50);
    expect(ItemLimit.leftFor(pro: false, stored: 0), 50);
    expect(ItemLimit.leftFor(pro: false, stored: 49), 1);
    expect(ItemLimit.leftFor(pro: false, stored: 50), 0);
    // Already above the limit (e.g. Pro lapsed): nothing is removed.
    expect(ItemLimit.leftFor(pro: false, stored: 120), 0);
    expect(ItemLimit.leftFor(pro: true, stored: 120), isNull);
  });

  test('every add path checks the free limit', () {
    for (final f in [
      'lib/screens/gallery_screen.dart',
      'lib/screens/files_screen.dart',
      'lib/screens/notes_list_screen.dart',
      'lib/screens/browser_screen.dart',
    ]) {
      expect(File(f).readAsStringSync(), contains('ItemLimit.'), reason: f);
    }
    expect(
      File('lib/widgets/import_delete_originals.dart').readAsStringSync(),
      contains('maxCount'),
    );
  });
}
