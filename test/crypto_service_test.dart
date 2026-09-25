import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/crypto_service.dart';

String hex(List<int> b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

void main() {
  final crypto = CryptoService();

  group('AES-256-GCM seal/open', () {
    test('round-trips data', () async {
      final key = CryptoService.newKey();
      final plain = Uint8List.fromList(utf8.encode('gizli not 🔒'));
      final sealed = await crypto.seal(key, plain);
      expect(await crypto.open(key, sealed), plain);
    });

    test('round-trips empty and larger payloads', () async {
      final key = CryptoService.newKey();
      for (final size in [0, 1, 4096, 300 * 1024]) {
        final plain = CryptoService.randomBytes(size);
        final sealed = await crypto.seal(key, plain);
        expect(sealed.length, size + 4 + 12 + 16);
        expect(await crypto.open(key, sealed), plain);
      }
    });

    test(
      'ciphertext has magic header and does not contain plaintext',
      () async {
        final key = CryptoService.newKey();
        final plain = Uint8List.fromList(utf8.encode('SECRET-SECRET-SECRET'));
        final sealed = await crypto.seal(key, plain);
        expect(CryptoService.isSealed(sealed), isTrue);
        expect(
          latin1.decode(sealed, allowInvalid: true).contains('SECRET'),
          isFalse,
        );
      },
    );

    test('uses a fresh nonce every time', () async {
      final key = CryptoService.newKey();
      final plain = Uint8List.fromList([1, 2, 3]);
      final a = await crypto.seal(key, plain);
      final b = await crypto.seal(key, plain);
      expect(hex(a), isNot(hex(b)));
    });

    test('wrong key is rejected', () async {
      final sealed = await crypto.seal(
        CryptoService.newKey(),
        Uint8List.fromList([9]),
      );
      expect(
        () => crypto.open(CryptoService.newKey(), sealed),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('tampering is detected', () async {
      final key = CryptoService.newKey();
      final sealed = await crypto.seal(
        key,
        Uint8List.fromList(List.filled(64, 7)),
      );
      for (final pos in [5, 20, sealed.length - 1]) {
        final bad = Uint8List.fromList(sealed);
        bad[pos] ^= 0x01;
        expect(
          () => crypto.open(key, bad),
          throwsA(isA<VaultCryptoException>()),
        );
      }
    });

    test('garbage / truncated input is rejected', () async {
      final key = CryptoService.newKey();
      expect(
        () => crypto.open(key, Uint8List(10)),
        throwsA(isA<VaultCryptoException>()),
      );
      expect(
        () => crypto.open(key, Uint8List(64)),
        throwsA(isA<VaultCryptoException>()),
      );
    });

    test('rejects keys that are not 256-bit', () {
      expect(
        () => crypto.seal(Uint8List(16), Uint8List(1)),
        throwsArgumentError,
      );
    });
  });

  group('PBKDF2-HMAC-SHA256', () {
    test('matches RFC 7914 / known test vectors', () async {
      final salt = utf8.encode('salt');
      expect(
        hex(await CryptoService.pbkdf2('password', salt, iterations: 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(await CryptoService.pbkdf2('password', salt, iterations: 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('different salts give different hashes', () async {
      final a = await CryptoService.pbkdf2('1234', [1], iterations: 10);
      final b = await CryptoService.pbkdf2('1234', [2], iterations: 10);
      expect(hex(a), isNot(hex(b)));
    });
  });

  test('constantTimeEquals', () {
    expect(CryptoService.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(CryptoService.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(CryptoService.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}
