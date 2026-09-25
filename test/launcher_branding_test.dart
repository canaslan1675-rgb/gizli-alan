import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/tr.dart';

/// Guards the neutral launcher name and its disclosure (Play: the calculator
/// look is fine as long as the vault is disclosed, never hidden).
void main() {
  const res = 'android/app/src/main/res';

  String appName(String folder) {
    final xml = File('$res/$folder/strings.xml').readAsStringSync();
    final m = RegExp(
      r'<string name="app_name">([^<]*)</string>',
    ).firstMatch(xml);
    return m!.group(1)!;
  }

  test('launcher label is a neutral calculator name in EN and TR', () {
    expect(appName('values'), 'Calculator');
    expect(appName('values-tr'), 'Hesap Makinesi');
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
  });

  test('adaptive icon has foreground, background and monochrome layers', () {
    final xml = File(
      '$res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('@color/ic_launcher_background'));
    expect(xml, contains('@drawable/ic_launcher_monochrome'));
  });

  test(
    'in-app strings match the launcher name and still disclose the vault',
    () {
      expect(en['launcherName'], appName('values'));
      expect(tr['launcherName'], appName('values-tr'));
      for (final m in [en, tr]) {
        expect(m['calcInfoBody'], contains('GizliAlan'));
        expect(m['entryDisclosure'], contains('GizliAlan'));
        expect(m['calcInfoBody'], contains(m['launcherName']));
      }
    },
  );
}
