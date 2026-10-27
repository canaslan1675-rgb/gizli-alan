import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/models/note.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/services/vault_space.dart';

void main() {
  late Directory tmp;
  late VaultSession s;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_remind');
    s = VaultSession(
      space: VaultSpace.real,
      key: List<int>.generate(32, (i) => i),
      baseDir: tmp,
    );
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('remindAt round-trips through JSON; absent stays null', () {
    final at = DateTime(2026, 11, 2, 9, 30);
    final n = Note(
      id: 'x',
      title: 't',
      body: 'b',
      createdAt: at,
      updatedAt: at,
      remindAt: at,
    );
    expect(Note.fromJson(n.toJson()).remindAt, at);
    n.remindAt = null;
    expect(n.toJson().containsKey('remindAt'), isFalse);
    expect(Note.fromJson(n.toJson()).remindAt, isNull);
  });

  test('due reminders: multiple, oldest first, future ones excluded', () async {
    final now = DateTime(2026, 10, 27, 12);
    final a = await s.notes.create(
      title: 'a',
      remindAt: now.subtract(const Duration(hours: 1)),
    );
    final b = await s.notes.create(
      title: 'b',
      remindAt: now.subtract(const Duration(days: 1)),
    );
    await s.notes.create(
      title: 'c',
      remindAt: now.add(const Duration(hours: 1)),
    );
    await s.notes.create(title: 'd');
    final due = await s.notes.dueReminders(now: now);
    expect(due.map((n) => n.id), [b.id, a.id]);

    await s.notes.setReminder(b.id, null);
    expect((await s.notes.dueReminders(now: now)).map((n) => n.id), [a.id]);
  });

  test('reminder is stored only inside the encrypted notes file', () async {
    await s.notes.create(title: 'secret', remindAt: DateTime(2030));
    final files = tmp
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => latin1.decode(f.readAsBytesSync(), allowInvalid: true));
    for (final raw in files) {
      expect(raw.contains('remindAt'), isFalse);
      expect(raw.contains('secret'), isFalse);
    }
  });

  test('deleting a note drops its reminder (no pop-up from the bin)', () async {
    final n = await s.notes.create(title: 'x', remindAt: DateTime(2020));
    await s.notes.delete(n.id);
    expect(await s.notes.dueReminders(), isEmpty);
    await s.notes.restore(n.id);
    expect(await s.notes.dueReminders(), isEmpty);
  });
}
