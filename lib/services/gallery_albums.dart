import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import 'vault_session.dart';
import 'vault_storage.dart';

class Album {
  const Album(this.id, this.name);
  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Album.fromJson(Map<String, dynamic> j) =>
      Album(j['id'] as String, j['name'] as String? ?? '');
}

/// Free: 1 album; Pro: unlimited (0.6.0 H). Albums never change how items
/// are counted, and existing albums are never hidden if Pro lapses.
class AlbumLimit {
  const AlbumLimit._();
  static const int freeAlbums = 1;

  static bool canCreate({required bool pro, required int existing}) =>
      pro || existing < freeAlbums;
}

/// Gallery albums of one space, encrypted in `gallery/albums.gae`. An item's
/// album is stored in its (encrypted) [VaultItem.album].
class GalleryAlbums {
  GalleryAlbums(this._enc, this._file, this._gallery);

  final EncryptedFiles _enc;
  final File _file;
  final VaultStorage _gallery;

  Future<List<Album>> list() async {
    final raw = await _enc.read(_file);
    if (raw == null) return [];
    return (jsonDecode(utf8.decode(raw)) as List)
        .cast<Map<String, dynamic>>()
        .map(Album.fromJson)
        .toList();
  }

  /// Throws [StateError] when the free album limit is reached.
  Future<Album> create(String name, {required bool pro}) async {
    final all = await list();
    if (!AlbumLimit.canCreate(pro: pro, existing: all.length)) {
      throw StateError('album limit');
    }
    final a = Album(const Uuid().v4(), name.trim());
    await _save([...all, a]);
    return a;
  }

  /// Merges albums from a backup (by id; no limit — they already existed).
  Future<void> importAll(List<Album> incoming) async {
    final all = await list();
    final have = all.map((a) => a.id).toSet();
    await _save([...all, ...incoming.where((a) => !have.contains(a.id))]);
  }

  Future<void> rename(String id, String name) async => _save([
    for (final a in await list()) a.id == id ? Album(id, name.trim()) : a,
  ]);

  /// Deletes the album only; its photos stay in the gallery.
  Future<void> delete(String id) async {
    await _save((await list()).where((a) => a.id != id).toList());
    for (final i in await _gallery.list()) {
      if (i.album == id) {
        await _gallery.updateItem(i.copyWith(clearAlbum: true));
      }
    }
  }

  Future<void> move(VaultItem item, String? albumId) => _gallery.updateItem(
    albumId == null
        ? item.copyWith(clearAlbum: true)
        : item.copyWith(album: albumId),
  );

  Future<void> _save(List<Album> all) => _enc.write(
    _file,
    utf8.encode(jsonEncode(all.map((a) => a.toJson()).toList())),
  );
}
