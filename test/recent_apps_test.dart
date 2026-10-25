import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/recent_apps.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  test('push: newest first, unique, at most 4 (0.6.0 C)', () {
    var l = <String>[];
    for (final p in ['a', 'b', 'c', 'd', 'e', 'c']) {
      l = RecentApps.push(l, p);
    }
    expect(l, ['c', 'e', 'd', 'b']);
  });

  test('records are encrypted in the vault space', () async {
    final tmp = await Directory.systemTemp.createTemp('gizlialan_recent');
    addTearDown(() => tmp.delete(recursive: true));
    final s = VaultSession(
      space: VaultSpace.real,
      key: List<int>.filled(32, 7),
      baseDir: tmp,
    );
    await s.recentApps.record('com.example.chat');
    await s.recentApps.record('com.example.mail');
    expect(await s.recentApps.list(), ['com.example.mail', 'com.example.chat']);
    final f = File('${s.dir.path}/recent_apps.gae');
    expect(
      String.fromCharCodes(f.readAsBytesSync()).contains('example'),
      isFalse,
    );
  });

  test('no usage-stats permission anywhere', () {
    for (final f
        in Directory('android/app/src')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('AndroidManifest.xml'))) {
      expect(f.readAsStringSync().contains('PACKAGE_USAGE_STATS'), isFalse);
    }
  });
}
