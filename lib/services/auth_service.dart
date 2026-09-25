import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as legacy;

import 'crypto_service.dart';
import 'secure_kv.dart';
import 'vault_space.dart';

/// Outcome of a PIN check.
enum PinCheck { real, decoy, invalid, lockedOut }

/// PIN + key management.
///
/// * PINs are 4–8 digits. Only a PBKDF2-HMAC-SHA256 hash (random salt) is
///   stored, in Android Keystore-backed secure storage.
/// * Each [VaultSpace] has its own random 256-bit data key (DEK), also kept in
///   secure storage. Vault content is AES-256-GCM encrypted with it.
/// * Optional decoy PIN opens the separate, empty decoy space.
/// * Brute-force throttling: after [freeAttempts] wrong PINs, a growing
///   lockout (30 s, 60 s, … capped at 15 min) applies.
///
/// HONEST LIMITS: the DEK lives in the Keystore-backed store, not wrapped by
/// the PIN (so biometrics can unlock without the PIN). This protects against
/// casual access, other apps and file-level copies, but not against a fully
/// compromised/rooted device with the phone unlocked. It is not a replacement
/// for Android Private Space or full-disk encryption.
class AuthService {
  AuthService({
    SecureKv? storage,
    this.pbkdf2Iterations = CryptoService.defaultPbkdf2Iterations,
    DateTime Function()? clock,
  }) : _kv = storage ?? FlutterSecureKv(),
       _now = clock ?? DateTime.now;

  final SecureKv _kv;
  final int pbkdf2Iterations;
  final DateTime Function() _now;

  static const int minPinLength = 4;
  static const int maxPinLength = 8;
  static const int freeAttempts = 5;
  static const Duration maxLockout = Duration(minutes: 15);

  static const _kPin = 'ga_pin_v2';
  static const _kDecoyPin = 'ga_decoy_pin_v2';
  static const _kOnboarded = 'ga_onboarded';
  static const _kFailCount = 'ga_fail_count';
  static const _kLockUntil = 'ga_lock_until_ms';
  // Wrong PIN-pad attempts since the last REAL unlock (survives decoy unlocks,
  // so it is only ever reported inside the real vault).
  static const _kFailSinceUnlock = 'ga_fail_since_unlock';
  // Legacy scaffold format (sha256(salt::pin)). Migrated on first success.
  static const _kLegacySalt = 'ga_pin_salt';
  static const _kLegacyHash = 'ga_pin_hash';

  static String _dekKey(VaultSpace s) => 'ga_dek_${s.name}';

  static bool isValidPinFormat(String pin) =>
      pin.length >= minPinLength &&
      pin.length <= maxPinLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  // ---------------------------------------------------------------- state

  Future<bool> isOnboarded() async => await _kv.read(_kOnboarded) == '1';

  Future<bool> hasPin() async =>
      await _kv.read(_kPin) != null || await _kv.read(_kLegacyHash) != null;

  Future<bool> hasDecoyPin() async => await _kv.read(_kDecoyPin) != null;

  // ---------------------------------------------------------------- set

  /// Sets or replaces the real PIN and marks onboarding complete.
  Future<void> setPin(String pin) async {
    _requireFormat(pin);
    if (await _matches(_kDecoyPin, pin)) {
      throw ArgumentError('PIN must differ from decoy PIN');
    }
    await _kv.write(_kPin, await _hashRecord(pin));
    await _kv.delete(_kLegacySalt);
    await _kv.delete(_kLegacyHash);
    await _kv.write(_kOnboarded, '1');
    await _ensureDek(VaultSpace.real);
  }

  /// Sets the optional decoy PIN (must differ from the real PIN).
  Future<void> setDecoyPin(String pin) async {
    _requireFormat(pin);
    if (await _matchesReal(pin)) {
      throw ArgumentError('Decoy PIN must differ from real PIN');
    }
    await _kv.write(_kDecoyPin, await _hashRecord(pin));
    await _ensureDek(VaultSpace.decoy);
  }

  /// Removes the decoy PIN and its key. Caller should wipe decoy data too.
  Future<void> clearDecoyPin() async {
    await _kv.delete(_kDecoyPin);
    await _kv.delete(_dekKey(VaultSpace.decoy));
  }

  // ---------------------------------------------------------------- verify

  /// Remaining lockout, or null if a PIN may be tried now.
  Future<Duration?> lockoutRemaining() async {
    final raw = await _kv.read(_kLockUntil);
    final until = int.tryParse(raw ?? '');
    if (until == null) return null;
    final left = until - _now().millisecondsSinceEpoch;
    return left > 0 ? Duration(milliseconds: left) : null;
  }

  /// Checks [pin] against the real and decoy PIN.
  ///
  /// [countFailure] should be true for the PIN pad and false for the
  /// calculator entry (ordinary sums like `1234=` must not lock the owner out).
  Future<PinCheck> check(String pin, {bool countFailure = true}) async {
    if (await lockoutRemaining() != null) return PinCheck.lockedOut;
    if (!isValidPinFormat(pin)) {
      if (countFailure) await _registerFailure();
      return PinCheck.invalid;
    }
    // Always evaluate both hashes so timing does not reveal a decoy PIN.
    final realOk = await _matchesReal(pin);
    final decoyOk = await _matches(_kDecoyPin, pin);
    if (realOk) {
      await _resetFailures();
      if (await _kv.read(_kPin) == null) {
        await setPin(pin); // migrate legacy hash to PBKDF2
      }
      return PinCheck.real;
    }
    if (decoyOk) {
      await _resetFailures();
      return PinCheck.decoy;
    }
    if (countFailure) await _registerFailure();
    return PinCheck.invalid;
  }

  /// Back-compat helper used by older call sites.
  Future<bool> verifyPin(String pin) async => await check(pin) == PinCheck.real;

  /// Call after a successful biometric unlock (real space only).
  Future<void> onBiometricSuccess() => _resetFailures();

  // ---------------------------------------------------------------- keys

  /// Data key for [space]. Creates it if missing (real space only, or decoy
  /// when a decoy PIN exists).
  Future<List<int>> dataKey(VaultSpace space) => _ensureDek(space);

  // ---------------------------------------------------------------- reset

  /// Removes PINs, keys and counters. Encrypted files become unreadable.
  Future<void> clearAuth() async {
    for (final k in [
      _kPin,
      _kDecoyPin,
      _kOnboarded,
      _kFailCount,
      _kLockUntil,
      _kFailSinceUnlock,
      _kLegacySalt,
      _kLegacyHash,
      _dekKey(VaultSpace.real),
      _dekKey(VaultSpace.decoy),
    ]) {
      await _kv.delete(k);
    }
  }

  // ---------------------------------------------------------------- private

  void _requireFormat(String pin) {
    if (!isValidPinFormat(pin)) {
      throw ArgumentError('PIN must be $minPinLength-$maxPinLength digits');
    }
  }

  Future<List<int>> _ensureDek(VaultSpace space) async {
    final existing = await _kv.read(_dekKey(space));
    if (existing != null) return base64Decode(existing);
    final key = CryptoService.newKey();
    await _kv.write(_dekKey(space), base64Encode(key));
    return key;
  }

  Future<String> _hashRecord(String pin) async {
    final salt = CryptoService.randomBytes(16);
    final hash = await CryptoService.pbkdf2(
      pin,
      salt,
      iterations: pbkdf2Iterations,
    );
    return jsonEncode({
      'v': 2,
      'alg': 'pbkdf2-sha256',
      'it': pbkdf2Iterations,
      'salt': base64Encode(salt),
      'hash': base64Encode(hash),
    });
  }

  Future<bool> _matches(String storageKey, String pin) async {
    final raw = await _kv.read(storageKey);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final salt = base64Decode(m['salt'] as String);
      final expected = base64Decode(m['hash'] as String);
      final it = (m['it'] as num).toInt();
      final got = await CryptoService.pbkdf2(pin, salt, iterations: it);
      return CryptoService.constantTimeEquals(got, expected);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matchesReal(String pin) async {
    if (await _kv.read(_kPin) != null) return _matches(_kPin, pin);
    // Legacy scaffold hash.
    final salt = await _kv.read(_kLegacySalt);
    final hash = await _kv.read(_kLegacyHash);
    if (salt == null || hash == null) return false;
    final got = legacy.sha256.convert(utf8.encode('$salt::$pin')).toString();
    return CryptoService.constantTimeEquals(
      utf8.encode(got),
      utf8.encode(hash),
    );
  }

  /// Returns and resets the number of wrong PIN-pad attempts since the last
  /// real-vault unlock. Call only when the REAL vault was opened.
  Future<int> takeFailuresSinceUnlock() async {
    final n = int.tryParse(await _kv.read(_kFailSinceUnlock) ?? '') ?? 0;
    if (n > 0) await _kv.delete(_kFailSinceUnlock);
    return n;
  }

  Future<void> _registerFailure() async {
    final since = int.tryParse(await _kv.read(_kFailSinceUnlock) ?? '') ?? 0;
    await _kv.write(_kFailSinceUnlock, '${since + 1}');
    final n = (int.tryParse(await _kv.read(_kFailCount) ?? '') ?? 0) + 1;
    await _kv.write(_kFailCount, '$n');
    if (n >= freeAttempts) {
      final step = min(n - freeAttempts, 10); // 0,1,2… (bounded)
      final secs = min(30 * pow(2, step).toInt(), maxLockout.inSeconds);
      final until = _now().add(Duration(seconds: secs));
      await _kv.write(_kLockUntil, '${until.millisecondsSinceEpoch}');
    }
  }

  Future<void> _resetFailures() async {
    await _kv.delete(_kFailCount);
    await _kv.delete(_kLockUntil);
  }
}
