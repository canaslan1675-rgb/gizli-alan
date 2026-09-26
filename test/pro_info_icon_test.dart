import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/decoy_calculator_screen.dart';
import 'package:gizlialan/screens/pro_screen.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/pro_entitlement.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart' show FakeBiometrics;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_pro_info');
  });

  tearDown(() async {
    Flavor.debugOverride = null;
    Flavor.debugProStubOverride = null;
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('ProEntitlement', () {
    test('play (no Pro stub): never active, icon never hidden', () async {
      SharedPreferences.setMockInitialValues({
        'pro_stub_active': true,
        'hide_calc_info_icon': true,
      });
      final s = await SettingsService.create();
      Flavor.debugOverride = AppFlavor.play;
      expect(ProEntitlement.available, isFalse);
      expect(ProEntitlement.isActive(s), isFalse);
      expect(ProEntitlement.hideCalculatorInfo(s), isFalse);
    });

    test(
      'full: hidden only with opt-in AND active Pro; lapse restores',
      () async {
        SharedPreferences.setMockInitialValues({});
        final s = await SettingsService.create();
        Flavor.debugOverride = AppFlavor.full;
        expect(s.hideCalcInfoIcon, isFalse); // default off
        expect(ProEntitlement.hideCalculatorInfo(s), isFalse);
        await s.setHideCalcInfoIcon(true);
        expect(ProEntitlement.hideCalculatorInfo(s), isFalse); // not Pro
        await s.setProStubActive(true);
        expect(ProEntitlement.hideCalculatorInfo(s), isTrue);
        await s.setProStubActive(false); // Pro lapses
        expect(ProEntitlement.hideCalculatorInfo(s), isFalse);
        expect(s.hideCalcInfoIcon, isTrue); // opt-in kept for renewal
      },
    );
  });

  Future<(SettingsService, AuthService)> boot(
    WidgetTester tester,
    Map<String, Object> prefs,
    AppFlavor flavor,
  ) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'tr', ...prefs});
    late SettingsService settings;
    late AuthService auth;
    await tester.runAsync(() async {
      settings = await SettingsService.create();
      auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
      await auth.setPin('2580');
    });
    Flavor.debugOverride = flavor;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GizliAlanApp(
        settings: settings,
        auth: auth,
        biometrics: FakeBiometrics(),
        baseDirProvider: () async => tmp,
      ),
    );
    return (settings, auth);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> unlock(WidgetTester tester) async {
    for (final k in [...'2580'.split(''), '=']) {
      await tester.tap(find.byKey(ValueKey('calc_$k')));
      await tester.pump();
    }
    await settle(tester);
    expect(find.byType(VaultHomeScreen), findsOneWidget);
  }

  Future<Finder> openHideTile(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    final tile = find.byKey(const ValueKey('settings_hide_calc_info'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(tile);
    await settle(tester);
    return tile;
  }

  testWidgets('full: calculator hides ⓘ only while Pro is active', (
    tester,
  ) async {
    await boot(tester, {
      'hide_calc_info_icon': true,
      'pro_stub_active': true,
    }, AppFlavor.full);
    await settle(tester);
    expect(find.byType(DecoyCalculatorScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('calc_info')), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    // Calculator still fully works and the vault still opens.
    await unlock(tester);
  });

  testWidgets('full: lapsed Pro → ⓘ is back, dialog mentions Pro hint', (
    tester,
  ) async {
    await boot(tester, {
      'hide_calc_info_icon': true,
      'pro_stub_active': false,
    }, AppFlavor.full);
    await settle(tester);
    expect(find.byKey(const ValueKey('calc_info')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calc_info')));
    await settle(tester);
    expect(
      find.textContaining("Pro üyeler bu simgeyi Ayarlar'dan gizleyebilir."),
      findsOneWidget,
    );
  });

  testWidgets('full: Settings toggle is locked without Pro, opens Pro screen, '
      'works after Pro, hides ⓘ after lock', (tester) async {
    final (settings, _) = await boot(tester, {}, AppFlavor.full);
    await settle(tester);
    expect(find.byKey(const ValueKey('calc_info')), findsOneWidget);
    await unlock(tester);

    var tile = await openHideTile(tester);
    expect(
      find
          .byType(SwitchListTile)
          .evaluate()
          .where(
            (e) => e.widget.key == const ValueKey('settings_hide_calc_info'),
          ),
      isEmpty,
    );
    expect(
      find.byKey(const ValueKey('settings_hide_calc_info_pro_badge')),
      findsOneWidget,
    );
    await tester.tap(tile);
    await settle(tester);
    expect(find.byType(ProScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pro_stub_toggle')));
    await settle(tester);
    expect(settings.proStubActive, isTrue);
    await tester.pageBack();
    await settle(tester);

    tile = find.byKey(const ValueKey('settings_hide_calc_info'));
    await tester.ensureVisible(tile);
    final sw = tester.widget<SwitchListTile>(tile);
    expect(sw.value, isFalse); // default off
    await tester.tap(tile);
    await settle(tester);
    expect(settings.hideCalcInfoIcon, isTrue);

    // Help remains reachable in vault Settings.
    final help = find.byKey(const ValueKey('settings_calc_help'));
    await tester.scrollUntilVisible(
      help,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(help);
    await settle(tester);
    await tester.tap(help, warnIfMissed: false);
    await settle(tester);
    expect(find.text('Bu hesap makinesi hakkında'), findsOneWidget);
    await tester.tap(find.text('Tamam').last);
    await settle(tester);

    final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    state.lockVaultExplicit();
    await settle(tester);
    expect(find.byType(DecoyCalculatorScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('calc_info')), findsNothing);
  });

  testWidgets('play: ⓘ always shown, no Pro hint, toggle says "Pro yakında"', (
    tester,
  ) async {
    await boot(tester, {
      'hide_calc_info_icon': true,
      'pro_stub_active': true,
    }, AppFlavor.play);
    Flavor.debugProStubOverride = false;
    await settle(tester);
    expect(find.byKey(const ValueKey('calc_info')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calc_info')));
    await settle(tester);
    expect(find.textContaining('Pro üyeler'), findsNothing);
    await tester.tap(find.text('Tamam').last);
    await settle(tester);

    await unlock(tester);
    final tile = await openHideTile(tester);
    expect(find.text('Pro yakında'), findsOneWidget);
    expect(tester.widget<ListTile>(tile).onTap, isNull);
    expect(tester.widget<ListTile>(tile).enabled, isFalse);
  });
}
