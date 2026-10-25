import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/vault_backup.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  late Directory tmp;
  setUp(
    () async => tmp = await Directory.systemTemp.createTemp('gizlialan_bk'),
  );
  tearDown(() => tmp.delete(recursive: true));

  VaultSession open(String sub, int k) => VaultSession(
    space: VaultSpace.real,
    key: List<int>.filled(32, k),
    baseDir: Directory('${tmp.path}/$sub'),
  );

  final backup = VaultBackup(iterations: 1000);

  group('backup (0.6.0 L)', () {
    test(
      'round-trip into another device/key, no plaintext, idempotent',
      () async {
        final a = open('a', 1);
        final photo = Uint8List.fromList(List.generate(300, (i) => i % 256));
        final album = await a.albums.create('Tatil', pro: true);
        final p = await a.gallery.add(name: 'deniz.jpg', bytes: photo);
        await a.albums.move(p, album.id);
        await a.files.add(name: 'belge.pdf', bytes: Uint8List.fromList([7, 7]));
        await a.notes.create(title: 'GizliNot', body: 'içerik');
        await a.bookmarks.add('ex', 'https://example.org/', pro: false);
        final trashed = await a.files.add(name: 'cop.txt', bytes: Uint8List(1));
        await a.files.delete(trashed);

        final file = await backup.create(a, 'parola123');
        expect(String.fromCharCodes(file.sublist(0, 4)), 'GABK');
        final asText = String.fromCharCodes(file);
        for (final w in ['GizliNot', 'deniz', 'belge', 'example', 'Tatil']) {
          expect(asText.contains(w), isFalse, reason: w);
        }

        final b = open('b', 2);
        await b.notes.create(title: 'mevcut');
        final r = await backup.restore(b, file, 'parola123');
        expect([r.photos, r.files, r.notes], [1, 1, 1]);
        final g = await b.gallery.list();
        expect(await b.gallery.read(g.single), photo);
        expect(g.single.album, album.id);
        expect((await b.albums.list()).single.name, 'Tatil');
        expect((await b.files.list()).single.name, 'belge.pdf');
        expect((await b.notes.list()).map((n) => n.title).toSet(), {
          'mevcut',
          'GizliNot',
        });
        expect((await b.bookmarks.list()).single.url, 'https://example.org/');
        expect(await b.files.listTrash(), isEmpty, reason: 'bin not backed up');

        final again = await backup.restore(b, file, 'parola123');
        expect(again.total, 0);
        expect((await b.gallery.list()).length, 1);
      },
    );

    test('wrong password and foreign files are rejected', () async {
      final a = open('a', 1);
      await a.notes.create(title: 'x');
      final file = await backup.create(a, 'parola123');
      final b = open('b', 2);
      await expectLater(
        backup.restore(b, file, 'yanlis99'),
        throwsA(
          isA<BackupException>().having((e) => e.reason, 'r', 'password'),
        ),
      );
      await expectLater(
        backup.restore(b, Uint8List.fromList([1, 2, 3, 4, 5]), 'parola123'),
        throwsA(isA<BackupException>().having((e) => e.reason, 'r', 'format')),
      );
      final tampered = Uint8List.fromList(file);
      tampered[tampered.length - 1] ^= 1;
      await expectLater(
        backup.restore(b, tampered, 'parola123'),
        throwsA(isA<BackupException>()),
      );
      expect(await b.notes.list(), isEmpty);
    });

    test('password rule', () {
      expect(VaultBackup.isValidPassword('12345'), isFalse);
      expect(VaultBackup.isValidPassword('123456'), isTrue);
    });
  });
}
