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

  test('no dev footer on vault home and no "Created with Grok" in the UI', () {
    final home = File('lib/screens/vault_home_screen.dart').readAsStringSync();
    expect(home.contains('home_watermark'), isFalse);
    expect(home.contains('vault: unlocked'), isFalse);
    expect(home.contains('PBKDF2'), isFalse);
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      expect(
        f.readAsStringSync().contains('Created with Grok'),
        isFalse,
        reason: f.path,
      );
    }
  });
}
