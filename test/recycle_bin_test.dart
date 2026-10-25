import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/recycle_bin.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:gizlialan/widgets/pro_gate.dart';

void main() {
  late Directory tmp;
  late VaultSession s;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_trash');
    s = VaultSession(
      space: VaultSpace.real,
      key: List<int>.generate(32, (i) => i),
      baseDir: tmp,
    );
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('recycle bin (0.6.0 G)', () {
    test(
      'delete moves to the bin (still encrypted), restore brings back',
      () async {
        final a = await s.gallery.add(
          name: 'a.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
        );
        final n = await s.notes.create(title: 'n');
        await s.gallery.delete(a);
        await s.notes.delete(n.id);
        expect(await s.gallery.count(), 0);
        expect(await ItemLimit.storedIn(s), 0, reason: 'bin does not count');
        final bin = RecycleBin(s);
        final e = await bin.entries();
        expect(
          e.map((x) => x.kind),
          containsAll([TrashKind.photo, TrashKind.note]),
        );
        // Payload file kept, never plaintext.
        final blob = File('${s.gallery.dir.path}/${a.id}.gae');
        expect(blob.existsSync(), isTrue);
        expect(blob.readAsBytesSync().length > 3, isTrue);
        for (final x in e) {
          await bin.restore(x);
        }
        expect(await s.gallery.count(), 1);
        expect(await s.notes.count(), 1);
        expect(await s.gallery.read((await s.gallery.list()).first), [1, 2, 3]);
        expect(await bin.entries(), isEmpty);
      },
    );

    test('purgeExpired removes only items older than 30 days', () async {
      final now = DateTime(2026, 10, 25, 12);
      final old = await s.files.add(name: 'old.pdf', bytes: Uint8List(4));
      final fresh = await s.files.add(name: 'new.pdf', bytes: Uint8List(4));
      final n = await s.notes.create(title: 'old note');
      await s.files.delete(old, now: now.subtract(const Duration(days: 31)));
      await s.files.delete(fresh, now: now.subtract(const Duration(days: 29)));
      await s.notes.delete(
        n.id,
        now: now.subtract(const Duration(days: 30, hours: 1)),
      );
      final bin = RecycleBin(s);
      expect(await bin.purgeExpired(now: now), 2);
      final left = await bin.entries();
      expect(left.single.name, 'new.pdf');
      expect(left.single.daysLeft(now), 1);
      expect(File('${s.files.dir.path}/${old.id}.gae').existsSync(), isFalse);
      expect(File('${s.files.dir.path}/${fresh.id}.gae').existsSync(), isTrue);
    });

    test('purge and empty delete for good', () async {
      final a = await s.gallery.add(name: 'a.jpg', bytes: Uint8List(2));
      final b = await s.gallery.add(name: 'b.jpg', bytes: Uint8List(2));
      await s.gallery.delete(a);
      await s.gallery.delete(b);
      final bin = RecycleBin(s);
      await bin.purge((await bin.entries()).first);
      expect((await bin.entries()).length, 1);
      await bin.emptyAll();
      expect(await bin.entries(), isEmpty);
      expect(File('${s.gallery.dir.path}/${a.id}.gae').existsSync(), isFalse);
    });
  });
}
