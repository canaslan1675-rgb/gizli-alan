import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app_version.dart';
import 'package:gizlialan/theme.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/decoy_calculator_screen.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/crypto_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart' show FakeBiometrics;

/// 1×1 PNG (valid image bytes for MemoryImage).
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_bg');
  });

  tearDown(() async {
    Flavor.debugOverride = null;
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('VaultSession home background', () {
    test('default none; set, read back encrypted, remove', () async {
      final key = CryptoService.newKey();
      final s = VaultSession(space: VaultSpace.real, key: key, baseDir: tmp);
      expect(await s.homeBackgroundId(), isNull);
      expect(await s.homeBackgroundBytes(), isNull);

      final item = await s.gallery.add(
        name: 'bg.png',
        bytes: Uint8List.fromList(_png),
      );
      await s.setHomeBackgroundId(item.id);

      // Fresh session: choice persisted, bytes decrypted in memory.
      final s2 = VaultSession(space: VaultSpace.real, key: key, baseDir: tmp);
      expect(await s2.homeBackgroundId(), item.id);
      expect(await s2.homeBackgroundBytes(), _png);

      // The choice is stored sealed, never as plain text.
      final f = File('${s2.dir.path}/home_background.gae');
      final raw = await f.readAsBytes();
      expect(CryptoService.isSealed(raw), isTrue);
      expect(latin1.decode(raw, allowInvalid: true).contains(item.id), false);

      await s2.setHomeBackgroundId(null);
      expect(await s2.homeBackgroundId(), isNull);
      expect(await f.exists(), isFalse);
    });

    test('deleting the photo from the gallery clears the background', () async {
      final key = CryptoService.newKey();
      final s = VaultSession(space: VaultSpace.real, key: key, baseDir: tmp);
      final item = await s.gallery.add(
        name: 'bg.png',
        bytes: Uint8List.fromList(_png),
      );
      await s.setHomeBackgroundId(item.id);
      await s.gallery.delete(item);
      expect(await s.homeBackgroundBytes(), isNull);
      expect(await s.homeBackgroundId(), isNull);
    });

    test('each space has its own background', () async {
      final real = VaultSession(
        space: VaultSpace.real,
        key: CryptoService.newKey(),
        baseDir: tmp,
      );
      final decoy = VaultSession(
        space: VaultSpace.decoy,
        key: CryptoService.newKey(),
        baseDir: tmp,
      );
      final item = await real.gallery.add(
        name: 'bg.png',
        bytes: Uint8List.fromList(_png),
      );
      await real.setHomeBackgroundId(item.id);
      expect(await decoy.homeBackgroundId(), isNull);
    });
  });

  testWidgets(
    'Gallery long-press sets the home background; Settings removes it',
    (tester) async {
      await initializeDateFormatting();
      SharedPreferences.setMockInitialValues({'lang': 'tr'});
      late SettingsService settings;
      late AuthService auth;
      await tester.runAsync(() async {
        settings = await SettingsService.create();
        auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
        await auth.setPin('2580');
      });
      Flavor.debugOverride = AppFlavor.play;
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      BoxDecoration homeDecoration() =>
          tester
                  .widget<Container>(
                    find.byKey(const ValueKey('vault_home_background')),
                  )
                  .decoration!
              as BoxDecoration;

      await tester.pumpWidget(
        GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: FakeBiometrics(),
          baseDirProvider: () async => tmp,
        ),
      );
      await settle();
      // Calculator disguise has no background mechanism at all.
      expect(find.byType(DecoyCalculatorScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_home_background')), findsNothing);
      expect(find.byKey(const ValueKey('home_watermark')), findsNothing);

      for (final k in [...'2580'.split(''), '=']) {
        await tester.tap(find.byKey(ValueKey('calc_$k')));
        await tester.pump();
      }
      await settle();
      expect(find.byType(VaultHomeScreen), findsOneWidget);
      // Default: the bundled owner picture (AssetImage), no colour filter.
      expect(homeDecoration().image!.image, isA<AssetImage>());
      expect(
        (homeDecoration().image!.image as AssetImage).assetName,
        GizliTheme.defaultWallpaperAsset,
      );
      // Desktop-style watermark above the dock, not interactive.
      expect(find.byKey(const ValueKey('home_watermark')), findsOneWidget);
      expect(
        find.textContaining('v$appVersion (build $appBuild)  ·  play'),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('home_watermark')),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );

      final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
      await tester.runAsync(
        () => state.session!.gallery.add(
          name: 'bg.png',
          bytes: Uint8List.fromList(_png),
        ),
      );

      // Gallery → long-press the photo → "Ana ekran arka planı yap".
      await tester.tap(find.text('Galeri').first);
      await settle();
      await tester.longPress(find.byKey(const ValueKey('gallery_thumb_0')));
      await settle();
      expect(find.byKey(const ValueKey('photo_opt_open')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo_opt_export')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo_opt_delete')), findsOneWidget);
      expect(find.text('Ana ekran arka planı yap'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo_opt_background')));
      await settle();
      expect(
        await tester.runAsync(() => state.session!.homeBackgroundId()),
        isNotNull,
      );
      await tester.pageBack();
      await settle();
      await settle();

      final withPhoto = homeDecoration();
      expect(withPhoto.image, isNotNull);
      expect(withPhoto.image!.image, isA<MemoryImage>());
      expect(withPhoto.image!.colorFilter, isNotNull); // readability scrim
      expect(find.byKey(const ValueKey('home_watermark')), findsOneWidget);

      // Settings shows the state and only offers removal.
      // Through the home icon, like the owner (home reloads on return).
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle();
      final remove = find.byKey(
        const ValueKey('settings_home_background_remove'),
      );
      await tester.scrollUntilVisible(
        remove,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(remove);
      expect(find.text('Arka planı kaldır'), findsOneWidget);
      await settle();
      await tester.tap(remove);
      await settle();
      await tester.pageBack();
      await settle();
      await settle();
      // Removing the vault photo goes back to the default picture.
      expect(homeDecoration().image!.image, isA<AssetImage>());

      // "Düz renk": picking a colour swatch switches to the plain gradient.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle();
      final swatch = find.byKey(const ValueKey('settings_wallpaper_1'));
      await tester.scrollUntilVisible(
        swatch,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(swatch);
      await settle();
      await tester.tap(swatch);
      await settle();
      expect(settings.wallpaperImage, isFalse);
      await tester.pageBack();
      await settle();
      expect(homeDecoration().image, isNull);
      expect(homeDecoration().gradient, isNotNull);
    },
  );

  test('only the owner default wallpaper is bundled; no new permissions', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('- assets/wallpapers/default.jpg'), isTrue);
    expect(RegExp('assets/').allMatches(pubspec).length, 1);
    expect(
      File('assets/wallpapers/default.jpg').lengthSync(),
      lessThan(400000),
    );
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      isNot(contains('READ_MEDIA_IMAGES"/>')),
    );
  });
}
