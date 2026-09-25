import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value abstraction over secret storage so services can be unit
/// tested without platform channels.
abstract class SecureKv {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore-backed storage via flutter_secure_storage.
///
/// `resetOnError` is disabled on purpose: silently wiping the store on a
/// Keystore hiccup would destroy the vault keys (= permanent data loss).
class FlutterSecureKv implements SecureKv {
  FlutterSecureKv([FlutterSecureStorage? storage])
    : _s =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
          );

  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// In-memory implementation for tests.
class MemorySecureKv implements SecureKv {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}
