import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
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
  });

  tearDown(() async {
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
}
