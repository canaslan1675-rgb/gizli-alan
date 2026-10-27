import 'package:flutter/material.dart' show ThemeMode;

import '../theme.dart' show AccentPreset;

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
  static const _kPlayPro = 'play_pro_active';
  static const _kFreeBannerDismissed = 'free_banner_dismissed';
  static const _kHideCalcInfo = 'hide_calc_info_icon';
  static const _kDeleteOriginal = 'delete_original_after_import';
  static const _kDeleteOriginalAsked = 'delete_original_asked';
  static const _kBrowserEngine = 'browser_engine';
  static const _kBrowserWipe = 'browser_wipe_on_lock';
  static const _kSecondPhoneClose = 'second_phone_close';
  static const _kSecondPhoneClosedBy = 'second_phone_closed_by';
  static const _kThemeMode = 'theme_mode';
  static const _kAccent = 'accent_color';
  static const _kAnalytics = 'analytics_enabled';
  static const _kJoiOnline = 'joi_online_consent';

  /// Seconds before auto-lock after leaving the app or the screen turning
  /// off. 0 = immediately. Legacy values (15 s, 5 min) snap onto these.
  static const lockTimeoutChoices = [0, 30, 60];

  /// Maps a stored or chosen value onto [lockTimeoutChoices].
  static int normalizeLockTimeout(int sec) {
    if (sec <= 0) return 0;
    if (sec <= 30) return 30;
    return 60;
  }

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

  /// `play`: cached Google Play Pro purchase state (ProBilling). Re-checked
  /// against Play on every start; read through [ProEntitlement].
  bool get playProActive => _prefs.getBool(_kPlayPro) ?? false;

  Future<void> setPlayProActive(bool v) => _prefs.setBool(_kPlayPro, v);

  /// The vault-home "limited free version" card was dismissed.
  bool get freeBannerDismissed =>
      _prefs.getBool(_kFreeBannerDismissed) ?? false;

  Future<void> setFreeBannerDismissed(bool v) =>
      _prefs.setBool(_kFreeBannerDismissed, v);

  /// User opt-in (Pro only): hide the ⓘ button on the calculator. Must be
  /// readable before unlock, so it lives in app settings (like the
  /// calculator-entry switch). Effective value: ProEntitlement.
  bool get hideCalcInfoIcon => _prefs.getBool(_kHideCalcInfo) ?? false;

  Future<void> setHideCalcInfoIcon(bool v) => _prefs.setBool(_kHideCalcInfo, v);

  /// User opt-in (free, #37): delete the phone's original after a verified
  /// import. Effective value: ProEntitlement.deleteOriginalAfterImport.
  bool get deleteOriginalAfterImport =>
      _prefs.getBool(_kDeleteOriginal) ?? false;

  Future<void> setDeleteOriginalAfterImport(bool v) =>
      _prefs.setBool(_kDeleteOriginal, v);

  /// The one-time "delete originals?" prompt after the first gallery import
  /// was answered (or the user set the switch in Settings themselves).
  bool get deleteOriginalAsked =>
      _prefs.getBool(_kDeleteOriginalAsked) ?? false;

  Future<void> setDeleteOriginalAsked() =>
      _prefs.setBool(_kDeleteOriginalAsked, true);

  /// Biometric unlock for the real vault (never opens the decoy vault).
  bool get biometricEnabled => _prefs.getBool(_kBiometric) ?? false;

  Future<void> setBiometricEnabled(bool v) => _prefs.setBool(_kBiometric, v);

  /// Seconds in background before auto-lock. 0 = lock immediately.
  /// Reads snap a previously stored 15 s onto 30 s and 5 min onto 1 min.
  int get lockTimeoutSec =>
      normalizeLockTimeout(_prefs.getInt(_kLockTimeout) ?? 0);

  Future<void> setLockTimeoutSec(int sec) =>
      _prefs.setInt(_kLockTimeout, normalizeLockTimeout(sec));

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
  /// is locked. Default [SecondPhoneCloseMode.quiet] (hide apps + try to pause).
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

  /// Appearance (v0.5.1): System / Light / Dark for the calculator and the
  /// vault screens. Readable before unlock (the calculator uses it), so it
  /// lives here. Default dark = the look of every earlier version.
  ThemeMode get themeMode => parseThemeMode(_prefs.getString(_kThemeMode));

  Future<void> setThemeMode(ThemeMode m) =>
      _prefs.setString(_kThemeMode, m.name);

  static ThemeMode parseThemeMode(String? v) => switch (v) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    _ => ThemeMode.dark,
  };

  /// Accent colour preset (v0.5.2). Local only; default mint.
  AccentPreset get accent => AccentPreset.parse(_prefs.getString(_kAccent));

  Future<void> setAccent(AccentPreset a) => _prefs.setString(_kAccent, a.name);

  /// "Anonim istatistik ve reklam ölçümü" (0.6.1): AppMetrica + TikTok
  /// App Events data sending. Default on; see lib/services/analytics.dart.
  bool get analyticsEnabled => _prefs.getBool(_kAnalytics) ?? true;

  Future<void> setAnalyticsEnabled(bool v) => _prefs.setBool(_kAnalytics, v);

  /// Joi online answers (0.6.2): user consented to sending general
  /// questions (never notes) to Google Gemini. Default off; revocable in
  /// Settings. Without it Joi makes no network call.
  bool get joiOnlineConsent => _prefs.getBool(_kJoiOnline) ?? false;

  Future<void> setJoiOnlineConsent(bool v) => _prefs.setBool(_kJoiOnline, v);

  String get language => _prefs.getString(_kLang) ?? 'tr';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(_kLang, L10n.supported.contains(code) ? code : 'tr');
    L10n.setLang(language);
  }

  Future<void> resetAll() async {
    final lang = language;
    final theme = _prefs.getString(_kThemeMode);
    final accent = _prefs.getString(_kAccent);
    // Keep "the work apps are currently hidden by us" across a vault reset,
    // so the next real unlock still unhides them (#30).
    final closedBy = _prefs.getString(_kSecondPhoneClosedBy);
    final analytics = _prefs.getBool(_kAnalytics);
    await _prefs.clear();
    if (analytics != null) await _prefs.setBool(_kAnalytics, analytics);
    await setLanguage(lang);
    if (theme != null) await _prefs.setString(_kThemeMode, theme);
    if (accent != null) await _prefs.setString(_kAccent, accent);
    if (closedBy != null) {
      await _prefs.setString(_kSecondPhoneClosedBy, closedBy);
    }
  }
}
