import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local vault file storage under app documents.
///
/// DEFAULT BEHAVIOR: hide-only (files sit in the app sandbox, not encrypted).
/// When [encryptionEnabled] is true, file bytes are AES-encrypted before write.
///
/// HONEST COMMENT: App-sandbox hiding is NOT Android Private Space. Other apps
/// cannot read these files without root/backup access, but the app icon remains
/// visible. Encryption adds confidentiality at rest for the file payloads.
class VaultStorage {
  VaultStorage({
    FlutterSecureStorage? secure,
  }) : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _secure;
  static const _kAesKey = 'ga_aes_key_b64';

  Directory? _filesDir;

  Future<Directory> get filesDir async {
    if (_filesDir != null) return _filesDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'vault_files'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _filesDir = dir;
    return dir;
  }

  Future<List<FileSystemEntity>> listFiles() async {
    final dir = await filesDir;
    final list = dir.listSync().whereType<File>().toList();
    list.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return list;
  }

  /// Import raw bytes. If [encrypt], wraps with AES; else plain write.
  Future<File> importBytes({
    required String fileName,
    required Uint8List bytes,
    required bool encrypt,
  }) async {
    final dir = await filesDir;
    final safe = _safeName(fileName);
    final outPath = p.join(dir.path, safe);
    final file = File(outPath);

    if (encrypt) {
      final sealed = await _encrypt(bytes);
      // Store as .gaenc with metadata header
      final payload = jsonEncode({
        'v': 1,
        'name': fileName,
        'data': base64Encode(sealed),
      });
      final encPath = outPath.endsWith('.gaenc') ? outPath : '$outPath.gaenc';
      return File(encPath).writeAsString(payload);
    } else {
      return file.writeAsBytes(bytes);
    }
  }

  Future<Uint8List> readFile(File file, {required bool decryptIfNeeded}) async {
    if (file.path.endsWith('.gaenc') && decryptIfNeeded) {
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final data = base64Decode(map['data'] as String);
      return _decrypt(Uint8List.fromList(data));
    }
    return file.readAsBytes();
  }

  Future<String?> displayName(File file) async {
    if (file.path.endsWith('.gaenc')) {
      try {
        final raw = await file.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return map['name'] as String?;
      } catch (_) {
        return p.basename(file.path);
      }
    }
    return p.basename(file.path);
  }

  Future<void> deleteFile(File file) async {
    if (await file.exists()) await file.delete();
  }

  Future<void> wipeAll() async {
    final dir = await filesDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  String _safeName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w\.\-]+'), '_');
    if (base.isEmpty) return 'file_${DateTime.now().millisecondsSinceEpoch}';
    // Avoid overwrite
    return '${DateTime.now().millisecondsSinceEpoch}_$base';
  }

  Future<enc.Key> _aesKey() async {
    var b64 = await _secure.read(key: _kAesKey);
    if (b64 == null) {
      final r = Random.secure();
      final bytes = List<int>.generate(32, (_) => r.nextInt(256));
      b64 = base64Encode(bytes);
      await _secure.write(key: _kAesKey, value: b64);
    }
    return enc.Key.fromBase64(b64);
  }

  Future<Uint8List> _encrypt(Uint8List plain) async {
    final key = await _aesKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plain, iv: iv);
    // IV || ciphertext
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  Future<Uint8List> _decrypt(Uint8List sealed) async {
    final key = await _aesKey();
    final iv = enc.IV(sealed.sublist(0, 16));
    final cipher = sealed.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(cipher), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Future<void> clearKey() async {
    await _secure.delete(key: _kAesKey);
  }
}
