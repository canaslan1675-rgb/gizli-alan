import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/vault_event.dart';
import 'vault_session.dart';

/// The vault-only notification list of one space, stored as a single
/// AES-256-GCM encrypted JSON document (`events.gae`). Newest first, capped at
/// [maxEvents]. Real and decoy spaces have separate logs (separate keys).
///
/// Nothing here is ever shown outside the unlocked vault: the app posts no
/// system notifications (no POST_NOTIFICATIONS permission).
class VaultEventLog {
  VaultEventLog(this._enc, this._file);

  final EncryptedFiles _enc;
  final File _file;
  final _uuid = const Uuid();

  static const int maxEvents = 200;

  // Serialises read-modify-write so concurrent adds never drop entries.
  Future<void> _queue = Future.value();

  Future<T> _locked<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<VaultEvent>> list() => _locked(_read);

  Future<int> unreadCount() async =>
      (await list()).where((e) => !e.read).length;

  /// Adds an event. Never throws: a logging failure must not break the
  /// action that triggered it.
  Future<void> add(
    VaultEventType type, [
    Map<String, String> params = const {},
  ]) async {
    try {
      await _locked(() async {
        final events = await _read();
        events.insert(
          0,
          VaultEvent(
            id: _uuid.v4(),
            type: type,
            at: DateTime.now(),
            params: params,
          ),
        );
        if (events.length > maxEvents) {
          events.removeRange(maxEvents, events.length);
        }
        await _save(events);
      });
    } catch (_) {
      // Best effort (e.g. the session was closed mid-write).
    }
  }

  Future<void> markAllRead() => _locked(() async {
    final events = await _read();
    if (events.every((e) => e.read)) return;
    for (final e in events) {
      e.read = true;
    }
    await _save(events);
  });

  Future<void> clear() => _locked(() => _save(const []));

  Future<List<VaultEvent>> _read() async {
    final raw = await _enc.read(_file);
    if (raw == null) return [];
    final events = (jsonDecode(utf8.decode(raw)) as List)
        .cast<Map<String, dynamic>>()
        .map(VaultEvent.fromJson)
        .whereType<VaultEvent>()
        .toList();
    events.sort((a, b) => b.at.compareTo(a.at));
    return events;
  }

  Future<void> _save(List<VaultEvent> events) => _enc.write(
    _file,
    utf8.encode(jsonEncode(events.map((e) => e.toJson()).toList())),
  );
}
