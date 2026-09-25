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
  });

  final String id;
  final String name;
  final String mime;
  final int size;
  final DateTime addedAt;

  bool get isImage => mime.startsWith('image/');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mime': mime,
    'size': size,
    'addedAt': addedAt.toIso8601String(),
  };

  factory VaultItem.fromJson(Map<String, dynamic> j) => VaultItem(
    id: j['id'] as String,
    name: j['name'] as String? ?? 'file',
    mime: j['mime'] as String? ?? 'application/octet-stream',
    size: (j['size'] as num?)?.toInt() ?? 0,
    addedAt:
        DateTime.tryParse(j['addedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
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
  File _blob(String id) => File(p.join(dir.path, '$id.gae'));

  Future<List<VaultItem>> list() async {
    final raw = await _enc.read(_index);
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

  Future<void> delete(VaultItem item) async {
    _forget(item.id);
    final f = _blob(item.id);
    if (await f.exists()) await f.delete();
    final items = await list();
    items.removeWhere((i) => i.id == item.id);
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
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
