import 'dart:convert';
import 'dart:io';

import 'vault_session.dart';

/// Recently opened İkinci telefon apps (0.6.0 C). Only our own launch
/// records (the vault-home grid), stored encrypted inside the vault space.
/// No usage-stats access: apps opened outside GizliAlan are never seen.
class RecentApps {
  RecentApps(this._enc, this._file);

  final EncryptedFiles _enc;
  final File _file;

  static const int max = 4;

  /// Pure rule: [pkg] moves to the front, duplicates dropped, at most [max].
  static List<String> push(List<String> current, String pkg) =>
      [pkg, ...current.where((p) => p != pkg)].take(max).toList();

  Future<List<String>> list() async {
    try {
      final raw = await _enc.read(_file);
      if (raw == null) return [];
      return (jsonDecode(utf8.decode(raw)) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> record(String pkg) async =>
      _enc.write(_file, utf8.encode(jsonEncode(push(await list(), pkg))));

  Future<void> restore(List<String> previous) async =>
      _enc.write(_file, utf8.encode(jsonEncode(previous.take(max).toList())));

  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}
