import 'dart:convert';
import 'dart:io';

import 'vault_session.dart';

class Bookmark {
  const Bookmark(this.title, this.url);
  final String title;
  final String url;

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
  factory Bookmark.fromJson(Map<String, dynamic> j) =>
      Bookmark(j['title'] as String? ?? '', j['url'] as String? ?? '');
}

/// Free: [freeBookmarks]; Pro: unlimited (0.6.0 K). Bookmarks above the
/// limit (e.g. after Pro lapses) are kept and usable; only adding stops.
class BookmarkLimit {
  const BookmarkLimit._();
  static const int freeBookmarks = 5;

  static bool canAdd({required bool pro, required int existing}) =>
      pro || existing < freeBookmarks;
}

/// In-vault browser bookmarks, encrypted in `bookmarks.gae` of the space.
/// Only title + address — never passwords, form data or history (history
/// is still cleared on lock).
class Bookmarks {
  Bookmarks(this._enc, this._file);

  final EncryptedFiles _enc;
  final File _file;

  Future<List<Bookmark>> list() async {
    final raw = await _enc.read(_file);
    if (raw == null) return [];
    return (jsonDecode(utf8.decode(raw)) as List)
        .cast<Map<String, dynamic>>()
        .map(Bookmark.fromJson)
        .toList();
  }

  Future<bool> contains(String url) async =>
      (await list()).any((b) => b.url == url);

  /// Adds (or retitles an existing) bookmark. Throws [StateError] when the
  /// free limit is reached.
  Future<void> add(String title, String url, {required bool pro}) async {
    final all = await list();
    final i = all.indexWhere((b) => b.url == url);
    final t = title.trim().isEmpty ? url : title.trim();
    if (i >= 0) {
      all[i] = Bookmark(t, url);
    } else {
      if (!BookmarkLimit.canAdd(pro: pro, existing: all.length)) {
        throw StateError('bookmark limit');
      }
      all.add(Bookmark(t, url));
    }
    await _save(all);
  }

  /// Merges bookmarks from a backup (by url; no limit — they already existed).
  Future<void> importAll(List<Bookmark> incoming) async {
    final all = await list();
    final have = all.map((b) => b.url).toSet();
    await _save([...all, ...incoming.where((b) => !have.contains(b.url))]);
  }

  Future<void> remove(String url) async =>
      _save((await list()).where((b) => b.url != url).toList());

  Future<void> _save(List<Bookmark> all) => _enc.write(
    _file,
    utf8.encode(jsonEncode(all.map((b) => b.toJson()).toList())),
  );
}
