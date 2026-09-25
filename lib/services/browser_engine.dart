import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'browser_logic.dart';

/// Minimal browser surface used by BrowserScreen, so the screen can be
/// widget-tested with a fake (the real one needs Android System WebView).
abstract class BrowserEngine {
  /// Current page URL ('' = start page).
  ValueListenable<String> get url;

  /// 0–100 while loading, 100 when done.
  ValueListenable<int> get progress;

  Widget view();
  Future<void> load(Uri uri);
  Future<bool> canGoBack();
  Future<bool> canGoForward();
  Future<void> goBack();
  Future<void> goForward();
  Future<void> reload();
  void dispose();
}

typedef BrowserEngineFactory =
    BrowserEngine Function({required void Function(String url) onBlocked});

/// Android System WebView, locked down for private browsing inside the vault:
/// - JavaScript on (needed by most sites) but **no JavaScript channels**: the
///   page cannot call into GizliAlan;
/// - no file / content:// access, no geolocation, every web permission
///   request (camera, microphone, MIDI…) denied, no file chooser;
/// - third-party cookies blocked; only http(s) navigations allowed;
/// - downloads are not handled (no DownloadListener) — nothing is saved.
/// Cookies/cache/storage live in the app-private WebView directory and are
/// wiped on lock by [BrowserData.wipe] (setting "Kilitlenince temizle").
class WebViewBrowserEngine implements BrowserEngine {
  WebViewBrowserEngine({required void Function(String url) onBlocked}) {
    _controller = WebViewController(onPermissionRequest: (r) => r.deny())
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1220))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            if (BrowserLogic.isAllowedNavigation(req.url)) {
              return NavigationDecision.navigate;
            }
            onBlocked(req.url);
            return NavigationDecision.prevent;
          },
          onUrlChange: (c) => _url.value = c.url ?? _url.value,
          onPageStarted: (u) => _url.value = u,
          onProgress: (p) => _progress.value = p,
          onPageFinished: (_) => _progress.value = 100,
        ),
      );
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform
        ..setAllowFileAccess(false)
        ..setAllowContentAccess(false)
        ..setGeolocationEnabled(false)
        ..setMediaPlaybackRequiresUserGesture(true);
      AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      ).setAcceptThirdPartyCookies(platform, false);
    }
  }

  late final WebViewController _controller;
  final _url = ValueNotifier<String>('');
  final _progress = ValueNotifier<int>(100);

  @override
  ValueListenable<String> get url => _url;

  @override
  ValueListenable<int> get progress => _progress;

  @override
  Widget view() => WebViewWidget(controller: _controller);

  @override
  Future<void> load(Uri uri) => _controller.loadRequest(uri);

  @override
  Future<bool> canGoBack() => _controller.canGoBack();

  @override
  Future<bool> canGoForward() => _controller.canGoForward();

  @override
  Future<void> goBack() => _controller.goBack();

  @override
  Future<void> goForward() => _controller.goForward();

  @override
  Future<void> reload() => _controller.reload();

  @override
  void dispose() {
    _url.dispose();
    _progress.dispose();
  }
}

/// Wipes everything the WebView stored (cookies, cache, DOM/local storage,
/// IndexedDB, form data, HTTP auth) via the Kotlin `gizlialan/system`
/// channel. Called on vault lock and on app start when "Kilitlenince
/// temizle" is on, and from Settings → "Şimdi temizle".
class BrowserData {
  BrowserData._();

  static const MethodChannel channel = MethodChannel('gizlialan/system');

  static Future<bool> wipe() async {
    try {
      return await channel.invokeMethod<bool>('wipeWebData') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
