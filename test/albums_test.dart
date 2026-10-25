import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/gallery_albums.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:gizlialan/widgets/pro_gate.dart';

void main() {
  late Directory tmp;
  late VaultSession s;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_albums');
    s = VaultSession(
      space: VaultSpace.real,
      key: List<int>.filled(32, 3),
      baseDir: tmp,
    );
  });
  tearDown(() => tmp.delete(recursive: true));

  group('albums (0.6.0 H)', () {
    test('limit rule: free 1, Pro unlimited', () {
      expect(AlbumLimit.canCreate(pro: false, existing: 0), isTrue);
      expect(AlbumLimit.canCreate(pro: false, existing: 1), isFalse);
      expect(AlbumLimit.canCreate(pro: true, existing: 99), isTrue);
    });

    test('free user gets one album; Pro more; lapsed Pro keeps them', () async {
      await s.albums.create('Tatil', pro: false);
      expect(
        () => s.albums.create('İkinci', pro: false),
        throwsA(isA<StateError>()),
      );
      await s.albums.create('İkinci', pro: true);
      await s.albums.create('Üçüncü', pro: true);
      expect((await s.albums.list()).map((a) => a.name), [
        'Tatil',
        'İkinci',
        'Üçüncü',
      ]);
    });

    test('albums do not change item counting; deleting keeps photos', () async {
      final a = await s.albums.create('Tatil', pro: false);
      final p1 = await s.gallery.add(name: '1.jpg', bytes: Uint8List(3));
      await s.gallery.add(name: '2.jpg', bytes: Uint8List(3));
      final before = await ItemLimit.storedIn(s);
      await s.albums.move(p1, a.id);
      expect(await ItemLimit.storedIn(s), before);
      final inAlbum = (await s.gallery.list()).where((i) => i.album == a.id);
      expect(inAlbum.single.name, '1.jpg');
      await s.albums.delete(a.id);
      expect(await s.albums.list(), isEmpty);
      final items = await s.gallery.list();
      expect(items.length, 2);
      expect(items.every((i) => i.album == null), isTrue);
    });

    test('album names are not stored in plaintext', () async {
      await s.albums.create('GizliTatil', pro: false);
      final f = File('${s.dir.path}/gallery/albums.gae');
      expect(
        String.fromCharCodes(f.readAsBytesSync()).contains('Gizli'),
        isFalse,
      );
    });
  });
}
