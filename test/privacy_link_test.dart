import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/settings_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/privacy_link.dart';
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
    tmp = await Directory.systemTemp.createTemp('gizlialan_privacy');
    Flavor.debugOverride = AppFlavor.play;
  });

  tearDown(() async {
    L10n.setLang('tr');
    Flavor.debugOverride = null;
    PrivacyLink.debugUrlOverride = null;
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

  Future<void> openPrivacy(WidgetTester tester) async {
    final state = await openVault(tester, VaultSpace.real);
    state.navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await settle(tester);
    final list = find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Privacy & permissions'),
      200,
      scrollable: list,
    );
    await tester.tap(find.text('Privacy & permissions'));
    await tester.pumpAndSettle();
  }

  group('PrivacyLink.isValid', () {
    test('accepts https with host only', () {
      expect(PrivacyLink.isValid('https://example.org/privacy'), isTrue);
      expect(PrivacyLink.isValid('http://example.org/privacy'), isFalse);
      expect(PrivacyLink.isValid(''), isFalse);
      expect(PrivacyLink.isValid('https://'), isFalse);
      expect(PrivacyLink.isValid('javascript:alert(1)'), isFalse);
      expect(PrivacyLink.isValid('https://exa mple.org'), isFalse);
    });

    test('no PRIVACY_URL define in tests -> url is null', () {
      expect(PrivacyLink.configured, isEmpty);
      expect(PrivacyLink.url, isNull);
      PrivacyLink.debugUrlOverride = 'http://insecure.example';
      expect(PrivacyLink.url, isNull);
    });
  });

  testWidgets('no PRIVACY_URL: in-app policy text only, no link buttons', (
    tester,
  ) async {
    await openPrivacy(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('AES-256-GCM'), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy_url')), findsNothing);
    expect(find.byKey(const ValueKey('privacy_open')), findsNothing);
    expect(find.byKey(const ValueKey('privacy_copy')), findsNothing);
  });

  testWidgets('PRIVACY_URL set: shows link, opens via system channel', (
    tester,
  ) async {
    const url = 'https://example.org/gizlialan/privacy';
    PrivacyLink.debugUrlOverride = url;
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PrivacyLink.channel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PrivacyLink.channel,
        null,
      ),
    );
    await openPrivacy(tester);
    expect(find.textContaining('AES-256-GCM'), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy_url')), findsOneWidget);
    expect(find.text(url), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('privacy_open')));
    await tester.pumpAndSettle();
    // The same channel also carries the browser wipe (#32) — ignore it.
    final opens = calls.where((c) => c.method == 'openUrl').toList();
    expect(opens, hasLength(1));
    expect(opens.single.method, 'openUrl');
    expect(opens.single.arguments, {'url': url});
  });

  testWidgets('no browser: falls back to copying the link', (tester) async {
    const url = 'https://example.org/p';
    PrivacyLink.debugUrlOverride = url;
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PrivacyLink.channel,
      (call) async => false,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clip = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PrivacyLink.channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await openPrivacy(tester);
    await tester.tap(find.byKey(const ValueKey('privacy_open')));
    await tester.pumpAndSettle();
    expect(clip, url);
    expect(
      find.text('No browser found. The link was copied instead.'),
      findsOneWidget,
    );
  });

  test('manifests: INTERNET only in main (browser, #32), no url_launcher', () {
    // v0.4.0: INTERNET is declared once, in the shared main manifest, for
    // the in-vault private browser only. The full flavor adds nothing.
    final main = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      '<uses-permission android:name="android.permission.INTERNET" />'
          .allMatches(main)
          .length,
      1,
    );
    expect(
      File(
        'android/app/src/full/AndroidManifest.xml',
      ).readAsStringSync().contains('android.permission.INTERNET'),
      isFalse,
    );
    expect(
      File('pubspec.yaml').readAsStringSync().contains('url_launcher'),
      isFalse,
    );
  });
}
