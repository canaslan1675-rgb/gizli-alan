import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'crypto_service.dart';
import 'notes_repository.dart';
import 'vault_events.dart';
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
/// Layout: `<base>/spaces/<space>/notes.gae`, `events.gae`, `.../gallery/`,
/// `.../files/`.
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
    events = VaultEventLog(_files, File(p.join(dir.path, 'events.gae')));
    gallery = VaultStorage(
      _files,
      Directory(p.join(dir.path, 'gallery')),
      events: events,
    );
    files = VaultStorage(
      _files,
      Directory(p.join(dir.path, 'files')),
      events: events,
    );
  }

  final VaultSpace space;
  final Directory dir;
  final EncryptedFiles _files;

  late final NotesRepository notes;

  /// Vault-only notification list of this space.
  late final VaultEventLog events;
  late final VaultStorage gallery;
  late final VaultStorage files;

  bool get isDecoy => space == VaultSpace.decoy;

  // ------------------------------------------------ vault home background

  /// Which gallery photo is this space's vault-home background. Stored
  /// encrypted inside the space (`home_background.gae`), so neither the
  /// choice nor the photo ever leaves the vault; the photo is only decrypted
  /// into memory while unlocked. Each space (real / decoy) has its own.
  File get _homeBackground => File(p.join(dir.path, 'home_background.gae'));

  Future<String?> homeBackgroundId() async {
    try {
      final raw = await _files.read(_homeBackground);
      if (raw == null) return null;
      final id = utf8.decode(raw).trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Sets (or with null removes) the background photo.
  Future<void> setHomeBackgroundId(String? id) async {
    if (id == null) {
      if (await _homeBackground.exists()) await _homeBackground.delete();
      return;
    }
    await _files.write(_homeBackground, utf8.encode(id));
  }

  /// Decrypted bytes of the background photo, or null (none set, or the
  /// photo was deleted from the gallery — then the choice is cleared).
  Future<Uint8List?> homeBackgroundBytes() async {
    final id = await homeBackgroundId();
    if (id == null) return null;
    final items = await gallery.list();
    final matches = items.where((i) => i.id == id && i.isImage);
    if (matches.isEmpty) {
      await setHomeBackgroundId(null);
      return null;
    }
    try {
      return await gallery.read(matches.first);
    } catch (_) {
      return null;
    }
  }

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
