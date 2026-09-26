import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/browser_screen.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/browser_download.dart';
import 'package:gizlialan/services/browser_engine.dart';
import 'package:gizlialan/services/browser_logic.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart' show FakeBiometrics;

class FakeEngine implements BrowserEngine {
  FakeEngine(this.onBlocked, [this.onDownload, this.onImageLongPress]);

  final void Function(String url) onBlocked;
  final void Function(DownloadRequest r)? onDownload;
  final void Function(DownloadRequest r)? onImageLongPress;
  final loads = <Uri>[];
  final _url = ValueNotifier<String>('');
  final _progress = ValueNotifier<int>(100);
  bool disposed = false;

  @override
  ValueListenable<String> get url => _url;
  @override
  ValueListenable<int> get progress => _progress;
  @override
  Widget view() => Text('PAGE ${_url.value}', key: const ValueKey('fake_page'));
  @override
  Future<void> load(Uri uri) async {
    loads.add(uri);
    _url.value = uri.toString();
  }

  @override
  Future<bool> canGoBack() async => loads.length > 1;
  @override
  Future<bool> canGoForward() async => false;
  @override
  Future<void> goBack() async {}
  @override
  Future<void> goForward() async {}
  @override
  Future<void> reload() async {}
  @override
  void dispose() => disposed = true;
}

void main() {
  group('BrowserLogic', () {
    const ddg = SearchEngine.duckduckgo;

    test('web addresses load directly, bare domains get https', () {
      expect(
        BrowserLogic.resolve('https://example.com/a?b=1', ddg).toString(),
        'https://example.com/a?b=1',
      );
      expect(
        BrowserLogic.resolve('http://example.org', ddg).toString(),
        'http://example.org',
      );
      expect(
        BrowserLogic.resolve('  wikipedia.org ', ddg).toString(),
        'https://wikipedia.org',
      );
      expect(
        BrowserLogic.resolve('tr.wikipedia.org/wiki/Kedi', ddg).toString(),
        'https://tr.wikipedia.org/wiki/Kedi',
      );
      expect(
        BrowserLogic.resolve('localhost:8080', ddg).toString(),
        'https://localhost:8080',
      );
    });

    test('everything else is a search with the chosen engine', () {
      expect(
        BrowserLogic.resolve('kedi mama fiyatı', ddg).toString(),
        'https://duckduckgo.com/?q=kedi+mama+fiyat%C4%B1',
      );
      expect(
        BrowserLogic.resolve('flutter', SearchEngine.startpage).toString(),
        'https://www.startpage.com/do/search?q=flutter',
      );
      expect(BrowserLogic.resolve('   ', ddg), isNull);
    });

    test('dangerous schemes are never opened, only searched', () {
      for (final s in [
        'file:///data/data/com.offerforge.gizlialan/x',
        'content://media/external/images/1',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;end',
      ]) {
        final u = BrowserLogic.resolve(s, ddg)!;
        expect(u.host, 'duckduckgo.com', reason: s);
      }
    });

    test('navigation allow-list: http(s) and about:blank only', () {
      expect(BrowserLogic.isAllowedNavigation('https://a.com'), isTrue);
      expect(BrowserLogic.isAllowedNavigation('http://a.com'), isTrue);
      expect(BrowserLogic.isAllowedNavigation('about:blank'), isTrue);
      for (final u in [
        'tel:123',
        'mailto:a@b.c',
        'intent://x',
        'market://details?id=x',
        'file:///sdcard/a',
        'content://x',
        'javascript:void(0)',
        'data:text/html,hi',
      ]) {
        expect(BrowserLogic.isAllowedNavigation(u), isFalse, reason: u);
      }
    });

    test('search engine parse defaults to DuckDuckGo', () {
      expect(SearchEngine.parse(null), SearchEngine.duckduckgo);
      expect(SearchEngine.parse('bogus'), SearchEngine.duckduckgo);
      expect(SearchEngine.parse('brave'), SearchEngine.brave);
    });
  });

  test('settings defaults: DuckDuckGo, clear on lock ON', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    expect(s.browserSearchEngine, SearchEngine.duckduckgo);
    expect(s.browserWipeOnLock, isTrue);
    await s.setBrowserSearchEngine(SearchEngine.bing);
    await s.setBrowserWipeOnLock(false);
    expect(s.browserSearchEngine, SearchEngine.bing);
    expect(s.browserWipeOnLock, isFalse);
  });

  test(
    'engine source: no JS bridges, no file access, 3rd-party cookies off',
    () {
      final src = File('lib/services/browser_engine.dart').readAsStringSync();
      expect(src, isNot(contains('addJavaScriptChannel')));
      expect(src, isNot(contains('loadFile')));
      expect(src, contains('setAllowFileAccess(false)'));
      expect(src, contains('setAllowContentAccess(false)'));
      expect(src, contains('setGeolocationEnabled(false)'));
      expect(src, contains('setAcceptThirdPartyCookies(platform, false)'));
      expect(src, contains('r.deny()'));
      expect(src, isNot(contains('setOnShowFileSelector')));
      // No analytics / crash / ads SDKs in the app.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final sdk in [
        'firebase',
        'sentry',
        'crashlytics',
        'google_mobile_ads',
        'analytics',
        'amplitude',
        'mixpanel',
      ]) {
        expect(pubspec.contains(sdk), isFalse, reason: sdk);
      }
    },
  );

  group('browser in the vault', () {
    late Directory tmp;
    late AuthService auth;
    late SettingsService settings;
    late List<FakeEngine> engines;
    late int wipes;

    setUp(() async {
      await initializeDateFormatting();
      SharedPreferences.setMockInitialValues({'lang': 'tr'});
      settings = await SettingsService.create();
      auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
      tmp = await Directory.systemTemp.createTemp('gizlialan_browser');
      engines = [];
      wipes = 0;
      Flavor.debugOverride = AppFlavor.play;
    });

    tearDown(() async {
      Flavor.debugOverride = null;
      L10n.setLang('tr');
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    /// Waits (real time; encryption runs off the UI isolate) until [text]
    /// is no longer shown.
    Future<void> untilGone(WidgetTester tester, String text) async {
      for (var i = 0; i < 50 && find.text(text).evaluate().isNotEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<GizliAlanAppState> openVault(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => auth.setPin('2580'));
      await tester.pumpWidget(
        GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: FakeBiometrics(),
          baseDirProvider: () async => tmp,
          browserEngineFactory:
              ({
                required onBlocked,
                required onDownload,
                required onImageLongPress,
              }) {
                final e = FakeEngine(onBlocked, onDownload, onImageLongPress);
                engines.add(e);
                return e;
              },
          wipeBrowserData: () async {
            wipes++;
            return true;
          },
        ),
      );
      await settle(tester);
      for (final k in [...'2580'.split(''), '=']) {
        await tester.tap(find.byKey(ValueKey('calc_$k')));
        await tester.pump();
      }
      await settle(tester);
      expect(find.byType(VaultHomeScreen), findsOneWidget);
      return tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
    }

    testWidgets('Tarayıcı tile opens the browser; search uses DuckDuckGo; '
        'lock wipes and closes it', (tester) async {
      await openVault(tester);
      final wipesAtStart = wipes; // app start wipe (setting on)
      expect(wipesAtStart, 1);
      await tester.tap(find.text('Tarayıcı'));
      await settle(tester);
      expect(find.byType(BrowserScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('browser_privacy_note')),
        findsOneWidget,
      );
      expect(engines.single.loads, isEmpty); // nothing loads by itself

      await tester.enterText(
        find.byKey(const ValueKey('browser_address')),
        'gizli kasa',
      );
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester);
      expect(
        engines.single.loads.single.toString(),
        'https://duckduckgo.com/?q=gizli+kasa',
      );
      expect(find.byKey(const ValueKey('fake_page')), findsOneWidget);

      // Blocked scheme → message, nothing opened.
      engines.single.onBlocked('tel:123');
      await tester.pump();
      expect(
        find.textContaining('kasa tarayıcısından açılmaz'),
        findsOneWidget,
      );

      // Lock: browser route closes, engine disposed, data wiped.
      GizliAlanApp.of(tester.element(find.byType(BrowserScreen))).lockVault();
      await settle(tester);
      expect(find.byType(BrowserScreen), findsNothing);
      expect(engines.single.disposed, isTrue);
      expect(wipes, wipesAtStart + 1);
    });

    testWidgets('long-press image -> Save to vault -> encrypted Photos; '
        'other downloads -> vault Files (#45)', (tester) async {
      final state = await openVault(tester);
      await tester.tap(find.text('Tarayıcı'));
      await settle(tester);
      const pngB64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      engines.single.onImageLongPress!(
        const DownloadRequest(
          url: 'data:image/png;base64,$pngB64',
          imageOnly: true,
        ),
      );
      await settle(tester);
      expect(find.text('Resmi kasaya kaydet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('browser_save_image')));
      await settle(tester);
      await untilGone(tester, 'Kasaya indiriliyor…');
      expect(find.textContaining("Fotoğraflar'a kaydedildi"), findsOneWidget);
      final photos = await tester.runAsync(() => state.session!.gallery.list());
      expect(photos!.single.mime, 'image/png');

      engines.single.onDownload!(
        const DownloadRequest(
          url: 'data:text/plain;base64,aGVsbG8=',
          contentDisposition: 'attachment; filename="not.txt"',
        ),
      );
      await settle(tester);
      await untilGone(tester, 'Kasaya indiriliyor…');
      expect(
        find.textContaining("Dosyalar'a kaydedildi: not.txt"),
        findsOneWidget,
      );
      final files = await tester.runAsync(() => state.session!.files.list());
      expect(files!.single.name, 'not.txt');

      // Unsupported download: message, nothing stored.
      engines.single.onDownload!(
        const DownloadRequest(url: 'blob:https://x/1'),
      );
      await settle(tester);
      expect(find.textContaining('kaydedilemez'), findsOneWidget);
      expect(
        (await tester.runAsync(() => state.session!.files.list()))!.length,
        1,
      );
    });

    testWidgets('clear on lock OFF: no wipe; engine choice is used', (
      tester,
    ) async {
      await settings.setBrowserWipeOnLock(false);
      await settings.setBrowserSearchEngine(SearchEngine.brave);
      final state = await openVault(tester);
      expect(wipes, 0);
      await tester.tap(find.text('Tarayıcı'));
      await settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('browser_address')),
        'test',
      );
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await settle(tester);
      expect(engines.single.loads.single.host, 'search.brave.com');
      state.lockVault();
      await settle(tester);
      expect(wipes, 0);
    });

    testWidgets('Settings: browser section, wipe now', (tester) async {
      await openVault(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
      final sw = find.byKey(const ValueKey('settings_browser_wipe'));
      await tester.scrollUntilVisible(
        sw,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(sw);
      await settle(tester);
      expect(find.text('Kilitlenince temizle'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(sw).value, isTrue);
      final wipeNow = find.byKey(const ValueKey('settings_browser_wipe_now'));
      await tester.scrollUntilVisible(
        wipeNow,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(wipeNow);
      await settle(tester);
      final before = wipes;
      await tester.tap(wipeNow);
      await settle(tester);
      expect(wipes, before + 1);
      expect(find.text('Tarayıcı verileri temizlendi.'), findsOneWidget);
    });
  });

  test('privacy texts no longer claim "no internet permission"', () {
    for (final lang in ['tr', 'en']) {
      L10n.setLang(lang);
      for (final k in ['privacyBody', 'privacyBody_play']) {
        final text = L10n.current.t(k).toLowerCase();
        expect(text.contains('no internet permission'), isFalse);
        expect(text.contains('internet izni yok'), isFalse);
        expect(
          text.contains('browser') || text.contains('tarayıcı'),
          isTrue,
          reason: '$lang $k',
        );
      }
    }
    L10n.setLang('tr');
  });
}
