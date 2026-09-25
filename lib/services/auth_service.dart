import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN authentication — hash with SHA-256 + random salt in secure storage.
///
/// HONEST COMMENT: This protects against casual peeking and casual filesystem
/// browsing. It is NOT a substitute for full-disk encryption or Android Private
/// Space. A rooted device or forensic tool can still attack the sandbox.
class AuthService {
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kSalt = 'ga_pin_salt';
  static const _kHash = 'ga_pin_hash';
  static const _kOnboarded = 'ga_onboarded';

  Future<bool> isOnboarded() async {
    final v = await _storage.read(key: _kOnboarded);
    return v == '1';
  }

  Future<bool> hasPin() async {
    final h = await _storage.read(key: _kHash);
    return h != null && h.isNotEmpty;
  }

  /// Set or replace PIN. Stores only salt + sha256(salt||pin).
  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN too short');
    }
    final salt = _randomSalt();
    final hash = _hash(salt, pin);
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: hash);
    await _storage.write(key: _kOnboarded, value: '1');
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final expected = await _storage.read(key: _kHash);
    if (salt == null || expected == null) return false;
    return _hash(salt, pin) == expected;
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kOnboarded);
  }

  String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String salt, String pin) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }
}
