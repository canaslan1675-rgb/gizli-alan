import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Install attribution / measurement (0.6.1): AppMetrica (Yandex) and the
/// TikTok App Events SDK; plus Google Analytics for Firebase (0.6.5:
/// active users, joi_question, pro_purchase).
///
/// PRIVACY CONTRACT — keep it this way:
/// - Only two kinds of data leave the device: the SDKs' automatic app
///   install / launch (session) events, and [logProPurchase] (product id,
///   price, currency). NEVER vault content, file or album names, note text,
///   PINs/hints, browser URLs or any other user-entered text.
/// - AppMetrica location tracking is off (coarse region only from IP,
///   server side). No user profile id, no email/phone (TikTok identify-by-email/phone is
///   never called).
/// - Keys are injected at build time only (`--dart-define`), never in git.
///   Empty key → that SDK is never activated (tests, local builds).
/// - Settings → "Anonim istatistik ve reklam ölçümü" ([setEnabled]) turns
///   data sending off for both SDKs; persisted in SettingsService.
class Analytics {
  Analytics._();

  static const appMetricaApiKey = String.fromEnvironment('APPMETRICA_API_KEY');
  static const tiktokAppSecret = String.fromEnvironment('TIKTOK_APP_SECRET');

  /// TikTok Events Manager App ID (not a secret; from the 0.5.9 TikTok work,
  /// commit 74a9e22). Overridable with `--dart-define=TIKTOK_APP_ID=...`.
  static const tiktokAppId = String.fromEnvironment(
    'TIKTOK_APP_ID',
    defaultValue: '7700201711725477895',
  );

  /// Pro lifetime list price reported with the purchase event.
  static const proPriceTry = 200.0;
  static const proCurrency = 'TRY';

  static const MethodChannel _tiktok = MethodChannel('gizlialan/tiktok');

  /// Google Analytics for Firebase (0.6.5) — same project as Joi online.
  static const MethodChannel _fa = MethodChannel('gizlialan/fa');
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static bool _faActive = false;
  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool _appMetricaActive = false;
  static bool _tiktokActive = false;
  static bool _enabled = true;

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get appMetricaConfigured => appMetricaApiKey.isNotEmpty;
  static bool get tiktokConfigured =>
      tiktokAppSecret.isNotEmpty && tiktokAppId.isNotEmpty;

  /// Called once from main(). Never throws.
  static Future<void> init({required bool enabled}) async {
    _enabled = enabled;
    if (!_android) return;
    if (appMetricaConfigured) {
      try {
        await AppMetrica.activate(
          AppMetricaConfig(
            appMetricaApiKey,
            locationTracking: false,
            dataSendingEnabled: enabled,
            revenueAutoTrackingEnabled: false,
            crashReporting: false,
            nativeCrashReporting: false,
            flutterCrashReporting: false,
            logs: kDebugMode,
          ),
        );
        _appMetricaActive = true;
      } catch (_) {}
    }
    if (firebaseConfigured) {
      try {
        _faActive =
            await _fa.invokeMethod<bool>('init', <String, Object>{
              'apiKey': firebaseApiKey,
              'appId': firebaseAppId,
              'projectId': firebaseProjectId,
              'enabled': enabled,
            }) ??
            false;
      } catch (_) {}
    }
    if (tiktokConfigured) {
      try {
        _tiktokActive =
            await _tiktok.invokeMethod<bool>('init', <String, Object>{
              'appSecret': tiktokAppSecret,
              'ttAppId': tiktokAppId,
              'debug': kDebugMode,
              'enabled': enabled,
            }) ??
            false;
      } catch (_) {}
    }
  }

  /// Settings toggle: stop / resume data sending for both SDKs.
  static Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (_appMetricaActive) {
      try {
        await AppMetrica.setDataSendingEnabled(enabled);
      } catch (_) {}
    }
    if (_faActive) {
      try {
        await _fa.invokeMethod<bool>('setEnabled', <String, Object>{
          'enabled': enabled,
        });
      } catch (_) {}
    }
    if (_android && tiktokConfigured) {
      try {
        await _tiktok.invokeMethod<bool>('setEnabled', <String, Object>{
          'enabled': enabled,
        });
      } catch (_) {}
    }
  }

  /// Firebase-only custom event. [params] must be enums/numbers — never
  /// user-entered text.
  static Future<void> _faEvent(String name, Map<String, Object> params) async {
    if (!_enabled || !_faActive) return;
    try {
      await _fa.invokeMethod<bool>('logEvent', <String, Object>{
        'name': name,
        'params': params,
      });
    } catch (_) {}
  }

  /// A Joi question was answered (or failed). Only backend kind + success;
  /// the question text is NEVER sent.
  static Future<void> logJoiQuestion({
    required bool online,
    required bool ok,
  }) => _faEvent('joi_question', <String, Object>{
    'backend': online ? 'online' : 'on_device',
    'ok': ok ? 1 : 0,
  });

  /// A fresh Pro purchase (never restores). Only the product id, price and
  /// currency are sent.
  static Future<void> logProPurchase({required String productId}) async {
    if (!_enabled) return;
    if (_appMetricaActive) {
      try {
        await AppMetrica.reportEventWithMap('pro_purchase', <String, Object>{
          'product_id': productId,
          'value': proPriceTry,
          'currency': proCurrency,
        });
      } catch (_) {}
    }
    await _faEvent('pro_purchase', <String, Object>{
      'product_id': productId,
      'value': proPriceTry,
      'currency': proCurrency,
    });
    if (_tiktokActive) {
      try {
        await _tiktok.invokeMethod<bool>('logPurchase', <String, Object>{
          'currency': proCurrency,
          'value': proPriceTry,
          'contentId': productId,
        });
      } catch (_) {}
    }
  }
}
