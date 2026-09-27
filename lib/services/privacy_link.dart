import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional link to the hosted privacy policy (issue #28, Play User Data
/// policy: the policy must be reachable inside the app).
///
/// Defaults to the GitHub Pages policy; can be overridden at build time with
/// `--dart-define=PRIVACY_URL=https://…`. Only `https` URLs with a host are
/// accepted; otherwise the app shows its built-in privacy text only. Opening the link hands it to the browser with a
/// plain `ACTION_VIEW` intent via [channel] — no url_launcher and no
/// `<queries>` entries. (Since v0.4.0 the app has INTERNET for the in-vault
/// browser only; the policy link still opens in the user's own browser.)
class PrivacyLink {
  PrivacyLink._();

  static const String defaultUrl =
      'https://canaslan1675-rgb.github.io/gizli-alan/privacy/';

  static const String configured = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: defaultUrl,
  );

  /// Support / KVKK application address (also in the privacy policy).
  static const String supportEmail = 'delibaltabaris5@gmail.com';

  static const MethodChannel channel = MethodChannel('gizlialan/system');

  static String? _override;

  @visibleForTesting
  static set debugUrlOverride(String? v) => _override = v;

  /// The validated policy URL, or null when none is configured.
  static String? get url {
    final u = (_override ?? configured).trim();
    return isValid(u) ? u : null;
  }

  static bool isValid(String u) {
    final uri = Uri.tryParse(u);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !u.contains(' ');
  }

  /// Opens the user's e-mail app for [supportEmail] (`mailto:`). Returns
  /// false when there is none; callers then copy the address.
  static Future<bool> openMail() async {
    try {
      return await channel.invokeMethod<bool>('openUrl', {
            'url': 'mailto:$supportEmail',
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Asks Android to open [u] in a browser. Returns false if there is no
  /// browser (or the URL is invalid); callers then offer "copy link".
  static Future<bool> open(String u) async {
    if (!isValid(u)) return false;
    try {
      return await channel.invokeMethod<bool>('openUrl', {'url': u}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
