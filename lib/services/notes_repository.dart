import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';

/// Notes persisted as a single JSON file in app documents.
/// Notes are NOT AES-encrypted in MVP (hide-only). Files may be encrypted
/// separately via VaultStorage when the setting is on.
class NotesRepository {
  static const _fileName = 'notes.json';
  final _uuid = const Uuid();
  File? _file;

  Future<File> get _notesFile async {
    if (_file != null) return _file!;
    final docs = await getApplicationDocumentsDirectory();
    _file = File(p.join(docs.path, _fileName));
    if (!await _file!.exists()) {
      await _file!.writeAsString(jsonEncode([]));
    }
    return _file!;
  }

  Future<List<Note>> list() async {
    final f = await _notesFile;
    final raw = await f.readAsString();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
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

  Future<void> wipe() async {
    await _save([]);
  }

  Future<void> _save(List<Note> notes) async {
    final f = await _notesFile;
    await f.writeAsString(jsonEncode(notes.map((n) => n.toJson()).toList()));
  }
}
