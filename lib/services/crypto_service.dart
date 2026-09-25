import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Thrown when a sealed payload cannot be authenticated/decrypted
/// (wrong key, tampered data or unknown format).
class VaultCryptoException implements Exception {
  VaultCryptoException(this.message);
  final String message;
  @override
  String toString() => 'VaultCryptoException: $message';
}

/// Crypto primitives used by the vault.
///
/// * Content encryption: **AES-256-GCM** (authenticated), fresh random 96-bit
///   nonce per payload. On Android `cryptography_flutter` routes this to the
///   platform (javax.crypto) implementation; in unit tests the pure-Dart
///   implementation is used. Sealed format:
///   `"GAE1"` (4-byte magic, also bound as AAD) || nonce (12) || ciphertext ||
///   GCM tag (16).
/// * PIN hashing: **PBKDF2-HMAC-SHA256**, random 16-byte salt, run on a
///   background isolate so the UI does not freeze.
class CryptoService {
  CryptoService({AesGcm? aes}) : _aes = aes ?? AesGcm.with256bits();

  final AesGcm _aes;

  static final Uint8List magic = Uint8List.fromList(ascii.encode('GAE1'));
  static const int keyLength = 32;
  static const int nonceLength = 12;
  static const int tagLength = 16;
  static const int _header = 4 + nonceLength;

  /// Default PBKDF2 iteration count for PIN hashes.
  static const int defaultPbkdf2Iterations = 120000;

  static final Random _rng = Random.secure();

  static Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }

  static Uint8List newKey() => randomBytes(keyLength);

  /// AES-256-GCM encrypt [plain] with [key].
  Future<Uint8List> seal(Uint8List key, List<int> plain) async {
    _checkKey(key);
    final box = await _aes.encrypt(
      plain,
      secretKey: SecretKey(key),
      nonce: randomBytes(nonceLength),
      aad: magic,
    );
    final out = Uint8List(
      _header + box.cipherText.length + box.mac.bytes.length,
    );
    out.setAll(0, magic);
    out.setAll(4, box.nonce);
    out.setAll(_header, box.cipherText);
    out.setAll(_header + box.cipherText.length, box.mac.bytes);
    return out;
  }

  /// Decrypts a payload produced by [seal]. Throws [VaultCryptoException] if
  /// the key is wrong or the data was modified.
  Future<Uint8List> open(Uint8List key, Uint8List sealed) async {
    _checkKey(key);
    if (sealed.length < _header + tagLength) {
      throw VaultCryptoException('payload too short');
    }
    if (!isSealed(sealed)) throw VaultCryptoException('unknown format');
    final box = SecretBox(
      Uint8List.sublistView(sealed, _header, sealed.length - tagLength),
      nonce: Uint8List.sublistView(sealed, 4, _header),
      mac: Mac(Uint8List.sublistView(sealed, sealed.length - tagLength)),
    );
    try {
      final clear = await _aes.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: magic,
      );
      return clear is Uint8List ? clear : Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw VaultCryptoException('authentication failed');
    }
  }

  static bool isSealed(List<int> data) {
    if (data.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (data[i] != magic[i]) return false;
    }
    return true;
  }

  /// PBKDF2-HMAC-SHA256 of [secret] with [salt] (pure Dart, deterministic).
  static Future<Uint8List> pbkdf2(
    String secret,
    List<int> salt, {
    int iterations = defaultPbkdf2Iterations,
  }) {
    Future<Uint8List> run() async {
      final kdf = DartPbkdf2(
        macAlgorithm: const DartHmac(DartSha256()),
        iterations: iterations,
        bits: 256,
      );
      final k = await kdf.deriveKeyFromPassword(password: secret, nonce: salt);
      return Uint8List.fromList(await k.extractBytes());
    }

    // Cheap derivations (tests, legacy checks) run inline; real ones on an
    // isolate so the PIN pad stays responsive.
    if (iterations <= 5000) return run();
    return Isolate.run(run);
  }

  /// Constant-time comparison.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static void _checkKey(Uint8List key) {
    if (key.length != keyLength) {
      throw ArgumentError('AES-256 key must be $keyLength bytes');
    }
  }
}
