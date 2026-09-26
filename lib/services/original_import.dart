import 'dart:io';

import 'package:flutter/services.dart';

/// One item picked through the system document picker (ImportChannel.kt):
/// [uri] is the original, [path] a plaintext cache copy to import & delete.
class ImportSource {
  const ImportSource({
    required this.uri,
    required this.path,
    required this.name,
    this.mime,
  });

  final String uri;
  final String path;
  final String name;
  final String? mime;
}

/// Outcome of deleting originals.
class DeleteOutcome {
  const DeleteOutcome(this.deleted, this.failed, {this.declined = false});
  final int deleted;
  final int failed;
  final bool declined;
}

/// "Delete original after import" (Pro, #37). The vault copy is written and
/// verified (read back + decrypted) BEFORE any original is touched; only the
/// URIs of verified imports are ever passed to [deleteOriginals].
class OriginalImport {
  const OriginalImport._();

  static const MethodChannel _channel = MethodChannel('gizlialan/import');

  static Future<List<ImportSource>> pick({required bool images}) async {
    final raw = await _channel.invokeListMethod<Object?>('pick', {
      'images': images,
    });
    return [
      for (final m in raw ?? const <Object?>[])
        if (m is Map)
          ImportSource(
            uri: m['uri'] as String,
            path: m['path'] as String,
            name: (m['name'] as String?) ?? 'file',
            mime: m['mime'] as String?,
          ),
    ];
  }

  /// Imports every source with [store] (returns the stored id) and [verify]
  /// (true when the stored copy reads back intact). Returns the URIs that are
  /// safe to delete. Cache copies are always removed. Never throws per item.
  static Future<List<String>> importAll(
    List<ImportSource> sources, {
    required Future<Object> Function(ImportSource s, Uint8List bytes) store,
    required Future<bool> Function(Object stored, Uint8List bytes) verify,
    int maxBytes = 1 << 62,
    void Function(ImportSource s)? onTooBig,
  }) async {
    final safe = <String>[];
    for (final s in sources) {
      final f = File(s.path);
      try {
        final bytes = await f.readAsBytes();
        if (bytes.length > maxBytes) {
          onTooBig?.call(s);
          continue;
        }
        final stored = await store(s, bytes);
        if (await verify(stored, bytes)) safe.add(s.uri);
      } catch (_) {
        // Not stored → original is kept.
      } finally {
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
    return safe;
  }

  static Future<DeleteOutcome> deleteOriginals(List<String> uris) async {
    if (uris.isEmpty) return const DeleteOutcome(0, 0);
    try {
      final m = await _channel.invokeMapMethod<String, Object?>(
        'deleteOriginals',
        {'uris': uris},
      );
      return DeleteOutcome(
        (m?['deleted'] as int?) ?? 0,
        (m?['failed'] as int?) ?? uris.length,
        declined: (m?['declined'] as bool?) ?? false,
      );
    } catch (_) {
      return DeleteOutcome(0, uris.length);
    }
  }
}
