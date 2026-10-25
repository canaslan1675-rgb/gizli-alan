import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/l10n/tr.dart';
import 'package:gizlialan/screens/decoy_calculator_screen.dart';
import 'package:gizlialan/screens/files_screen.dart';
import 'package:gizlialan/screens/gallery_screen.dart';
import 'package:gizlialan/screens/note_edit_screen.dart';
import 'package:gizlialan/screens/settings_screen.dart';
import 'package:gizlialan/screens/notes_list_screen.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/auto_lock.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart' show FakeBiometrics;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoLockGuard', () {
    test('immediate lock on leave; shade and return-within-delay do not', () {
      var t = DateTime(2026, 10, 25, 12);
      final g = AutoLockGuard(now: () => t);

      expect(g.onLifecycle(AppLifecycleState.inactive, timeoutSec: 0), isFalse);
      expect(g.onLifecycle(AppLifecycleState.paused, timeoutSec: 0), isTrue);

      t = DateTime(2026, 10, 25, 12);
      final delay = AutoLockGuard(now: () => t);
      expect(
        delay.onLifecycle(AppLifecycleState.hidden, timeoutSec: 30),
        isFalse,
      );
      t = t.add(const Duration(seconds: 29));
      expect(
        delay.onLifecycle(AppLifecycleState.resumed, timeoutSec: 30),
        isFalse,
      );
      expect(
        delay.onLifecycle(AppLifecycleState.paused, timeoutSec: 30),
        isFalse,
      );
      t = t.add(const Duration(seconds: 30));
      expect(
        delay.onLifecycle(AppLifecycleState.resumed, timeoutSec: 30),
        isTrue,
      );
    });

    test('picker future covers the whole leave; share waits until resume', () {
      final g = AutoLockGuard();
      g.begin();
      expect(g.onLifecycle(AppLifecycleState.paused, timeoutSec: 0), isFalse);
      expect(g.onLifecycle(AppLifecycleState.resumed, timeoutSec: 0), isFalse);
      g.end(staysOut: false);
      expect(g.holding, isFalse);
      expect(g.onLifecycle(AppLifecycleState.paused, timeoutSec: 0), isTrue);

      final share = AutoLockGuard();
      share.begin(untilResume: true);
      share.end(staysOut: true); // startActivity returned, pause not yet seen
      expect(share.holding, isTrue);
      expect(
        share.onLifecycle(AppLifecycleState.paused, timeoutSec: 0),
        isFalse,
      );
      expect(
        share.onLifecycle(AppLifecycleState.resumed, timeoutSec: 0),
        isFalse,
      );
      expect(share.holding, isFalse);
      expect(
        share.onLifecycle(AppLifecycleState.paused, timeoutSec: 0),
        isTrue,
      );
    });

    test('a failed launch does not swallow the next real leave', () {
      final g = AutoLockGuard();
      g.begin(untilResume: true);
      g.end(staysOut: false);
      expect(g.holding, isFalse);
      expect(g.onLifecycle(AppLifecycleState.paused, timeoutSec: 0), isTrue);
    });

    test('pause queued before the platform call returns is still held', () {
      final g = AutoLockGuard();
      g.begin(untilResume: true);
      expect(g.onLifecycle(AppLifecycleState.paused, timeoutSec: 0), isFalse);
      g.end(staysOut: true);
      expect(g.holding, isTrue);
      expect(g.onLifecycle(AppLifecycleState.resumed, timeoutSec: 0), isFalse);
      expect(g.holding, isFalse);
    });

    test('externalCallStaysOut', () {
      expect(externalCallStaysOut(true), isTrue);
      expect(externalCallStaysOut(false), isFalse);
      expect(externalCallStaysOut(null), isFalse);
      expect(externalCallStaysOut('store_opened'), isTrue);
      expect(externalCallStaysOut('none'), isFalse);
      expect(externalCallStaysOut('canceled'), isFalse);
    });
  });

  group('lock delay preference', () {
    test('persists and snaps legacy 15 s / 5 min', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsService.create();
      expect(s.lockTimeoutSec, 0);
      expect(SettingsService.lockTimeoutChoices, [0, 30, 60]);
      await s.setLockTimeoutSec(30);
      expect(s.lockTimeoutSec, 30);

      SharedPreferences.setMockInitialValues({'lock_timeout_sec': 15});
      expect((await SettingsService.create()).lockTimeoutSec, 30);
      SharedPreferences.setMockInitialValues({'lock_timeout_sec': 300});
      expect((await SettingsService.create()).lockTimeoutSec, 60);
      SharedPreferences.setMockInitialValues({'lock_timeout_sec': 60});
      expect((await SettingsService.create()).lockTimeoutSec, 60);

      expect(tr['lockTimeout'], 'Kilit süresi');
      expect(tr['lockImmediately'], 'Hemen');
      expect(tr['lockAfter30'], '30 saniye');
      expect(tr['lockAfter60'], '1 dakika');
      expect(en['lockTimeout'], isNotNull);
      expect(en['lockAfter30'], isNotNull);
      expect(en['lockAfter60'], isNotNull);
      expect(en['lockTimeoutHint'], isNot(contains('spy')));
      expect(tr['lockTimeoutHint'], isNot(contains('casus')));
    });
  });

  group('vault back and relock', () {
    late Directory tmp;

    setUp(() async {
      await initializeDateFormatting();
      tmp = await Directory.systemTemp.createTemp('gizlialan_autolock');
    });

    tearDown(() async {
      L10n.setLang('tr');
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<GizliAlanAppState> unlock(
      WidgetTester tester, {
      DateTime Function()? now,
      String lang = 'en',
    }) async {
      SharedPreferences.setMockInitialValues({'lang': lang});
      final settings = await SettingsService.create();
      final auth = AuthService(
        storage: MemorySecureKv(),
        pbkdf2Iterations: 1000,
      );
      await tester.runAsync(() => auth.setPin('2580'));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: FakeBiometrics(),
          baseDirProvider: () async => tmp,
          now: now,
        ),
      );
      await settle(tester);
      final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
      await tester.runAsync(() => state.enterVault(VaultSpace.real));
      await settle(tester);
      expect(state.isUnlocked, isTrue);
      expect(find.byType(VaultHomeScreen), findsOneWidget);
      return state;
    }

    testWidgets('system back pops inner screens; only home locks', (
      tester,
    ) async {
      final state = await unlock(tester);

      await tester.tap(find.text('Files'));
      await settle(tester);
      expect(find.byType(FilesScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(FilesScreen), findsNothing);
      expect(find.byType(VaultHomeScreen), findsOneWidget);
      expect(state.isUnlocked, isTrue);

      await tester.tap(find.text('Gallery'));
      await settle(tester);
      expect(find.byType(GalleryScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(GalleryScreen), findsNothing);
      expect(state.isUnlocked, isTrue);

      await tester.tap(find.text('Notes'));
      await settle(tester);
      expect(find.byType(NotesListScreen), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      expect(find.byType(NoteEditScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(NoteEditScreen), findsNothing);
      expect(find.byType(NotesListScreen), findsOneWidget);
      expect(state.isUnlocked, isTrue);
      // App bar back, not only the system back.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(NotesListScreen), findsNothing);
      expect(find.byType(VaultHomeScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(state.isUnlocked, isFalse);
      expect(find.byType(VaultHomeScreen), findsNothing);
      expect(find.byType(DecoyCalculatorScreen), findsOneWidget);
    });

    testWidgets('leave locks after the saved delay; external return does not', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 25, 12);
      final state = await unlock(tester, now: () => now);
      expect(state.settings.lockTimeoutSec, 0);

      state.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(state.isUnlocked, isTrue);
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle(tester);
      expect(state.isUnlocked, isFalse);

      await tester.runAsync(() => state.enterVault(VaultSpace.real));
      await settle(tester);
      await state.settings.setLockTimeoutSec(30);
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle(tester);
      expect(state.isUnlocked, isTrue, reason: 'still inside 30 s');
      now = now.add(const Duration(seconds: 29));
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(state.isUnlocked, isTrue);
      state.didChangeAppLifecycleState(AppLifecycleState.hidden);
      now = now.add(const Duration(seconds: 30));
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(state.isUnlocked, isFalse);

      await tester.runAsync(() => state.enterVault(VaultSpace.real));
      await settle(tester);
      await state.settings.setLockTimeoutSec(0);
      // Share-style: the call returns before the activity pauses.
      await state.withExternalUi(() async => true, untilResume: true);
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(state.isUnlocked, isTrue);
      // The next real leave still locks.
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settle(tester);
      expect(state.isUnlocked, isFalse);

      await tester.runAsync(() => state.enterVault(VaultSpace.real));
      await settle(tester);
      final gate = Completer<void>();
      final pending = state.withExternalUi(() => gate.future);
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(state.isUnlocked, isTrue);
      gate.complete();
      await pending;
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle(tester);
      expect(state.isUnlocked, isTrue);
    });

    testWidgets('Kilit süresi row offers Hemen, 30 saniye, 1 dakika', (
      tester,
    ) async {
      final state = await unlock(tester, lang: 'tr');
      await tester.tap(find.text('Ayarlar'));
      await settle(tester);
      final tile = find.byKey(const ValueKey('settings_lock_timeout'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      await settle(tester);
      expect(find.text('Kilit süresi'), findsOneWidget);
      expect(find.text('Hemen'), findsOneWidget);
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(DropdownButton<int>)),
      );
      await tester.pumpAndSettle();
      expect(find.text('30 saniye'), findsWidgets);
      expect(find.text('1 dakika'), findsWidgets);
      await tester.tap(find.text('1 dakika').last);
      await tester.pumpAndSettle();
      expect(state.settings.lockTimeoutSec, 60);
    });
  });
}
