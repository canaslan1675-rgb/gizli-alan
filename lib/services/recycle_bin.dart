import 'vault_session.dart';
import 'vault_storage.dart';

enum TrashKind { photo, file, note }

/// One entry of the recycle bin (0.6.0 G), across gallery, files and notes.
class TrashEntry {
  TrashEntry({
    required this.kind,
    required this.id,
    required this.name,
    required this.deletedAt,
    this.item,
  });

  final TrashKind kind;
  final String id;
  final String name;
  final DateTime deletedAt;

  /// Gallery/files metadata (null for notes).
  final VaultItem? item;

  /// Whole days left before the automatic purge (never < 0).
  int daysLeft(DateTime now) {
    final end = deletedAt.add(VaultStorage.trashKeep);
    final d = end.difference(now).inHours / 24;
    return d <= 0 ? 0 : d.ceil();
  }
}

/// Recycle bin of one vault space: deleted photos, files and notes stay
/// encrypted for [VaultStorage.trashKeep] (30 days), then are purged. Free.
class RecycleBin {
  RecycleBin(this.session);
  final VaultSession session;

  Future<List<TrashEntry>> entries() async {
    final out = <TrashEntry>[
      for (final i in await session.gallery.listTrash())
        TrashEntry(
          kind: TrashKind.photo,
          id: i.id,
          name: i.name,
          deletedAt: i.deletedAt ?? i.addedAt,
          item: i,
        ),
      for (final i in await session.files.listTrash())
        TrashEntry(
          kind: TrashKind.file,
          id: i.id,
          name: i.name,
          deletedAt: i.deletedAt ?? i.addedAt,
          item: i,
        ),
      for (final n in await session.notes.listTrash())
        TrashEntry(
          kind: TrashKind.note,
          id: n.id,
          name: n.title.trim().isEmpty
              ? n.body.split('\n').first.trim()
              : n.title.trim(),
          deletedAt: n.deletedAt ?? n.updatedAt,
        ),
    ];
    out.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return out;
  }

  VaultStorage? _store(TrashKind k) => switch (k) {
    TrashKind.photo => session.gallery,
    TrashKind.file => session.files,
    TrashKind.note => null,
  };

  Future<void> restore(TrashEntry e) async {
    final s = _store(e.kind);
    if (s != null) {
      await s.restore(e.item!);
    } else {
      await session.notes.restore(e.id);
    }
  }

  Future<void> purge(TrashEntry e) async {
    final s = _store(e.kind);
    if (s != null) {
      await s.purge(e.item!);
    } else {
      await session.notes.purge(e.id);
    }
  }

  /// Removes everything older than 30 days. Called on every vault entry.
  Future<int> purgeExpired({DateTime? now}) async =>
      await session.gallery.purgeExpired(now: now) +
      await session.files.purgeExpired(now: now) +
      await session.notes.purgeExpired(now: now);

  Future<void> emptyAll() async {
    await session.gallery.emptyTrash();
    await session.files.emptyTrash();
    await session.notes.emptyTrash();
  }
}
