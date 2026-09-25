import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/crypto_service.dart';
import 'package:gizlialan/services/legacy_migration.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  VaultSession open(VaultSpace space, List<int> key) =>
      VaultSession(space: space, key: key, baseDir: tmp);

  Future<List<File>> allFiles() async =>
      tmp.list(recursive: true).where((e) => e is File).cast<File>().toList();

  test('gallery: add, list, read, delete; nothing plaintext on disk', () async {
    final key = CryptoService.newKey();
    final s = open(VaultSpace.real, key);
    final photo = Uint8List.fromList(utf8.encode('JPEG-PRIVATE-PHOTO-BYTES'));
    final item = await s.gallery.add(name: 'holiday.jpg', bytes: photo);
    expect(item.mime, 'image/jpeg');

    final list = await s.gallery.list();
    expect(list.single.name, 'holiday.jpg');
    expect(await s.gallery.read(list.single), photo);

    for (final f in await allFiles()) {
      final raw = await f.readAsBytes();
      expect(CryptoService.isSealed(raw), isTrue, reason: f.path);
      final text = latin1.decode(raw, allowInvalid: true);
      expect(text.contains('PRIVATE'), isFalse);
      expect(text.contains('holiday'), isFalse);
      expect(f.path.contains('holiday'), isFalse);
    }

    // A fresh session (no cache) reads it back from disk.
    final s2 = open(VaultSpace.real, key);
    expect(await s2.gallery.read((await s2.gallery.list()).single), photo);

    await s2.gallery.delete(list.single);
    expect(await s2.gallery.list(), isEmpty);
    expect(
      (await allFiles()).where((f) => !f.path.endsWith('index.gae')),
      isEmpty,
    );
  });

  test('notes: CRUD round-trip, encrypted at rest', () async {
    final key = CryptoService.newKey();
    final s = open(VaultSpace.real, key);
    final n = await s.notes.create(title: 'Pasaport', body: 'no: X123');
    n.body = 'no: Y456';
    await s.notes.update(n);

    final again = open(VaultSpace.real, key);
    final notes = await again.notes.list();
    expect(notes.single.title, 'Pasaport');
    expect(notes.single.body, 'no: Y456');

    final raw = await File('${s.dir.path}/notes.gae').readAsBytes();
    expect(
      latin1.decode(raw, allowInvalid: true).contains('Pasaport'),
      isFalse,
    );

    await again.notes.delete(n.id);
    expect(await again.notes.list(), isEmpty);
  });

  test('decoy space is separate and cannot read the real space', () async {
    final realKey = CryptoService.newKey();
    final decoyKey = CryptoService.newKey();
    final real = open(VaultSpace.real, realKey);
    await real.notes.create(title: 'real secret');

    final decoy = open(VaultSpace.decoy, decoyKey);
    expect(await decoy.notes.list(), isEmpty);
    expect(await decoy.gallery.list(), isEmpty);

    // Even pointing the decoy key at the real files fails authentication.
    final wrong = open(VaultSpace.real, decoyKey);
    expect(() => wrong.notes.list(), throwsA(isA<VaultCryptoException>()));
  });

  test('wipeSpace removes only that space', () async {
    final real = open(VaultSpace.real, CryptoService.newKey());
    final decoy = open(VaultSpace.decoy, CryptoService.newKey());
    await real.notes.create(title: 'a');
    await decoy.notes.create(title: 'b');
    await VaultSession.wipeSpace(tmp, VaultSpace.decoy);
    expect(await decoy.dir.exists(), isFalse);
    expect(await real.dir.exists(), isTrue);
  });

  test('legacy plaintext scaffold data is migrated and deleted', () async {
    final docs = await Directory('${tmp.path}/docs').create();
    await File('${docs.path}/notes.json').writeAsString(
      jsonEncode([
        {
          'id': 'x',
          'title': 'old',
          'body': 'plain',
          'createdAt': DateTime(2026).toIso8601String(),
          'updatedAt': DateTime(2026).toIso8601String(),
        },
      ]),
    );
    final vf = await Directory('${docs.path}/vault_files').create();
    await File('${vf.path}/123_pic.png').writeAsBytes([1, 2, 3]);
    await File('${vf.path}/456_doc.pdf').writeAsBytes([4, 5]);

    final s = open(VaultSpace.real, CryptoService.newKey());
    final moved = await LegacyMigration.run(s, docs);
    expect(moved, 3);
    expect((await s.notes.list()).single.title, 'old');
    expect((await s.gallery.list()).single.name, 'pic.png');
    expect((await s.files.list()).single.name, 'doc.pdf');
    expect(await File('${docs.path}/notes.json').exists(), isFalse);
    expect(await vf.list().isEmpty, isTrue);
  });
}
