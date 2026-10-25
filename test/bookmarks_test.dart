import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/bookmarks.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  late Directory tmp;
  late VaultSession s;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_bm');
    s = VaultSession(
      space: VaultSpace.real,
      key: List<int>.filled(32, 9),
      baseDir: tmp,
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  group('bookmarks (0.6.0 K)', () {
    test('limit rule: free 5, Pro unlimited', () {
      expect(BookmarkLimit.canAdd(pro: false, existing: 4), isTrue);
      expect(BookmarkLimit.canAdd(pro: false, existing: 5), isFalse);
      expect(BookmarkLimit.canAdd(pro: true, existing: 500), isTrue);
    });

    test('free: 6th add throws, re-adding an existing url is fine', () async {
      for (var i = 0; i < 5; i++) {
        await s.bookmarks.add('s$i', 'https://e$i.example/', pro: false);
      }
      expect(
        () => s.bookmarks.add('x', 'https://x.example/', pro: false),
        throwsA(isA<StateError>()),
      );
      await s.bookmarks.add('renamed', 'https://e0.example/', pro: false);
      expect((await s.bookmarks.list()).first.title, 'renamed');
      await s.bookmarks.add('x', 'https://x.example/', pro: true);
      expect((await s.bookmarks.list()).length, 6);
      await s.bookmarks.remove('https://x.example/');
      expect(await s.bookmarks.contains('https://x.example/'), isFalse);
    });

    test('stored encrypted; real and decoy spaces are separate', () async {
      await s.bookmarks.add('gizli', 'https://secret.example/', pro: false);
      final f = File('${s.dir.path}/bookmarks.gae');
      expect(
        String.fromCharCodes(f.readAsBytesSync()).contains('secret'),
        isFalse,
      );
      final d = VaultSession(
        space: VaultSpace.decoy,
        key: List<int>.filled(32, 8),
        baseDir: tmp,
      );
      expect(await d.bookmarks.list(), isEmpty);
    });
  });
}
