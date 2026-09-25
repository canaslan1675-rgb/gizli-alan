import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the Android sources (issues #11, #30): the `play`
/// flavor must not contain any device-admin / profile-owner / work-profile
/// code, and the hide-while-locked feature must stay in `src/full`.
void main() {
  const src = 'android/app/src';

  Iterable<File> filesUnder(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.kt') || f.path.endsWith('.xml'));

  const forbidden = [
    'DevicePolicyManager',
    'DeviceAdminReceiver',
    'setApplicationHidden',
    'requestQuietModeEnabled',
    'HidePolicy',
    'BIND_DEVICE_ADMIN',
    'device_admin',
    'secondphone',
  ];

  test('play + main source sets contain no device-admin/work-profile code', () {
    for (final dir in ['$src/play', '$src/main']) {
      for (final f in filesUnder(dir)) {
        final text = f.readAsStringSync();
        for (final word in forbidden) {
          // Comments may mention the Second phone; code/manifest may not.
          final code = text
              .split('\n')
              .where((l) {
                final t = l.trimLeft();
                return !(t.startsWith('//') ||
                    t.startsWith('*') ||
                    t.startsWith('/*') ||
                    t.startsWith('<!--'));
              })
              .join('\n');
          expect(
            code.contains(word),
            isFalse,
            reason: '${f.path} must not contain "$word"',
          );
        }
      }
    }
  });

  test('hide-while-locked lives only in the full flavor', () {
    final policy = File(
      '$src/full/kotlin/com/offerforge/gizlialan/secondphone/HidePolicy.kt',
    );
    expect(policy.existsSync(), isTrue);
    final p = policy.readAsStringSync();
    // Essentials that must never be hidden (reinstall/manage the profile).
    for (final pkg in [
      'com.google.android.gms',
      'com.android.packageinstaller',
      'com.android.permissioncontroller',
    ]) {
      expect(p, contains('"$pkg"'));
    }
    final action = File(
      '$src/full/kotlin/com/offerforge/gizlialan/secondphone/ProfileActionActivity.kt',
    ).readAsStringSync();
    expect(action, contains('HidePolicy.toHide'));
    expect(action, contains('HidePolicy.unhideCandidates'));
    expect(
      File(
        '$src/testFull/kotlin/com/offerforge/gizlialan/secondphone/HidePolicyTest.kt',
      ).existsSync(),
      isTrue,
    );
  });

  test('no new permissions, no INTERNET, FLAG_SECURE stays', () {
    final main = File('$src/main/AndroidManifest.xml').readAsStringSync();
    final full = File('$src/full/AndroidManifest.xml').readAsStringSync();
    final granted = RegExp(
      r'<uses-permission android:name="([^"]+)"\s*/>',
    ).allMatches(main + full).map((m) => m.group(1)).toSet();
    expect(granted, {'android.permission.USE_BIOMETRIC'});
    expect(main + full, isNot(contains('android.permission.INTERNET')));
    expect(full, isNot(contains('uses-permission')));
    final activity = File(
      '$src/main/kotlin/com/offerforge/gizlialan/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('WindowManager.LayoutParams.FLAG_SECURE'));
  });
}
