import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/note.dart';
import 'vault_session.dart';

/// Notes of one vault space, stored as a single AES-256-GCM encrypted JSON
/// document (`notes.gae`). Nothing is written in plaintext.
class NotesRepository {
  NotesRepository(this._enc, this._file)
    : _trashFile = File(
        _file.path.replaceFirst(RegExp(r'\.gae$'), '_trash.gae'),
      );

  final EncryptedFiles _enc;
  final File _file;
  final File _trashFile;
  final _uuid = const Uuid();

  Future<List<Note>> list() => _read(_file);

  Future<List<Note>> _read(File file) async {
    final raw = await _enc.read(file);
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

  /// User delete: moves the note to the recycle bin (0.6.0 G).
  Future<void> delete(String id, {DateTime? now}) async {
    final notes = await list();
    final gone = notes.where((n) => n.id == id).toList();
    notes.removeWhere((n) => n.id == id);
    await _save(notes);
    if (gone.isEmpty) return;
    final trash = await listTrash();
    trash.removeWhere((n) => n.id == id);
    trash.insert(0, gone.first..deletedAt = now ?? DateTime.now());
    await _saveTrash(trash);
  }

  Future<List<Note>> listTrash() async {
    final t = await _read(_trashFile);
    t.sort(
      (a, b) =>
          (b.deletedAt ?? b.updatedAt).compareTo(a.deletedAt ?? a.updatedAt),
    );
    return t;
  }

  Future<void> restore(String id) async {
    final trash = await listTrash();
    final back = trash.where((n) => n.id == id).toList();
    trash.removeWhere((n) => n.id == id);
    await _saveTrash(trash);
    if (back.isEmpty) return;
    final notes = await list();
    notes.removeWhere((n) => n.id == id);
    notes.insert(0, back.first..deletedAt = null);
    await _save(notes);
  }

  Future<void> purge(String id) async {
    final trash = await listTrash();
    trash.removeWhere((n) => n.id == id);
    await _saveTrash(trash);
  }

  Future<int> purgeExpired({
    DateTime? now,
    Duration keep = const Duration(days: 30),
  }) async {
    final limit = (now ?? DateTime.now()).subtract(keep);
    final trash = await listTrash();
    final keepList = trash
        .where((n) => !(n.deletedAt ?? n.updatedAt).isBefore(limit))
        .toList();
    final n = trash.length - keepList.length;
    if (n > 0) await _saveTrash(keepList);
    return n;
  }

  Future<void> emptyTrash() => _saveTrash([]);

  Future<void> _saveTrash(List<Note> notes) => _enc.write(
    _trashFile,
    utf8.encode(jsonEncode(notes.map((n) => n.toJson()).toList())),
  );

  Future<int> count() async => (await list()).length;

  Future<void> wipe() async {
    await _save([]);
    await _saveTrash([]);
  }

  Future<void> _save(List<Note> notes) => _enc.write(
    _file,
    utf8.encode(jsonEncode(notes.map((n) => n.toJson()).toList())),
  );
}
