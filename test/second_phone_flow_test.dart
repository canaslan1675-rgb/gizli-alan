import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/second_phone_service.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart' show FakeBiometrics;

class FakeSecondPhone extends SecondPhoneService {
  FakeSecondPhone([this.st = _ready]);

  static const _ready = SecondPhoneStatus(
    featureSupported: true,
    provisioningAllowed: false,
    exists: true,
    linked: true,
    sdkInt: 34,
  );

  final SecondPhoneStatus st;
  final closes = <SecondPhoneCloseMode>[];
  final opens = <SecondPhoneCloseMode>[];

  @override
  Future<SecondPhoneStatus> status() async => st;

  @override
  Future<List<ProfileApp>> listApps() async => const [
    ProfileApp(label: 'Chat', packageName: 'com.example.chat', activity: 'A'),
  ];

  @override
  Future<SecondPhoneCloseMode?> close(SecondPhoneCloseMode mode) async {
    closes.add(mode);
    return SecondPhoneCloseMode.freeze;
  }

  @override
  Future<bool> open(SecondPhoneCloseMode applied) async {
    opens.add(applied);
    return true;
  }
}

void main() {
  late Directory tmp;
  late AuthService auth;
  late SettingsService settings;
  late FakeSecondPhone sp;

  setUp(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    settings = await SettingsService.create();
    auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    sp = FakeSecondPhone();
    tmp = await Directory.systemTemp.createTemp('gizlialan_sp');
    Flavor.debugOverride = AppFlavor.full;
  });

  tearDown(() async {
    Flavor.debugOverride = null;
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final k in [...pin.split(''), '=']) {
      await tester.tap(find.byKey(ValueKey('calc_$k')));
      await tester.pump();
    }
    await settle(tester);
  }

  testWidgets('second phone: grid in real vault only, Lock closes, unlock '
      're-opens', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await auth.setPin('2580');
      await auth.setDecoyPin('1111');
    });

    await tester.pumpWidget(
      GizliAlanApp(
        settings: settings,
        auth: auth,
        biometrics: FakeBiometrics(),
        baseDirProvider: () async => tmp,
        secondPhone: sp,
      ),
    );
    await settle(tester);
    final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    expect(state.secondPhoneIfUnlocked, isNull); // gated behind unlock

    // Real vault: tile + profile app grid.
    await typePin(tester, '2580');
    expect(find.byType(VaultHomeScreen), findsOneWidget);
    expect(find.text('Second phone'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(state.secondPhoneIfUnlocked, same(sp));

    // Lock button closes the second phone (default: hide apps).
    await tester.tap(find.byKey(const ValueKey('lock_button')));
    await settle(tester);
    expect(sp.closes, [SecondPhoneCloseMode.freeze]);
    expect(settings.secondPhoneClosedBy, SecondPhoneCloseMode.freeze);
    expect(state.secondPhoneIfUnlocked, isNull);

    // Unlock re-opens it.
    await typePin(tester, '2580');
    expect(sp.opens, [SecondPhoneCloseMode.freeze]);
    expect(settings.secondPhoneClosedBy, isNull);
    await tester.tap(find.byKey(const ValueKey('lock_button')));
    await settle(tester);

    // Decoy vault: no second phone at all, and locking it closes nothing.
    final closesBefore = sp.closes.length;
    await typePin(tester, '1111');
    expect(find.byType(VaultHomeScreen), findsOneWidget);
    expect(find.text('Second phone'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(state.secondPhoneIfUnlocked, isNull);
    await tester.tap(find.byKey(const ValueKey('lock_button')));
    await settle(tester);
    expect(sp.closes.length, closesBefore);
  });

  testWidgets('Xiaomi device with blocked provisioning shows the fallback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    sp = FakeSecondPhone(
      const SecondPhoneStatus(
        featureSupported: true,
        provisioningAllowed: false,
        isXiaomi: true,
        sdkInt: 35,
      ),
    );
    await tester.runAsync(() => auth.setPin('2580'));
    await tester.pumpWidget(
      GizliAlanApp(
        settings: settings,
        auth: auth,
        biometrics: FakeBiometrics(),
        baseDirProvider: () async => tmp,
        secondPhone: sp,
      ),
    );
    await settle(tester);
    await typePin(tester, '2580');
    expect(find.text('Chat'), findsNothing); // no profile yet
    await tester.tap(find.text('Second phone'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.textContaining('Second space'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Second space'), findsOneWidget);
    expect(find.textContaining('Private space'), findsWidgets);
    expect(find.byKey(const ValueKey('sp_setup')), findsNothing);
  });

  group('flavor gating (#11)', () {
    Future<GizliAlanAppState> openRealVault(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => auth.setPin('2580'));
      await tester.pumpWidget(
        GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: FakeBiometrics(),
          baseDirProvider: () async => tmp,
          secondPhone: sp,
        ),
      );
      await settle(tester);
      await typePin(tester, '2580');
      expect(find.byType(VaultHomeScreen), findsOneWidget);
      return tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    }

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
    }

    test('parse: unknown/missing flavor defaults to play', () {
      expect(Flavor.parse('full'), AppFlavor.full);
      expect(Flavor.parse('play'), AppFlavor.play);
      expect(Flavor.parse(''), AppFlavor.play);
      expect(Flavor.parse(null), AppFlavor.play);
      expect(Flavor.parse('Full'), AppFlavor.play);
    });

    testWidgets('play: no Second phone anywhere', (tester) async {
      Flavor.debugOverride = AppFlavor.play;
      expect(Flavor.hasSecondPhone, isFalse);
      final state = await openRealVault(tester);
      expect(find.textContaining('Second phone'), findsNothing);
      expect(find.text('Chat'), findsNothing); // no profile apps grid
      expect(state.secondPhoneIfUnlocked, isNull);

      await openSettings(tester);
      expect(find.byKey(const ValueKey('sp_close_mode')), findsNothing);
      expect(find.textContaining('Second phone'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_version')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('GizliAlan 0.3.1 · Play'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      // Locking in play never touches the (absent) second phone.
      await tester.tap(find.byKey(const ValueKey('lock_button')));
      await settle(tester);
      expect(sp.closes, isEmpty);
      await typePin(tester, '2580');
      expect(sp.opens, isEmpty);

      // Texts that mention the Second phone use their play variants.
      final l = L10n.current;
      for (final k in ['onboardingPrivacy', 'privacyBody', 'notifEmpty']) {
        expect(l.t(k), isNot(contains('Second phone')), reason: k);
        expect(l.t(k), isNot(contains('work profile')), reason: k);
      }
      L10n.setLang('tr');
      for (final k in ['onboardingPrivacy', 'privacyBody', 'notifEmpty']) {
        expect(L10n.current.t(k), isNot(contains('İkinci telefon')));
        expect(L10n.current.t(k), isNot(contains('iş profili')));
      }
    });

    testWidgets('full: Second phone tile, grid and settings', (tester) async {
      Flavor.debugOverride = AppFlavor.full;
      final state = await openRealVault(tester);
      expect(find.text('Second phone'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(state.secondPhoneIfUnlocked, same(sp));
      expect(L10n.current.t('notifEmpty'), contains('Second phone'));

      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sp_close_mode')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const ValueKey('sp_close_mode')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_version')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('GizliAlan 0.3.1 · Full'), findsOneWidget);
    });
  });
}
