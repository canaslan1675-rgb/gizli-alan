import 'dart:convert';

import 'package:crypto/crypto.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  late MemorySecureKv kv;
  late DateTime now;
  late AuthService auth;

  setUp(() {
    kv = MemorySecureKv();
    now = DateTime(2026, 9, 25, 12);
    auth = AuthService(storage: kv, pbkdf2Iterations: 1000, clock: () => now);
  });

  test('PIN format validation', () {
    expect(AuthService.isValidPinFormat('1234'), isTrue);
    expect(AuthService.isValidPinFormat('12345678'), isTrue);
    expect(AuthService.isValidPinFormat('123'), isFalse);
    expect(AuthService.isValidPinFormat('123456789'), isFalse);
    expect(AuthService.isValidPinFormat('12a4'), isFalse);
    expect(() => auth.setPin('12'), throwsArgumentError);
  });

  test('setPin stores only a salted PBKDF2 hash and onboards', () async {
    expect(await auth.isOnboarded(), isFalse);
    await auth.setPin('2580');
    expect(await auth.isOnboarded(), isTrue);
    expect(await auth.hasPin(), isTrue);
    final stored = kv.data.values.join('|');
    expect(stored.contains('2580'), isFalse);
    final rec = jsonDecode(kv.data['ga_pin_v2']!) as Map<String, dynamic>;
    expect(rec['alg'], 'pbkdf2-sha256');
    expect(rec['it'], 1000);
  });

  test('check: real, wrong, decoy', () async {
    await auth.setPin('2580');
    expect(await auth.check('2580'), PinCheck.real);
    expect(await auth.check('0000'), PinCheck.invalid);
    expect(await auth.hasDecoyPin(), isFalse);

    await auth.setDecoyPin('1111');
    expect(await auth.hasDecoyPin(), isTrue);
    expect(await auth.check('1111'), PinCheck.decoy);
    expect(await auth.check('2580'), PinCheck.real);
  });

  test('real and decoy PIN must differ', () async {
    await auth.setPin('2580');
    expect(() => auth.setDecoyPin('2580'), throwsArgumentError);
    await auth.setDecoyPin('1111');
    expect(() => auth.setPin('1111'), throwsArgumentError);
  });

  test('clearDecoyPin disables decoy and drops its key', () async {
    await auth.setPin('2580');
    await auth.setDecoyPin('1111');
    await auth.clearDecoyPin();
    expect(await auth.check('1111'), PinCheck.invalid);
    expect(kv.data.containsKey('ga_dek_decoy'), isFalse);
  });

  test('lockout after repeated failures, growing and expiring', () async {
    await auth.setPin('2580');
    for (var i = 0; i < AuthService.freeAttempts - 1; i++) {
      expect(await auth.check('0000'), PinCheck.invalid);
    }
    expect(await auth.lockoutRemaining(), isNull);
    expect(await auth.check('0000'), PinCheck.invalid); // 5th → lockout
    expect(await auth.lockoutRemaining(), const Duration(seconds: 30));
    // Even the right PIN is refused while locked out.
    expect(await auth.check('2580'), PinCheck.lockedOut);

    now = now.add(const Duration(seconds: 31));
    expect(await auth.lockoutRemaining(), isNull);
    expect(await auth.check('0000'), PinCheck.invalid); // 6th → 60 s
    expect(await auth.lockoutRemaining(), const Duration(seconds: 60));

    now = now.add(const Duration(seconds: 61));
    expect(await auth.check('2580'), PinCheck.real);
    expect(kv.data.containsKey('ga_fail_count'), isFalse);
  });

  test('lockout is capped', () async {
    await auth.setPin('2580');
    for (var i = 0; i < 40; i++) {
      await auth.check('0000');
      now = now.add(const Duration(hours: 1));
    }
    await auth.check('0000');
    expect(await auth.lockoutRemaining(), AuthService.maxLockout);
  });

  test('calculator checks do not count as failures', () async {
    await auth.setPin('2580');
    for (var i = 0; i < 20; i++) {
      expect(await auth.check('1234', countFailure: false), PinCheck.invalid);
    }
    expect(await auth.lockoutRemaining(), isNull);
    expect(await auth.check('2580', countFailure: false), PinCheck.real);
  });

  test('data keys: 256-bit, stable, separate per space', () async {
    await auth.setPin('2580');
    await auth.setDecoyPin('1111');
    final real1 = await auth.dataKey(VaultSpace.real);
    final real2 = await auth.dataKey(VaultSpace.real);
    final decoy = await auth.dataKey(VaultSpace.decoy);
    expect(real1.length, 32);
    expect(real1, real2);
    expect(real1, isNot(decoy));
    // Changing the PIN must not change the data key (content stays readable).
    await auth.setPin('9999');
    expect(await auth.dataKey(VaultSpace.real), real1);
  });

  test('legacy scaffold sha256 PIN is accepted and migrated', () async {
    const salt = 'legacysalt';
    kv.data['ga_pin_salt'] = salt;
    kv.data['ga_pin_hash'] = legacy.sha256
        .convert(utf8.encode('$salt::4321'))
        .toString();
    kv.data['ga_onboarded'] = '1';
    expect(await auth.hasPin(), isTrue);
    expect(await auth.check('0000'), PinCheck.invalid);
    expect(await auth.check('4321'), PinCheck.real);
    expect(kv.data.containsKey('ga_pin_hash'), isFalse);
    expect(kv.data.containsKey('ga_pin_v2'), isTrue);
    expect(await auth.check('4321'), PinCheck.real);
  });

  test('clearAuth removes everything', () async {
    await auth.setPin('2580');
    await auth.setDecoyPin('1111');
    await auth.clearAuth();
    expect(kv.data, isEmpty);
    expect(await auth.isOnboarded(), isFalse);
  });
}
