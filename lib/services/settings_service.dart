import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// User preferences: encryption toggle, decoy, lock timeout, language.
///
/// Default encryption = OFF (hide-only in app documents). Documented in README.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kEncryption = 'encryption_enabled';
  static const _kDecoy = 'decoy_enabled';
  static const _kLockTimeout = 'lock_timeout_sec';
  static const _kLang = 'lang';

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsService(prefs);
    // Apply saved language
    L10n.setLang(s.language);
    return s;
  }

  /// Optional AES for files. Default false = hide-only.
  bool get encryptionEnabled => _prefs.getBool(_kEncryption) ?? false;

  Future<void> setEncryptionEnabled(bool v) =>
      _prefs.setBool(_kEncryption, v);

  /// Show calculator decoy as root when true (default true).
  bool get decoyEnabled => _prefs.getBool(_kDecoy) ?? true;

  Future<void> setDecoyEnabled(bool v) => _prefs.setBool(_kDecoy, v);

  /// Seconds before auto-lock after app pause. Default 0 = immediate.
  int get lockTimeoutSec => _prefs.getInt(_kLockTimeout) ?? 0;

  Future<void> setLockTimeoutSec(int sec) =>
      _prefs.setInt(_kLockTimeout, sec.clamp(0, 300));

  String get language => _prefs.getString(_kLang) ?? 'tr';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_kLang, code == 'en' ? 'en' : 'tr');
    L10n.setLang(language);
  }
}
