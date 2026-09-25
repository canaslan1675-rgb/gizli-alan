import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/note.dart';
import 'vault_session.dart';

/// Notes of one vault space, stored as a single AES-256-GCM encrypted JSON
/// document (`notes.gae`). Nothing is written in plaintext.
class NotesRepository {
  NotesRepository(this._enc, this._file);

  final EncryptedFiles _enc;
  final File _file;
  final _uuid = const Uuid();

  Future<List<Note>> list() async {
    final raw = await _enc.read(_file);
    if (raw == null) return [];
    final list = (jsonDecode(utf8.decode(raw)) as List)
        .cast<Map<String, dynamic>>();
    final notes = list.map(Note.fromJson).toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<Note> create({String title = '', String body = ''}) async {
    final notes = await list();
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    notes.insert(0, note);
    await _save(notes);
    return note;
  }

  Future<void> update(Note note) async {
    final notes = await list();
    final i = notes.indexWhere((n) => n.id == note.id);
    if (i < 0) return;
    note.updatedAt = DateTime.now();
    notes[i] = note;
    await _save(notes);
  }

  Future<void> delete(String id) async {
    final notes = await list();
    notes.removeWhere((n) => n.id == id);
    await _save(notes);
  }

  Future<int> count() async => (await list()).length;

  Future<void> wipe() => _save([]);

  Future<void> _save(List<Note> notes) => _enc.write(
    _file,
    utf8.encode(jsonEncode(notes.map((n) => n.toJson()).toList())),
  );
}
