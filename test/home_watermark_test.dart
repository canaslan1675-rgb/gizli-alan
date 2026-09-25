import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app_version.dart';

void main() {
  test('appVersion matches pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(
      r'^version:\s*([0-9.]+)\+',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(appVersion, m.group(1));
    final b = RegExp(
      r'^version:\s*[0-9.]+\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(appBuild, int.parse(b.group(1)!));
  });

  test('watermark lives on the vault home only, never the calculator', () {
    final home = File('lib/screens/vault_home_screen.dart').readAsStringSync();
    expect(home.contains("ValueKey('home_watermark')"), isTrue);
    expect(home.contains('OfferForge'), isTrue);
    // Technical terms must come from the real implementation.
    final crypto = File('lib/services/crypto_service.dart').readAsStringSync();
    expect(crypto.contains('AesGcm.with256bits()'), isTrue);
    expect(crypto.contains('DartHmac(DartSha256())'), isTrue);
    expect(home.contains('CryptoService.keyLength * 8'), isTrue);
    expect(home.contains('CryptoService.defaultPbkdf2Iterations'), isTrue);
    final main = File('lib/main.dart').readAsStringSync();
    expect(
      main.contains('FLAG_SECURE') ||
          File(
            'android/app/src/main/kotlin/com/offerforge/gizlialan/MainActivity.kt',
          ).readAsStringSync().contains('FLAG_SECURE'),
      isTrue,
    );
    expect(main.contains('AuthService()'), isTrue); // default iterations
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (f.path.endsWith('vault_home_screen.dart')) continue;
      if (f.path.endsWith('app_version.dart')) continue;
      expect(
        f.readAsStringSync().contains('home_watermark'),
        isFalse,
        reason: f.path,
      );
    }
  });
  test('default wallpaper attribution is shown in both languages', () {
    expect(
      File('lib/l10n/tr.dart').readAsStringSync(),
      contains('Varsayılan arka plan: Created with Grok'),
    );
    expect(
      File('lib/l10n/en.dart').readAsStringSync(),
      contains('Default background: Created with Grok'),
    );
    expect(
      File('lib/screens/settings_screen.dart').readAsStringSync(),
      contains("t('wallpaperAttribution')"),
    );
  });
}
