import 'dart:convert';
import 'dart:typed_data';

import '../models/note.dart';
import 'bookmarks.dart';
import 'crypto_service.dart';
import 'gallery_albums.dart';
import 'vault_session.dart';
import 'vault_storage.dart';

class BackupException implements Exception {
  BackupException(this.reason);

  /// 'format' (not a GizliAlan backup) or 'password' (wrong password or
  /// damaged file).
  final String reason;
  @override
  String toString() => 'BackupException($reason)';
}

class RestoreResult {
  const RestoreResult(this.photos, this.files, this.notes);
  final int photos;
  final int files;
  final int notes;
  int get total => photos + files + notes;
}

/// Encrypted backup of one vault space into ONE file (0.6.0 L).
///
/// The user picks the file with the system dialog (SAF create/open
/// document); nothing goes to a server, account or the network.
///
/// File format: `"GABK"` || version (1 byte) || PBKDF2 iterations (u32 BE)
/// || salt (16) || AES-256-GCM sealed payload (CryptoService format). The
/// key is PBKDF2-HMAC-SHA256(backup password, salt). Payload: manifest
/// length (u32 BE) || manifest JSON || item payloads back to back.
/// Contents: photos, files, notes, albums, bookmarks (not the recycle bin).
class VaultBackup {
  VaultBackup({CryptoService? crypto, this.iterations = 200000})
    : _crypto = crypto ?? CryptoService();

  final CryptoService _crypto;
  final int iterations;

  static final Uint8List magic = Uint8List.fromList(ascii.encode('GABK'));
  static const int version = 1;
  static const int minPasswordLength = 6;
  static const String fileName = 'gizlialan-yedek.gabk';

  static bool isValidPassword(String p) => p.length >= minPasswordLength;

  Future<Uint8List> create(VaultSession s, String password) async {
    final blobs = BytesBuilder(copy: false);
    var off = 0;
    Future<List<Map<String, dynamic>>> items(VaultStorage st) async {
      final out = <Map<String, dynamic>>[];
      for (final i in await st.list()) {
        final b = await st.read(i);
        out.add({'item': i.toJson(), 'off': off, 'len': b.length});
        blobs.add(b);
        off += b.length;
      }
      return out;
    }

    final manifest = utf8.encode(
      jsonEncode({
        'v': version,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'gallery': await items(s.gallery),
        'files': await items(s.files),
        'notes': [for (final n in await s.notes.list()) n.toJson()],
        'albums': [for (final a in await s.albums.list()) a.toJson()],
        'bookmarks': [for (final b in await s.bookmarks.list()) b.toJson()],
      }),
    );
    final payload = BytesBuilder(copy: false)
      ..add(_u32(manifest.length))
      ..add(manifest)
      ..add(blobs.takeBytes());
    final salt = CryptoService.randomBytes(16);
    final key = await CryptoService.pbkdf2(
      password,
      salt,
      iterations: iterations,
    );
    final sealed = await _crypto.seal(key, payload.takeBytes());
    return (BytesBuilder(copy: false)
          ..add(magic)
          ..addByte(version)
          ..add(_u32(iterations))
          ..add(salt)
          ..add(sealed))
        .takeBytes();
  }

  /// Decrypts [file] and merges it into [s] (items already present, by id,
  /// are skipped — restoring twice does not duplicate anything).
  Future<RestoreResult> restore(
    VaultSession s,
    Uint8List file,
    String password,
  ) async {
    const head = 4 + 1 + 4 + 16;
    if (file.length < head || !_startsWith(file, magic) || file[4] != version) {
      throw BackupException('format');
    }
    final iters = ByteData.sublistView(file, 5, 9).getUint32(0);
    if (iters < 1000 || iters > 5000000) throw BackupException('format');
    final salt = Uint8List.sublistView(file, 9, head);
    final key = await CryptoService.pbkdf2(password, salt, iterations: iters);
    Uint8List payload;
    try {
      payload = await _crypto.open(key, Uint8List.sublistView(file, head));
    } catch (_) {
      throw BackupException('password');
    }
    try {
      final mlen = ByteData.sublistView(payload, 0, 4).getUint32(0);
      final m =
          jsonDecode(utf8.decode(Uint8List.sublistView(payload, 4, 4 + mlen)))
              as Map<String, dynamic>;
      final base = 4 + mlen;
      Future<int> put(VaultStorage st, List list) async {
        var n = 0;
        for (final e in list.cast<Map<String, dynamic>>()) {
          final item = VaultItem.fromJson(
            (e['item'] as Map).cast<String, dynamic>(),
          );
          final o = base + (e['off'] as num).toInt();
          final bytes = Uint8List.fromList(
            Uint8List.sublistView(payload, o, o + (e['len'] as num).toInt()),
          );
          if (await st.importItem(item, bytes)) n++;
        }
        return n;
      }

      final photos = await put(s.gallery, m['gallery'] as List? ?? []);
      final files = await put(s.files, m['files'] as List? ?? []);
      final notes = await s.notes.importNotes([
        for (final j in (m['notes'] as List? ?? []).cast<Map>())
          Note.fromJson(j.cast<String, dynamic>()),
      ]);
      await s.albums.importAll([
        for (final j in (m['albums'] as List? ?? []).cast<Map>())
          Album.fromJson(j.cast<String, dynamic>()),
      ]);
      await s.bookmarks.importAll([
        for (final j in (m['bookmarks'] as List? ?? []).cast<Map>())
          Bookmark.fromJson(j.cast<String, dynamic>()),
      ]);
      return RestoreResult(photos, files, notes);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw BackupException('format');
    }
  }

  static Uint8List _u32(int v) =>
      (ByteData(4)..setUint32(0, v)).buffer.asUint8List();

  static bool _startsWith(List<int> d, List<int> p) {
    for (var i = 0; i < p.length; i++) {
      if (d[i] != p[i]) return false;
    }
    return true;
  }
}
