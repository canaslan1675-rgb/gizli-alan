import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoBiometrics extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

Future<void> settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Shared 0.6.0 widget-test harness: app with PIN 2580 / decoy 1111.
class Harness {
  Harness(this.tmp, this.auth, this.settings);
  final Directory tmp;
  final AuthService auth;
  final SettingsService settings;
  late GizliAlanAppState state;

  static Future<Harness> start(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en', ...prefs});
    final settings = await SettingsService.create();
    final auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    final tmp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('gizlialan_h'),
    ))!;
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
        biometrics: NoBiometrics(),
        baseDirProvider: () async => tmp,
      ),
    );
    await settle(tester, 2);
    final h = Harness(tmp, auth, settings);
    h.state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    return h;
  }

  Future<void> enter(
    WidgetTester tester, [
    VaultSpace s = VaultSpace.real,
  ]) async {
    await tester.runAsync(() => state.enterVault(s));
    await settle(tester);
  }
}
