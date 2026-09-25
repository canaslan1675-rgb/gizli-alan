import 'package:flutter/services.dart';

/// Compile-time fallback for the app version, used when the platform
/// channel is unavailable (tests, non-Android). Must match `version:` in
/// pubspec.yaml; a unit test enforces it.
const String appVersion = '0.4.1';
const int appBuild = 7;

/// Version of the installed APK, read at runtime from Android's
/// PackageManager via the `gizlialan/system` channel (`appInfo`).
class AppInfo {
  const AppInfo(this.version, this.build);

  final String version;
  final int build;

  static const AppInfo fallback = AppInfo(appVersion, appBuild);
  static const MethodChannel _channel = MethodChannel('gizlialan/system');
  static AppInfo? _cached;

  static Future<AppInfo> load() async {
    if (_cached != null) return _cached!;
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('appInfo');
      final name = m?['versionName'];
      final code = m?['versionCode'];
      if (name is String && code is int) {
        return _cached = AppInfo(name, code);
      }
    } catch (_) {
      // No platform implementation (tests) → compile-time values.
    }
    return fallback;
  }
}
