import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBiometrics extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

void main() {
  late Directory tmp;
  late AuthService auth;
  late SettingsService settings;

  setUp(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    settings = await SettingsService.create();
    auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    tmp = await Directory.systemTemp.createTemp('gizlialan_widget');
  });

  tearDown(() async {
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(f);
  }

  Future<void> tapKey(WidgetTester tester, String k) async {
    await tester.tap(find.byKey(ValueKey('calc_$k')));
    await tester.pump();
  }

  testWidgets('onboarding → calculator works → PIN= opens vault → lock', (
    tester,
  ) async {
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
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    // Step 1: must confirm own device.
    expect(find.text('Welcome to GizliAlan'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('own_device')));
    await tester.pump();
    await tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: calculator entry disclosed, keep default (on).
    expect(find.text('Calculator entry'), findsOneWidget);
    await tapVisible(tester, find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3: PIN.
    await tester.enterText(find.byKey(const ValueKey('pin_new')), '2580');
    await tester.enterText(find.byKey(const ValueKey('pin_confirm')), '2580');
    await tapVisible(tester, find.byKey(const ValueKey('onboarding_finish')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    // Calculator is a real calculator.
    expect(find.text('Calculator'), findsOneWidget);
    for (final k in ['1', '2', '+', '3', '=']) {
      await tapKey(tester, k);
    }
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('calc_display'))).data,
      '15',
    );
    await tapKey(tester, 'C');

    // Wrong PIN + "=" just calculates.
    for (final k in ['1', '1', '1', '1', '=']) {
      await tapKey(tester, k);
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VaultHomeScreen), findsNothing);
    await tapKey(tester, 'C');

    // PIN + "=" opens the vault.
    for (final k in ['2', '5', '8', '0', '=']) {
      await tapKey(tester, k);
    }
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(VaultHomeScreen), findsOneWidget);
    expect(find.text('Gallery'), findsWidgets);
    expect(find.text('Notes'), findsWidgets);

    // Lock returns to the calculator and closes the session.
    await tester.tap(find.byKey(const ValueKey('lock_button')));
    await tester.pumpAndSettle();
    expect(find.byType(VaultHomeScreen), findsNothing);
    expect(find.text('Calculator'), findsOneWidget);
    final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    expect(state.isUnlocked, isFalse);
  });
}
