import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Non-secret user preferences (stored in SharedPreferences, app sandbox).
///
/// Encryption is no longer optional: all vault content is always AES-256-GCM
/// encrypted. Secrets (PIN hashes, keys) never live here — see AuthService.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  // Key kept from the scaffold for compatibility ("decoy" = calculator entry).
  static const _kCalculatorEntry = 'decoy_enabled';
  static const _kBiometric = 'biometric_enabled';
  static const _kLockTimeout = 'lock_timeout_sec';
  static const _kLang = 'lang';
  static const _kWallpaper = 'wallpaper';

  static const lockTimeoutChoices = [0, 15, 60, 300];

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsService(prefs);
    L10n.setLang(s.language);
    return s;
  }

  /// App opens as a working calculator; typing the PIN then `=` opens the
  /// vault. When false the app opens straight to the PIN / biometric screen.
  bool get calculatorEntryEnabled => _prefs.getBool(_kCalculatorEntry) ?? true;

  Future<void> setCalculatorEntryEnabled(bool v) =>
      _prefs.setBool(_kCalculatorEntry, v);

  /// Biometric unlock for the real vault (never opens the decoy vault).
  bool get biometricEnabled => _prefs.getBool(_kBiometric) ?? false;

  Future<void> setBiometricEnabled(bool v) => _prefs.setBool(_kBiometric, v);

  /// Seconds in background before auto-lock. 0 = lock immediately.
  int get lockTimeoutSec => _prefs.getInt(_kLockTimeout) ?? 0;

  Future<void> setLockTimeoutSec(int sec) =>
      _prefs.setInt(_kLockTimeout, sec.clamp(0, 300));

  /// Index into GizliTheme.wallpapers for the vault home screen.
  int get wallpaper => _prefs.getInt(_kWallpaper) ?? 0;

  Future<void> setWallpaper(int i) => _prefs.setInt(_kWallpaper, i);

  String get language => _prefs.getString(_kLang) ?? 'tr';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_kLang, code == 'en' ? 'en' : 'tr');
    L10n.setLang(language);
  }

  Future<void> resetAll() async {
    final lang = language;
    await _prefs.clear();
    await setLanguage(lang);
  }
}
