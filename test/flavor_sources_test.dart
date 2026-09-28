import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the Android sources (issues #11, #30, #52): the lite
/// `play` flavor must not contain any device-admin / profile-owner /
/// work-profile code (that stays in `src/full`). Since v0.5.0 `full`
/// (Second phone + Play Billing) is the Play upload, same applicationId.
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
      '$src/full/kotlin/com/offerforge/gizlialan/secondphone/ProfileHider.kt',
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

  test('only USE_BIOMETRIC + INTERNET (browser), FLAG_SECURE stays', () {
    final main = File('$src/main/AndroidManifest.xml').readAsStringSync();
    final full = File('$src/full/AndroidManifest.xml').readAsStringSync();
    final granted = RegExp(
      r'<uses-permission android:name="([^"]+)"\s*/>',
    ).allMatches(main + full).map((m) => m.group(1)).toSet();
    // #32: INTERNET is the only permission added since v0.3 (in-vault
    // browser). Nothing else may appear, and location stays removed.
    expect(granted, {
      'android.permission.USE_BIOMETRIC',
      'android.permission.INTERNET',
    });
    expect(full, isNot(contains('uses-permission')));
    for (final p in ['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION']) {
      expect(
        main,
        contains(
          '<uses-permission android:name="android.permission.$p" tools:node="remove" />',
        ),
      );
    }
    expect(main, contains('android.webkit.WebView.MetricsOptOut'));
    final activity = File(
      '$src/main/kotlin/com/offerforge/gizlialan/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('WindowManager.LayoutParams.FLAG_SECURE'));
  });

  test('v0.5.0: full is the Play build (same applicationId, AAB = full)', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.offerforge.gizlialan"'));
    expect(gradle, isNot(contains('applicationIdSuffix')));
    expect(gradle, contains('create("play")'));
    expect(gradle, contains('create("full")'));

    final ci = File(
      '.github/workflows/android-test-build.yml',
    ).readAsStringSync();
    final lines = ci.split('\n');
    final apks = lines.where((l) => l.contains('flutter build apk')).toList();
    expect(apks, hasLength(2));
    for (final l in apks) {
      expect(l, contains('--target-platform android-arm64,android-x64'));
      expect(l, contains('--dart-define=PRO_STUB=true')); // test APKs only
    }
    expect(apks.any((l) => l.contains('--flavor play')), isTrue);
    expect(apks.any((l) => l.contains('--flavor full')), isTrue);
    final aab = lines.singleWhere((l) => l.contains('flutter build appbundle'));
    expect(aab, contains('--flavor full'));
    expect(aab, isNot(contains('PRO_STUB'))); // Play: real billing only
  });
}
