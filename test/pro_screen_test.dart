import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/pro_screen.dart';
import 'package:gizlialan/screens/settings_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
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

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_pro');
    // The Pro stub only exists in the `full` flavor (#28).
    Flavor.debugOverride = AppFlavor.full;
  });

  tearDown(() async {
    L10n.setLang('tr');
    Flavor.debugOverride = null;
    Flavor.debugProStubOverride = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GizliAlanAppState> openVault(
    WidgetTester tester,
    VaultSpace space,
  ) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    final settings = await SettingsService.create();
    final auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    await tester.runAsync(() async {
      await auth.setPin('2580');
      await auth.setDecoyPin('1111');
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
      await state.enterVault(space);
      await state.session!.notes.create(title: 'a');
    });
    await settle(tester);
    return state;
  }

  for (final space in VaultSpace.values) {
    testWidgets(
      'Pro screen from settings (${space.name}): plans, no purchase',
      (tester) async {
        final state = await openVault(tester, space);
        state.navKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('settings_pro')),
          200,
          scrollable: find
              .descendant(
                of: find.byType(SettingsScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('settings_pro')));
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('settings_pro')));
        await settle(tester);

        expect(find.byType(ProScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('pro_test_build_note')),
          findsOneWidget,
        );
        expect(find.text('7 days · 50 items'), findsOneWidget);
        expect(
          find.text('Usage: 1 / 50 items (limit not enforced in this build)'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('399 TL'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('149 TL / year'), findsOneWidget);
        expect(find.text('Best value'), findsOneWidget);
        // Yearly is listed before lifetime.
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('plan_yearly'))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('plan_lifetime'))).dy,
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Buy'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(find.text('Buy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buy'));
        await tester.pumpAndSettle();
        expect(find.text('Not available yet'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('pro_dialog_ok')));
        await tester.pumpAndSettle();
        expect(find.text('Not available yet'), findsNothing);
      },
    );
  }

  group('Pro stub gating (#28)', () {
    test('hasProStub: play off, full on, override wins', () {
      Flavor.debugOverride = AppFlavor.play;
      expect(Flavor.hasProStub, isFalse);
      Flavor.debugOverride = AppFlavor.full;
      expect(Flavor.hasProStub, isTrue);
      Flavor.debugOverride = AppFlavor.play;
      Flavor.debugProStubOverride = true;
      expect(Flavor.hasProStub, isTrue);
    });

    for (final space in VaultSpace.values) {
      testWidgets('play flavor (${space.name}): no Pro entry in settings', (
        tester,
      ) async {
        Flavor.debugOverride = AppFlavor.play;
        final state = await openVault(tester, space);
        state.navKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.text('Privacy & permissions'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.byKey(const ValueKey('settings_pro')), findsNothing);
        expect(find.text('GizliAlan Pro'), findsNothing);
        expect(find.byType(ProScreen), findsNothing);
        // Privacy entry is still there.
        expect(find.text('Privacy & permissions'), findsOneWidget);
      });
    }

    testWidgets('play flavor + PRO_STUB flag: Pro entry shown', (tester) async {
      Flavor.debugOverride = AppFlavor.play;
      Flavor.debugProStubOverride = true;
      final state = await openVault(tester, VaultSpace.real);
      state.navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      await settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_pro')),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const ValueKey('settings_pro')), findsOneWidget);
    });
  });

  test('no billing dependency in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('in_app_purchase'), isFalse);
    expect(pubspec.contains('billing'), isFalse);
  });
}
