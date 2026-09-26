import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'browser_logic.dart';
import 'second_phone_service.dart';

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
  static const _kWallpaperImage = 'wallpaper_image';
  static const _kProStub = 'pro_stub_active';
  static const _kHideCalcInfo = 'hide_calc_info_icon';
  static const _kDeleteOriginal = 'delete_original_after_import';
  static const _kBrowserEngine = 'browser_engine';
  static const _kBrowserWipe = 'browser_wipe_on_lock';
  static const _kSecondPhoneClose = 'second_phone_close';
  static const _kSecondPhoneClosedBy = 'second_phone_closed_by';

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

  /// Test-only Pro entitlement for builds with the Pro UI stub (no billing).
  /// Read through [ProEntitlement], never directly by UI.
  bool get proStubActive => _prefs.getBool(_kProStub) ?? false;

  Future<void> setProStubActive(bool v) => _prefs.setBool(_kProStub, v);

  /// User opt-in (Pro only): hide the ⓘ button on the calculator. Must be
  /// readable before unlock, so it lives in app settings (like the
  /// calculator-entry switch). Effective value: ProEntitlement.
  bool get hideCalcInfoIcon => _prefs.getBool(_kHideCalcInfo) ?? false;

  Future<void> setHideCalcInfoIcon(bool v) => _prefs.setBool(_kHideCalcInfo, v);

  /// User opt-in (Pro only, #37): delete the phone's original after a
  /// verified import. Effective value: ProEntitlement.
  bool get deleteOriginalAfterImport =>
      _prefs.getBool(_kDeleteOriginal) ?? false;

  Future<void> setDeleteOriginalAfterImport(bool v) =>
      _prefs.setBool(_kDeleteOriginal, v);

  /// Biometric unlock for the real vault (never opens the decoy vault).
  bool get biometricEnabled => _prefs.getBool(_kBiometric) ?? false;

  Future<void> setBiometricEnabled(bool v) => _prefs.setBool(_kBiometric, v);

  /// Seconds in background before auto-lock. 0 = lock immediately.
  int get lockTimeoutSec => _prefs.getInt(_kLockTimeout) ?? 0;

  Future<void> setLockTimeoutSec(int sec) =>
      _prefs.setInt(_kLockTimeout, sec.clamp(0, 300));

  /// Index into GizliTheme.wallpapers for the vault home screen.
  int get wallpaper => _prefs.getInt(_kWallpaper) ?? 0;

  /// Choosing a plain colour also turns the bundled default image off.
  Future<void> setWallpaper(int i) async {
    await _prefs.setInt(_kWallpaper, i);
    await _prefs.setBool(_kWallpaperImage, false);
  }

  /// Vault home uses the bundled default image (assets/wallpapers/default.jpg,
  /// provided by the owner) when no vault photo is chosen. Default true.
  bool get wallpaperImage => _prefs.getBool(_kWallpaperImage) ?? true;

  Future<void> setWallpaperImage(bool v) => _prefs.setBool(_kWallpaperImage, v);

  /// What happens to the second phone (work profile) while the real vault
  /// is locked. Default [SecondPhoneCloseMode.freeze] (hide work apps).
  SecondPhoneCloseMode get secondPhoneCloseMode =>
      SecondPhoneCloseMode.parse(_prefs.getString(_kSecondPhoneClose));

  Future<void> setSecondPhoneCloseMode(SecondPhoneCloseMode m) =>
      _prefs.setString(_kSecondPhoneClose, m.name);

  /// "Kilitliyken iş uygulamalarını gizle" / "Hide work apps while locked"
  /// (issue #30). Default on.
  bool get hideWorkAppsWhenLocked =>
      secondPhoneCloseMode != SecondPhoneCloseMode.off;

  Future<void> setHideWorkAppsWhenLocked(bool v) => setSecondPhoneCloseMode(
    !v
        ? SecondPhoneCloseMode.off
        : (secondPhoneCloseMode == SecondPhoneCloseMode.quiet
              ? SecondPhoneCloseMode.quiet
              : SecondPhoneCloseMode.freeze),
  );

  /// Additionally try to pause the work profile (quiet mode) when hiding.
  bool get pauseWorkProfileWhenLocked =>
      secondPhoneCloseMode == SecondPhoneCloseMode.quiet;

  /// Only meaningful while [hideWorkAppsWhenLocked] is on.
  Future<void> setPauseWorkProfileWhenLocked(bool v) async {
    if (!hideWorkAppsWhenLocked) return;
    await setSecondPhoneCloseMode(
      v ? SecondPhoneCloseMode.quiet : SecondPhoneCloseMode.freeze,
    );
  }

  /// How the second phone was closed at the last lock (null = not closed by
  /// us), so the next unlock can re-open it the same way.
  SecondPhoneCloseMode? get secondPhoneClosedBy {
    final v = _prefs.getString(_kSecondPhoneClosedBy);
    return v == null ? null : SecondPhoneCloseMode.parse(v);
  }

  Future<void> setSecondPhoneClosedBy(SecondPhoneCloseMode? m) => m == null
      ? _prefs.remove(_kSecondPhoneClosedBy)
      : _prefs.setString(_kSecondPhoneClosedBy, m.name);

  /// Private browser (#32): search engine for address-bar queries.
  SearchEngine get browserSearchEngine =>
      SearchEngine.parse(_prefs.getString(_kBrowserEngine));

  Future<void> setBrowserSearchEngine(SearchEngine e) =>
      _prefs.setString(_kBrowserEngine, e.name);

  /// "Kilitlenince temizle": wipe browser cookies/cache/storage when the
  /// vault locks. Default on.
  bool get browserWipeOnLock => _prefs.getBool(_kBrowserWipe) ?? true;

  Future<void> setBrowserWipeOnLock(bool v) => _prefs.setBool(_kBrowserWipe, v);

  String get language => _prefs.getString(_kLang) ?? 'tr';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_kLang, code == 'en' ? 'en' : 'tr');
    L10n.setLang(language);
  }

  Future<void> resetAll() async {
    final lang = language;
    // Keep "the work apps are currently hidden by us" across a vault reset,
    // so the next real unlock still unhides them (#30).
    final closedBy = _prefs.getString(_kSecondPhoneClosedBy);
    await _prefs.clear();
    await setLanguage(lang);
    if (closedBy != null) {
      await _prefs.setString(_kSecondPhoneClosedBy, closedBy);
    }
  }
}
