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

  /// What close() reports (null = the profile refused / failed).
  SecondPhoneCloseMode? closeResult = SecondPhoneCloseMode.freeze;

  @override
  Future<SecondPhoneStatus> status() async => st;

  @override
  Future<List<ProfileApp>> listApps() async => const [
    ProfileApp(label: 'Chat', packageName: 'com.example.chat', activity: 'A'),
  ];

  @override
  Future<SecondPhoneCloseMode?> close(SecondPhoneCloseMode mode) async {
    closes.add(mode);
    return closeResult;
  }

  @override
  Future<bool> open(
    SecondPhoneCloseMode applied, {
    int quietPolls = 10,
    Duration pollDelay = const Duration(milliseconds: 500),
  }) async {
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
    // App start while locked hides the work apps (#30).
    expect(sp.closes, [SecondPhoneCloseMode.freeze]);
    expect(settings.secondPhoneClosedBy, SecondPhoneCloseMode.freeze);
    sp.closes.clear();

    // Real vault: tile + profile app grid; unlock unhides.
    await typePin(tester, '2580');
    expect(sp.opens, [SecondPhoneCloseMode.freeze]);
    expect(settings.secondPhoneClosedBy, isNull);
    sp.opens.clear();
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
      expect(
        find.byKey(const ValueKey('settings_hide_when_locked')),
        findsNothing,
      );
      expect(find.textContaining('Second phone'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_version')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('GizliAlan 0.4.1 · Play'), findsOneWidget);
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
        find.byKey(const ValueKey('settings_hide_when_locked')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byKey(const ValueKey('settings_hide_when_locked')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings_version')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('GizliAlan 0.4.1 · Full'), findsOneWidget);
    });
  });

  group('hide work apps while locked (#30)', () {
    Future<GizliAlanAppState> start(WidgetTester tester) async {
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
      return tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    }

    testWidgets('toggle off: nothing hidden on start or Lock; unlock still '
        'unhides what was hidden before', (tester) async {
      await settings.setHideWorkAppsWhenLocked(false);
      await settings.setSecondPhoneClosedBy(SecondPhoneCloseMode.freeze);
      await start(tester);
      expect(sp.closes, isEmpty);
      await typePin(tester, '2580');
      expect(sp.opens, [SecondPhoneCloseMode.freeze]);
      expect(settings.secondPhoneClosedBy, isNull);
      await tester.tap(find.byKey(const ValueKey('lock_button')));
      await settle(tester);
      expect(sp.closes, isEmpty);
    });

    testWidgets('resume while locked hides; failures are not retried in a '
        'loop', (tester) async {
      sp.closeResult = null; // profile refuses
      final state = await start(tester);
      expect(sp.closes.length, 1); // app start
      // The translucent profile activity pauses/resumes us: no new attempt.
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(sp.closes.length, 1);
      // Leaving and coming back within the cooldown: still no attempt.
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(sp.closes.length, 1);
      expect(settings.secondPhoneClosedBy, isNull);
    });

    testWidgets('already hidden: start/resume do not hide again', (
      tester,
    ) async {
      await settings.setSecondPhoneClosedBy(SecondPhoneCloseMode.freeze);
      final state = await start(tester);
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(sp.closes, isEmpty);
    });

    testWidgets('pause option: Lock asks for quiet mode (hide + pause)', (
      tester,
    ) async {
      await settings.setPauseWorkProfileWhenLocked(true);
      sp.closeResult = SecondPhoneCloseMode.quiet;
      await start(tester);
      expect(sp.closes, [SecondPhoneCloseMode.quiet]);
      await typePin(tester, '2580');
      expect(sp.opens, [SecondPhoneCloseMode.quiet]);
    });

    testWidgets('Second phone screen has the toggle, default on, TR label', (
      tester,
    ) async {
      L10n.setLang('tr');
      await settings.setLanguage('tr');
      await start(tester);
      await typePin(tester, '2580');
      await tester.tap(find.text('İkinci telefon').first);
      await settle(tester);
      final toggle = find.byKey(const ValueKey('sp_hide_when_locked'));
      await tester.scrollUntilVisible(
        toggle,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Kilitliyken iş uygulamalarını gizle'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.ensureVisible(toggle);
      await settle(tester);
      await tester.tap(toggle);
      await settle(tester);
      expect(settings.hideWorkAppsWhenLocked, isFalse);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      final pause = find.byKey(const ValueKey('sp_pause_too'));
      expect(tester.widget<SwitchListTile>(pause).onChanged, isNull);
    });

    testWidgets('play flavor: never hides or unhides anything', (tester) async {
      Flavor.debugOverride = AppFlavor.play;
      final state = await start(tester);
      await state.ensureWorkAppsHiddenWhileLocked();
      await typePin(tester, '2580');
      await tester.tap(find.byKey(const ValueKey('lock_button')));
      await settle(tester);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(sp.closes, isEmpty);
      expect(sp.opens, isEmpty);
    });
  });
}
