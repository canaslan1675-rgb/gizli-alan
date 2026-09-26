import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'browser_download.dart';
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
    BrowserEngine Function({
      required void Function(String url) onBlocked,
      required void Function(DownloadRequest r) onDownload,
      required void Function(DownloadRequest r) onImageLongPress,
    });

/// Android System WebView, locked down for private browsing inside the vault:
/// - JavaScript on (needed by most sites) but **no JavaScript channels**: the
///   page cannot call into GizliAlan;
/// - no file / content:// access, no geolocation, every web permission
///   request (camera, microphone, MIDI…) denied, no file chooser;
/// - third-party cookies blocked; only http(s) navigations allowed;
/// - downloads never touch public storage: the native DownloadListener and
///   image long-press (Kotlin `gizlialan/browser`, #45) hand the URL to
///   [onDownload] / [onImageLongPress], which save into the encrypted vault.
/// Cookies/cache/storage live in the app-private WebView directory and are
/// wiped on lock by [BrowserData.wipe] (setting "Kilitlenince temizle").
class WebViewBrowserEngine implements BrowserEngine {
  WebViewBrowserEngine({
    required void Function(String url) onBlocked,
    required void Function(DownloadRequest r) onDownload,
    required void Function(DownloadRequest r) onImageLongPress,
  }) {
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
      _channel.setMethodCallHandler((call) async {
        final args = call.arguments;
        if (args is! Map) return;
        if (call.method == 'download') {
          onDownload(DownloadRequest.fromMap(args));
        } else if (call.method == 'imageLongPress') {
          onImageLongPress(DownloadRequest.fromMap(args, imageOnly: true));
        }
      });
      _webViewId = platform.webViewIdentifier;
    }
  }

  static const MethodChannel _channel = MethodChannel('gizlialan/browser');
  int? _webViewId;

  /// (Re)installs the native download / long-press hooks. Done before each
  /// load: webview_flutter installs its own DownloadListener when the
  /// navigation delegate is set, and ours must be the one that stays.
  Future<void> _attachHooks() async {
    final id = _webViewId;
    if (id == null) return;
    try {
      await _channel.invokeMethod<bool>('attach', {'id': id});
    } catch (_) {}
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
  Future<void> load(Uri uri) async {
    await _attachHooks();
    await _controller.loadRequest(uri);
  }

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
    _channel.setMethodCallHandler(null);
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
