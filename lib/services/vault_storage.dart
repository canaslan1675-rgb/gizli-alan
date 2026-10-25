import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'vault_events.dart';
import 'vault_session.dart';

/// Metadata of one encrypted item (kept inside the encrypted index, so file
/// names and types are not visible on disk either).
class VaultItem {
  VaultItem({
    required this.id,
    required this.name,
    required this.mime,
    required this.size,
    required this.addedAt,
    this.deletedAt,
    this.album,
  });

  final String id;
  final String name;
  final String mime;
  final int size;
  final DateTime addedAt;

  /// Set while the item is in the recycle bin (0.6.0 G).
  final DateTime? deletedAt;

  /// Album id (gallery, 0.6.0 H); null = not in an album.
  final String? album;

  VaultItem copyWith({
    DateTime? deletedAt,
    bool clearDeleted = false,
    String? album,
    bool clearAlbum = false,
  }) => VaultItem(
    id: id,
    name: name,
    mime: mime,
    size: size,
    addedAt: addedAt,
    deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
    album: clearAlbum ? null : (album ?? this.album),
  );

  bool get isVideo => mime.startsWith('video/');

  bool get isImage => mime.startsWith('image/');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mime': mime,
    'size': size,
    'addedAt': addedAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (album != null) 'album': album,
  };

  factory VaultItem.fromJson(Map<String, dynamic> j) => VaultItem(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'file',
    mime: j['mime'] as String? ?? 'application/octet-stream',
    size: (j['size'] as num?)?.toInt() ?? 0,
    addedAt:
        DateTime.tryParse(j['addedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    deletedAt: DateTime.tryParse(j['deletedAt'] as String? ?? ''),
    album: j['album'] as String?,
  );
}

/// An encrypted collection (gallery or files) inside a vault space.
///
/// On disk: `index.gae` (encrypted JSON list of [VaultItem]) and one
/// `<uuid>.gae` per item — random names, AES-256-GCM encrypted payloads.
class VaultStorage {
  VaultStorage(this._enc, this.dir, {this.events});

  final EncryptedFiles _enc;
  final Directory dir;

  /// The space's notification list; UI actions (import/export/delete) log to
  /// it. The storage itself does not log.
  final VaultEventLog? events;
  final _uuid = const Uuid();

  /// Largest single import we accept (whole file is held in memory).
  static const int maxItemBytes = 100 * 1024 * 1024;

  // Small LRU of decrypted payloads so the grid does not re-decrypt on scroll.
  final _cache = <String, Uint8List>{}; // insertion-ordered (LinkedHashMap)
  static const int _cacheBudget = 48 * 1024 * 1024;
  int _cacheBytes = 0;

  File get _index => File(p.join(dir.path, 'index.gae'));
  File get _trashIndex => File(p.join(dir.path, 'trash.gae'));
  File _blob(String id) => File(p.join(dir.path, '$id.gae'));

  Future<List<VaultItem>> list() => _readIndex(_index);

  Future<List<VaultItem>> _readIndex(File index) async {
    final raw = await _enc.read(index);
    if (raw == null) return [];
    final items = (jsonDecode(utf8.decode(raw)) as List)
        .cast<Map<String, dynamic>>()
        .map(VaultItem.fromJson)
        .toList();
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  Future<VaultItem> add({
    required String name,
    required Uint8List bytes,
    String? mime,
  }) async {
    if (bytes.length > maxItemBytes) {
      throw ArgumentError('File too large');
    }
    final item = VaultItem(
      id: _uuid.v4(),
      name: p.basename(name).isEmpty ? 'file' : p.basename(name),
      mime: mime ?? guessMime(name),
      size: bytes.length,
      addedAt: DateTime.now(),
    );
    await _enc.write(_blob(item.id), bytes);
    final items = await list();
    items.insert(0, item);
    await _saveIndex(items);
    return item;
  }

  Future<Uint8List> read(VaultItem item) async {
    final hit = _cache.remove(item.id);
    if (hit != null) {
      _cache[item.id] = hit; // refresh LRU position
      return hit;
    }
    final data = await _enc.read(_blob(item.id));
    if (data == null) throw FileSystemException('missing item', item.id);
    _remember(item.id, data);
    return data;
  }

  /// User delete: moves the item to the recycle bin (0.6.0 G). The payload
  /// stays encrypted on disk until [purge] / [purgeExpired] / [emptyTrash].
  Future<void> delete(VaultItem item, {DateTime? now}) async {
    _forget(item.id);
    final items = await list();
    items.removeWhere((i) => i.id == item.id);
    await _saveIndex(items);
    final trash = await listTrash();
    trash.removeWhere((i) => i.id == item.id);
    trash.insert(0, item.copyWith(deletedAt: now ?? DateTime.now()));
    await _saveTrash(trash);
  }

  /// Items in the recycle bin, newest deletion first.
  Future<List<VaultItem>> listTrash() async {
    final t = await _readIndex(_trashIndex);
    t.sort(
      (a, b) => (b.deletedAt ?? b.addedAt).compareTo(a.deletedAt ?? a.addedAt),
    );
    return t;
  }

  /// Puts a recycle-bin item back.
  Future<void> restore(VaultItem item) async {
    final trash = await listTrash();
    trash.removeWhere((i) => i.id == item.id);
    await _saveTrash(trash);
    final items = await list();
    items.removeWhere((i) => i.id == item.id);
    items.insert(0, item.copyWith(clearDeleted: true));
    await _saveIndex(items);
  }

  /// Deletes a recycle-bin item for good (payload file removed).
  Future<void> purge(VaultItem item) async {
    _forget(item.id);
    final f = _blob(item.id);
    if (await f.exists()) await f.delete();
    final trash = await listTrash();
    trash.removeWhere((i) => i.id == item.id);
    await _saveTrash(trash);
  }

  /// Purges recycle-bin items deleted more than [keep] ago. Returns how many.
  Future<int> purgeExpired({DateTime? now, Duration keep = trashKeep}) async {
    final limit = (now ?? DateTime.now()).subtract(keep);
    var n = 0;
    for (final i in await listTrash()) {
      if ((i.deletedAt ?? i.addedAt).isBefore(limit)) {
        await purge(i);
        n++;
      }
    }
    return n;
  }

  Future<void> emptyTrash() async {
    for (final i in await listTrash()) {
      await purge(i);
    }
  }

  /// How long deleted items are kept in the recycle bin.
  static const Duration trashKeep = Duration(days: 30);

  /// Replaces one item's metadata (e.g. album) in the index.
  Future<void> updateItem(VaultItem item) async {
    final items = await list();
    final i = items.indexWhere((x) => x.id == item.id);
    if (i < 0) return;
    items[i] = item;
    await _saveIndex(items);
  }

  Future<int> count() async => (await list()).length;

  Future<void> wipeAll() async {
    clearCache();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  void clearCache() {
    _cache.clear();
    _cacheBytes = 0;
  }

  Future<void> _saveIndex(List<VaultItem> items) => _enc.write(
    _index,
    utf8.encode(jsonEncode(items.map((i) => i.toJson()).toList())),
  );

  Future<void> _saveTrash(List<VaultItem> items) => _enc.write(
    _trashIndex,
    utf8.encode(jsonEncode(items.map((i) => i.toJson()).toList())),
  );

  void _remember(String id, Uint8List data) {
    if (data.length > _cacheBudget ~/ 4) return;
    _cache[id] = data;
    _cacheBytes += data.length;
    while (_cacheBytes > _cacheBudget && _cache.isNotEmpty) {
      _forget(_cache.keys.first);
    }
  }

  void _forget(String id) {
    final d = _cache.remove(id);
    if (d != null) _cacheBytes -= d.length;
  }

  static String guessMime(String name) {
    switch (p.extension(name).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.bmp':
        return 'image/bmp';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.mp4':
      case '.m4v':
        return 'video/mp4';
      case '.3gp':
        return 'video/3gpp';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      case '.mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
