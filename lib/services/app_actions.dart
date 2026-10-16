import 'package:flutter/services.dart';

import 'privacy_link.dart';

/// Share / Rate / Feedback rows in Settings (v0.5.1+, tester feedback).
///
/// Plain Android intents through the existing `gizlialan/system` channel
/// (see SystemChannel.kt): no SDK, no network access of our own, nothing
/// about the user's vault leaves the app.
class AppActions {
  AppActions._();

  static const String packageName = 'com.offerforge.gizlialan';

  /// Public Play listing (shared and used as the Rate fallback).
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  /// Feedback goes to the same support address as the Support row.
  static const String feedbackEmail = PrivacyLink.supportEmail;

  static const MethodChannel _channel = PrivacyLink.channel;

  /// The text shared by "Share app": a neutral line plus the listing link.
  /// [intro] is a localized sentence that must not mention the vault (the
  /// app sits behind a calculator; the recipient sees only this).
  static String shareText(String intro) => '$intro $storeUrl';

  /// Subject of the feedback e-mail, e.g.
  /// "GizliAlan geri bildirim [Hata] v0.5.3 (22)".
  /// [category] is a short localized label (Bug / Suggestion / Other);
  /// it goes in the subject only — never in auto-filled vault/device data.
  static String feedbackSubject(
    String prefix,
    String version,
    int build, {
    String? category,
  }) {
    final cat = (category == null || category.isEmpty) ? '' : ' [$category]';
    return '$prefix$cat v$version ($build)';
  }

  static Future<bool> share(String text, {String? title}) =>
      _invoke('shareApp', {'text': text, 'title': title});

  /// Opens the Play listing (Play Store app, else a browser).
  static Future<bool> openStore() => _invoke('openStore');

  /// Opens a mailto: intent. [body] is optional and must be user-typed only
  /// (never auto-insert device IDs, logs, or vault data).
  static Future<bool> sendFeedback(String subject, {String? body}) {
    final args = <String, Object?>{'subject': subject};
    final trimmed = body?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      args['body'] = trimmed;
    }
    return _invoke('sendFeedback', args);
  }

  static Future<bool> _invoke(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
