import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'crypto_service.dart';
import 'notes_repository.dart';
import 'vault_space.dart';
import 'vault_storage.dart';

/// Encrypted file helpers bound to one space's data key.
class EncryptedFiles {
  EncryptedFiles(this._key, this._crypto);

  final Uint8List _key;
  final CryptoService _crypto;

  Future<void> write(File file, List<int> plain) async {
    final sealed = await _crypto.seal(_key, plain);
    await file.parent.create(recursive: true);
    // Write to a temp file then rename, so a crash never leaves half a file.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(sealed, flush: true);
    await tmp.rename(file.path);
  }

  Future<Uint8List?> read(File file) async {
    if (!await file.exists()) return null;
    return _crypto.open(_key, await file.readAsBytes());
  }

  void wipeKeyFromMemory() => _key.fillRange(0, _key.length, 0);
}

/// Everything available while a vault space is unlocked. Dropped on lock.
///
/// Layout: `<base>/spaces/<space>/notes.gae`, `.../gallery/`, `.../files/`.
class VaultSession {
  VaultSession({
    required this.space,
    required List<int> key,
    required Directory baseDir,
    CryptoService? crypto,
  }) : dir = Directory(p.join(baseDir.path, 'spaces', space.name)),
       _files = EncryptedFiles(
         Uint8List.fromList(key),
         crypto ?? CryptoService(),
       ) {
    notes = NotesRepository(_files, File(p.join(dir.path, 'notes.gae')));
    gallery = VaultStorage(_files, Directory(p.join(dir.path, 'gallery')));
    files = VaultStorage(_files, Directory(p.join(dir.path, 'files')));
  }

  final VaultSpace space;
  final Directory dir;
  final EncryptedFiles _files;

  late final NotesRepository notes;
  late final VaultStorage gallery;
  late final VaultStorage files;

  bool get isDecoy => space == VaultSpace.decoy;

  /// Best-effort: zero our copy of the key and drop caches.
  void close() {
    gallery.clearCache();
    files.clearCache();
    _files.wipeKeyFromMemory();
  }

  /// Deletes all content of this space.
  Future<void> wipe() async {
    gallery.clearCache();
    files.clearCache();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<void> wipeSpace(Directory baseDir, VaultSpace space) async {
    final d = Directory(p.join(baseDir.path, 'spaces', space.name));
    if (await d.exists()) await d.delete(recursive: true);
  }
}
