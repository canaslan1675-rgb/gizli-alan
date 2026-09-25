import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/note.dart';
import 'vault_session.dart';

/// One-time migration from the pre-MVP scaffold, which stored notes as
/// plaintext `notes.json` and files in plaintext `vault_files/` under the app
/// documents directory. Content is moved into the encrypted real space and the
/// plaintext copies are deleted. Legacy `.gaenc` files (old optional AES-CBC
/// format, never released) are left untouched.
class LegacyMigration {
  static Future<int> run(VaultSession session, Directory docsDir) async {
    if (session.isDecoy) return 0;
    var moved = 0;

    final notesFile = File(p.join(docsDir.path, 'notes.json'));
    if (await notesFile.exists()) {
      try {
        final list = (jsonDecode(await notesFile.readAsString()) as List)
            .cast<Map<String, dynamic>>()
            .map(Note.fromJson);
        for (final n in list) {
          await session.notes.create(title: n.title, body: n.body);
          moved++;
        }
        await notesFile.delete();
      } catch (_) {
        // Leave the file for a later attempt rather than losing notes.
      }
    }

    final filesDir = Directory(p.join(docsDir.path, 'vault_files'));
    if (await filesDir.exists()) {
      await for (final e in filesDir.list()) {
        if (e is! File || e.path.endsWith('.gaenc')) continue;
        final name = p.basename(e.path).replaceFirst(RegExp(r'^\d+_'), '');
        final target =
            name.toLowerCase().contains(RegExp(r'\.(jpe?g|png|gif|webp|heic)$'))
            ? session.gallery
            : session.files;
        await target.add(name: name, bytes: await e.readAsBytes());
        await e.delete();
        moved++;
      }
    }
    return moved;
  }
}
