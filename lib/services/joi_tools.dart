import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'vault_session.dart';

/// One persisted Joi chat message (0.6.2). Stored only inside the vault
/// space, encrypted ([JoiChatStore]); never sent anywhere as a whole.
class JoiChatMsg {
  const JoiChatMsg({
    required this.fromUser,
    required this.text,
    this.online,
    this.private = false,
    this.noteId,
  });

  final bool fromUser;
  final String text;

  /// AI answers: true = online, false = on device, null = not a model answer.
  final bool? online;

  /// Derived from the user's notes (search hits, summaries, ask-my-notes):
  /// NEVER used as online context.
  final bool private;

  /// A note Joi created ("open note" button).
  final String? noteId;

  Map<String, dynamic> toJson() => {
    'u': fromUser,
    't': text,
    if (online != null) 'o': online,
    if (private) 'p': true,
    if (noteId != null) 'n': noteId,
  };

  static JoiChatMsg fromJson(Map<String, dynamic> j) => JoiChatMsg(
    fromUser: j['u'] == true,
    text: (j['t'] ?? '').toString(),
    online: j['o'] as bool?,
    private: j['p'] == true,
    noteId: j['n'] as String?,
  );
}

/// Encrypted chat history of one vault space (`joi_chat.gae`).
class JoiChatStore {
  JoiChatStore(this._files, this._file);
  final EncryptedFiles _files;
  final File _file;

  static const int maxStored = 200;

  Future<List<JoiChatMsg>> load() async {
    try {
      final raw = await _files.read(_file);
      if (raw == null) return [];
      return (jsonDecode(utf8.decode(raw)) as List)
          .cast<Map<String, dynamic>>()
          .map(JoiChatMsg.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<JoiChatMsg> msgs) async {
    final keep = msgs.length > maxStored
        ? msgs.sublist(msgs.length - maxStored)
        : msgs;
    await _files.write(
      _file,
      utf8.encode(jsonEncode(keep.map((m) => m.toJson()).toList())),
    );
  }

  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
  }
}

/// Online context: last [max] non-private, non-empty turns as
/// `{role: user|model, text}`. Note-derived messages are excluded.
List<Map<String, String>> joiOnlineHistory(
  List<JoiChatMsg> msgs, {
  int max = 20,
}) {
  final ok = msgs
      .where((m) => !m.private && m.text.trim().isNotEmpty)
      .where((m) => m.fromUser || m.online != null)
      .toList();
  final tail = ok.length > max ? ok.sublist(ok.length - max) : ok;
  return [
    for (final m in tail)
      {
        'role': m.fromUser ? 'user' : 'model',
        'text': m.text.length > 600 ? m.text.substring(0, 600) : m.text,
      },
  ];
}

/// What the user asked Joi to do.
sealed class JoiIntent {
  const JoiIntent();

  /// Simple TR/EN keyword detection (fast, offline, predictable).
  static JoiIntent? parse(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    final low = s.toLowerCase();

    // ---- write to notes
    final noteRe = RegExp(
      r"(not defter[iı]me|notlar[ıi]ma|not olarak|yeni (?:bir )?not|to my notes|in my notes|a note|note:)",
      unicode: true,
    );
    final writeRe = RegExp(
      r"(?<![\p{L}])(yaz|ekle|kaydet|özetle|oluştur|hazırla|write|add|save|create|make)",
      unicode: true,
    );
    if (noteRe.hasMatch(low) && writeRe.hasMatch(low)) {
      final colon = s.indexOf(':');
      if (colon > 0 && colon < s.length - 1) {
        final head = low.substring(0, colon);
        if (RegExp(r"(şunu|sunu|bunu|this|following)").hasMatch(head) ||
            noteRe.hasMatch(head)) {
          return JoiWriteNote(literal: s.substring(colon + 1).trim());
        }
      }
      var topic = s
          .replaceAll(
            RegExp(
              r"(?<![\p{L}])(not defter[iı]me|notlar[ıi]ma|not olarak|yeni (?:bir )?not|to my notes|in my notes|please|lütfen)(?![\p{L}])",
              caseSensitive: false,
              unicode: true,
            ),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return JoiWriteNote(request: topic);
    }

    // ---- image search
    final tr = RegExp(
      r"^(.+?)\s+(?:adl[ıi]\s+)?(?:bir\s+)?(fotoğraf|fotograf|resim|görsel|gorsel|foto)\p{L}*\s*(?:indir|bul|göster|goster|getir|ara)\p{L}*[.!?]*$",
      caseSensitive: false,
      unicode: true,
    );
    var m = tr.firstMatch(s);
    if (m != null) {
      return JoiImageSearch(_cleanSubject(m.group(1)!));
    }
    final tr2 = RegExp(
      r"^(?:bana\s+)?(?:bir\s+)?(?:fotoğraf|fotograf|resim|görsel|foto)\p{L}*\s*(?:indir|bul|göster|getir)\p{L}*\s*:?\s+(.+)$",
      caseSensitive: false,
      unicode: true,
    );
    m = tr2.firstMatch(s);
    if (m != null) return JoiImageSearch(_cleanSubject(m.group(1)!));
    final en = RegExp(
      r"(?:download|find|show|get)(?: me)?(?: an?| some)? (?:photo|picture|image|pic)s? of (.+?)[.!?]*$",
      caseSensitive: false,
      unicode: true,
    );
    m = en.firstMatch(s);
    if (m != null) return JoiImageSearch(_cleanSubject(m.group(1)!));
    return null;
  }

  /// "Galata Kulesi'nin" → "Galata Kulesi".
  static String _cleanSubject(String x) {
    var s = x.trim();
    s = s.replaceAll(
      RegExp(r"^(bana|benim için|lütfen)\s+", caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r"['’](n?[ıiuü]n|n?[ıiuü]|[ae]|d[ae]n|t[ae]n)$"),
      '',
    );
    s = s.replaceAll(RegExp(r"\s+(bir|bi)$"), '');
    return s.trim();
  }
}

class JoiImageSearch extends JoiIntent {
  const JoiImageSearch(this.query);
  final String query;
}

class JoiWriteNote extends JoiIntent {
  const JoiWriteNote({this.request, this.literal});

  /// Generate content for this request (e.g. "Sokrates'in hayatının kısa
  /// bir özetini yaz").
  final String? request;

  /// Write exactly this text.
  final String? literal;

  /// Prompt for the model (only the user's request — never existing notes).
  String prompt() =>
      'Kullanıcı not defterine şunu istiyor: "${request ?? ''}". '
      'Not içeriğini yaz: ilk satır kısa bir başlık (en fazla 6 kelime, '
      'işaretsiz), ardından boş satır ve kısa, düzenli içerik (madde '
      'işaretleri olabilir, en fazla ~150 kelime). Sadece notu yaz.';

  /// Splits model output / literal text into (title, body).
  static (String, String) titleBody(String text, {String fallback = ''}) {
    final t = text.trim().replaceAll('\r', '');
    final lines = t.split('\n');
    var title = lines.first
        .replaceAll(RegExp(r'^[#*\s]+|[*\s]+$'), '')
        .replaceAll(RegExp(r'^(başlık|title)\s*:\s*', caseSensitive: false), '')
        .trim();
    var body = lines.skip(1).join('\n').trim();
    if (body.isEmpty) {
      body = t;
      title = fallback;
    }
    if (title.isEmpty) title = fallback;
    if (title.length > 60) title = '${title.substring(0, 57)}…';
    return (title, body);
  }
}

/// A freely licensed image from Wikimedia Commons.
class CommonsImage {
  const CommonsImage({
    required this.title,
    required this.thumbUrl,
    required this.url,
    required this.pageUrl,
    required this.author,
    required this.license,
    this.licenseUrl,
    this.mime = 'image/jpeg',
  });
  final String title;
  final String thumbUrl;
  final String url;
  final String pageUrl;
  final String author;
  final String license;
  final String? licenseUrl;
  final String mime;

  String get attribution =>
      '$title — $author — $license — $pageUrl (Wikimedia Commons)';

  String get fileName {
    final base = title
        .replaceFirst(RegExp(r'^File:'), '')
        .replaceAll(RegExp(r'[^\w.\-]+', unicode: true), '_');
    return base.length > 80 ? base.substring(base.length - 80) : base;
  }
}

/// Wikimedia Commons search (free API, no key). Only files with a free
/// licence name are returned (Commons hosts free content only; anything
/// without licence metadata or marked non-free is skipped).
class CommonsSearch {
  CommonsSearch({HttpClient Function()? client})
    : _client = client ?? HttpClient.new;
  final HttpClient Function() _client;

  static const userAgent =
      'GizliAlan/0.6.2 (Android; com.offerforge.gizlialan; joi image search)';

  static Uri searchUri(String q, {int limit = 12}) =>
      Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'formatversion': '2',
        'generator': 'search',
        'gsrsearch': '$q filetype:bitmap',
        'gsrnamespace': '6',
        'gsrlimit': '$limit',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|mime',
        'iiurlwidth': '1280',
        'iiextmetadatafilter': 'Artist|LicenseShortName|LicenseUrl|NonFree',
      });

  static String _strip(String? html) => (html ?? '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _free(String lic) {
    final l = lic.toLowerCase();
    if (l.isEmpty || l.contains('fair use') || l.contains('non-free')) {
      return false;
    }
    return l.contains('cc') ||
        l.contains('public domain') ||
        l.contains('pd') ||
        l.contains('gfdl') ||
        l.contains('attribution') ||
        l.contains('fal') ||
        l.contains('free');
  }

  /// Parses an API response (pure; unit-tested).
  static List<CommonsImage> parse(Map<String, dynamic> j, {int max = 6}) {
    final pages = ((j['query'] as Map?)?['pages'] as List?) ?? const [];
    final sorted = [...pages.cast<Map>()]
      ..sort(
        (a, b) =>
            ((a['index'] ?? 0) as int).compareTo((b['index'] ?? 0) as int),
      );
    final out = <CommonsImage>[];
    for (final p in sorted) {
      final ii = (p['imageinfo'] as List?)?.cast<Map>().firstOrNull;
      if (ii == null) continue;
      final mime = (ii['mime'] ?? '').toString();
      if (!(mime == 'image/jpeg' ||
          mime == 'image/png' ||
          mime == 'image/webp')) {
        continue;
      }
      final md = (ii['extmetadata'] as Map?) ?? const {};
      String v(String k) => _strip(((md[k] as Map?)?['value'])?.toString());
      final lic = v('LicenseShortName');
      if (v('NonFree').isNotEmpty || !_free(lic)) continue;
      final thumb = (ii['thumburl'] ?? ii['url'] ?? '').toString();
      if (thumb.isEmpty) continue;
      final title = (p['title'] ?? '').toString();
      out.add(
        CommonsImage(
          title: title.replaceFirst(RegExp(r'^File:'), ''),
          thumbUrl: thumb,
          url: thumb,
          pageUrl: (ii['descriptionurl'] ?? '').toString(),
          author: v('Artist').isEmpty ? 'Bilinmiyor' : v('Artist'),
          license: lic,
          licenseUrl: v('LicenseUrl').isEmpty ? null : v('LicenseUrl'),
          mime: mime,
        ),
      );
      if (out.length >= max) break;
    }
    return out;
  }

  Future<Map<String, dynamic>> _getJson(Uri u) async {
    final c = _client()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await c.getUrl(u);
      req.headers.set(HttpHeaders.userAgentHeader, userAgent);
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return jsonDecode(await res.transform(utf8.decoder).join())
          as Map<String, dynamic>;
    } finally {
      c.close();
    }
  }

  Future<List<CommonsImage>> search(String q) async =>
      parse(await _getJson(searchUri(q)));

  /// Downloads the (≤1280 px) image bytes.
  Future<Uint8List> download(CommonsImage img) async {
    final c = _client()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await c.getUrl(Uri.parse(img.url));
      req.headers.set(HttpHeaders.userAgentHeader, userAgent);
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final b = BytesBuilder(copy: false);
      await for (final chunk in res) {
        b.add(chunk);
        if (b.length > 15 * 1024 * 1024) throw const HttpException('too big');
      }
      return b.takeBytes();
    } finally {
      c.close();
    }
  }
}

/// True for network-type failures (show "internet yok").
bool joiIsOffline(Object e) =>
    e is SocketException ||
    e is HandshakeException ||
    (e is HttpException && !e.message.startsWith('HTTP')) ||
    e.toString().contains('Failed host lookup');

String joiDebugName(Object e) => e.runtimeType.toString();
