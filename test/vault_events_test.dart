import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/models/vault_event.dart';
import 'package:gizlialan/screens/notifications_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/crypto_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_events.dart';
import 'package:gizlialan/services/vault_session.dart';
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
    tmp = await Directory.systemTemp.createTemp('gizlialan_events');
  });

  tearDown(() async {
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  VaultSession open(VaultSpace space, List<int> key) =>
      VaultSession(space: space, key: key, baseDir: tmp);

  group('VaultEventLog', () {
    test('add, list newest first, unread, mark read, clear', () async {
      final s = open(VaultSpace.real, CryptoService.newKey());
      expect(await s.events.list(), isEmpty);
      await s.events.add(VaultEventType.galleryImported, {'n': '3'});
      await s.events.add(VaultEventType.itemDeleted, {'name': 'a.jpg'});
      final list = await s.events.list();
      expect(list.map((e) => e.type), [
        VaultEventType.itemDeleted,
        VaultEventType.galleryImported,
      ]);
      expect(list.last.params, {'n': '3'});
      expect(await s.events.unreadCount(), 2);
      await s.events.markAllRead();
      expect(await s.events.unreadCount(), 0);
      await s.events.clear();
      expect(await s.events.list(), isEmpty);
    });

    test('encrypted at rest: no event text on disk', () async {
      final s = open(VaultSpace.real, CryptoService.newKey());
      await s.events.add(VaultEventType.itemExported, {
        'name': 'secret-holiday.jpg',
      });
      final f = File('${s.dir.path}/events.gae');
      final raw = await f.readAsBytes();
      expect(CryptoService.isSealed(raw), isTrue);
      final text = latin1.decode(raw, allowInvalid: true);
      expect(text.contains('secret'), isFalse);
      expect(text.contains('itemExported'), isFalse);
    });

    test('real and decoy spaces have separate logs', () async {
      final real = open(VaultSpace.real, CryptoService.newKey());
      final decoy = open(VaultSpace.decoy, CryptoService.newKey());
      await real.events.add(VaultEventType.secondPhoneCreated);
      expect(await decoy.events.list(), isEmpty);
      expect(
        (await real.events.list()).single.type,
        VaultEventType.secondPhoneCreated,
      );
    });

    test('concurrent adds are not lost; capped at maxEvents', () async {
      final s = open(VaultSpace.real, CryptoService.newKey());
      await Future.wait([
        for (var i = 0; i < 20; i++)
          s.events.add(VaultEventType.filesImported, {'n': '$i'}),
      ]);
      expect((await s.events.list()).length, 20);
      for (var i = 0; i < VaultEventLog.maxEvents; i++) {
        await s.events.add(VaultEventType.filesImported, {'n': 'x$i'});
      }
      expect((await s.events.list()).length, VaultEventLog.maxEvents);
    });

    test('unknown event types are skipped', () {
      expect(VaultEvent.fromJson({'type': 'fromTheFuture'}), isNull);
    });
  });

  test('messages are localized with params in TR and EN', () {
    final e = VaultEvent(
      id: '1',
      type: VaultEventType.galleryImported,
      at: DateTime(2026),
      params: {'n': '4'},
    );
    L10n.setLang('en');
    expect(eventMessage(L10n.current, e), '4 photo(s) added to Gallery');
    L10n.setLang('tr');
    expect(eventMessage(L10n.current, e), 'Galeriye 4 fotoğraf eklendi');
    for (final type in VaultEventType.values) {
      final msg = eventMessage(
        L10n.current,
        VaultEvent(id: 'x', type: type, at: DateTime(2026)),
      );
      expect(msg.startsWith('ev'), isFalse, reason: '$type has no string');
    }
  });

  test(
    'auth counts wrong PIN-pad attempts until the next real unlock',
    () async {
      final auth = AuthService(
        storage: MemorySecureKv(),
        pbkdf2Iterations: 1000,
      );
      await auth.setPin('2580');
      await auth.setDecoyPin('1111');
      await auth.check('9999');
      await auth.check('8888');
      await auth.check('0000', countFailure: false); // calculator: not counted
      // Decoy unlock resets the lockout counter but keeps the report.
      expect(await auth.check('1111'), PinCheck.decoy);
      expect(await auth.takeFailuresSinceUnlock(), 2);
      expect(await auth.takeFailuresSinceUnlock(), 0);
    },
  );

  testWidgets('failed attempts show in the real vault notification list', (
    tester,
  ) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'lang': 'en'});
    final settings = await SettingsService.create();
    final auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await auth.setPin('2580');
      await auth.check('1234');
      await auth.check('4321');
      await auth.check('5555');
    });
    await settings.setCalculatorEntryEnabled(false);

    await tester.pumpWidget(
      GizliAlanApp(
        settings: settings,
        auth: auth,
        biometrics: _NoBiometrics(),
        baseDirProvider: () async => tmp,
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    await tester.runAsync(() => state.enterVault(VaultSpace.real));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Badge with 1 unread on the Notifications tile (async encrypted read).
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    final tile = find.byKey(const ValueKey('tile_notifications'));
    expect(tile, findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('1')), findsOneWidget);

    await tester.tap(tile);
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(
      find.text('3 wrong PIN attempt(s) since your last unlock'),
      findsOneWidget,
    );

    // Unread entry has the dot; mark-read/clear are covered by the
    // VaultEventLog unit tests (async encrypted writes).
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byKey(const ValueKey('notif_mark_read')), findsOneWidget);
    expect(find.byKey(const ValueKey('notif_clear')), findsOneWidget);
  });
}
