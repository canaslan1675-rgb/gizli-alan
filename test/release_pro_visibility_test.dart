import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/help_screen.dart';
import 'package:gizlialan/screens/paywall_screen.dart';
import 'package:gizlialan/screens/settings_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/pro_entitlement.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoBiometrics extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

/// 0.6.0+43: release builds (no Pro stub) must show the Pro UI in BOTH
/// flavors — `full` is the Play upload.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_rel');
  });

  tearDown(() async {
    L10n.setLang('tr');
    Flavor.debugOverride = null;
    Flavor.debugProStubOverride = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  void release(AppFlavor f) {
    Flavor.debugOverride = f;
    Flavor.debugProStubOverride = false;
  }

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GizliAlanAppState> openVault(WidgetTester tester) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    final settings = await SettingsService.create();
    final auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    await tester.runAsync(() async {
      await auth.setPin('2580');
    });
    await settings.setCalculatorEntryEnabled(false);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GizliAlanApp(
        settings: settings,
        auth: auth,
        biometrics: _NoBiometrics(),
        baseDirProvider: () async => tmp,
      ),
    );
    await settle(tester, 2);
    final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    await tester.runAsync(() async {
      await state.enterVault(VaultSpace.real);
      await state.session!.notes.create(title: 'a');
    });
    await settle(tester);
    return state;
  }

  Future<void> push(WidgetTester tester, GizliAlanAppState s, Widget w) async {
    s.navKey.currentState!.push(MaterialPageRoute(builder: (_) => w));
    await settle(tester);
  }

  for (final f in AppFlavor.values) {
    test('${f.name} release: Pro available via Play Billing', () {
      release(f);
      expect(Flavor.hasProStub, isFalse);
      expect(ProEntitlement.viaPlayBilling, isTrue);
      expect(ProEntitlement.available, isTrue);
    });

    testWidgets('${f.name} release: counter, free banner, settings rows', (
      tester,
    ) async {
      release(f);
      final s = await openVault(tester);
      expect(find.byKey(const ValueKey('free_banner')), findsOneWidget);
      expect(find.text('1/50 items'), findsOneWidget);

      await push(tester, s, const SettingsScreen());
      final scroll = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_hide_calc_info')),
        150,
        scrollable: scroll,
      );
      expect(
        find.byKey(const ValueKey('settings_hide_calc_info')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_pro')),
        150,
        scrollable: scroll,
      );
      final row = find.byKey(const ValueKey('settings_pro'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('Buy or restore Pro')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('test')),
        findsNothing,
      );
    });

    testWidgets('${f.name} release: paywall payF1 only with Second phone', (
      tester,
    ) async {
      release(f);
      final s = await openVault(tester);
      await push(tester, s, const PaywallScreen());
      expect(
        find.text(L10n.current('payF1')),
        f == AppFlavor.full ? findsOneWidget : findsNothing,
      );
      // No legacy subscription → no "manage subscription" link.
      expect(find.byKey(const ValueKey('pay_manage')), findsNothing);
    });
  }

  testWidgets('full release: help shows the Second phone Pro note', (
    tester,
  ) async {
    release(AppFlavor.full);
    final s = await openVault(tester);
    await push(tester, s, const HelpScreen());
    final title = find.text(L10n.current('helpSecondPhoneTitle'));
    await tester.scrollUntilVisible(
      title,
      150,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('help_list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(title);
    await settle(tester);
    expect(
      find.textContaining(
        L10n.current('helpSecondPhonePro'),
        findRichText: true,
      ),
      findsWidgets,
    );
  });

  testWidgets('full test stub: settings row keeps the test-build hint', (
    tester,
  ) async {
    Flavor.debugOverride = AppFlavor.full;
    Flavor.debugProStubOverride = true;
    final s = await openVault(tester);
    await push(tester, s, const SettingsScreen());
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings_pro')),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(L10n.current('proSettingsHintStub')), findsOneWidget);
  });
}
