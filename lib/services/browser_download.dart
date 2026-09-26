import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// In-vault browser downloads (#45). Everything the private browser
/// downloads (any file via the WebView download callback, or an image via
/// long-press "Save image to vault") goes straight into the encrypted vault:
/// images → Photos, everything else → Files. Nothing is ever written to
/// public storage / Downloads; bytes are held in memory and sealed by
/// VaultStorage.
class DownloadRequest {
  const DownloadRequest({
    required this.url,
    this.userAgent,
    this.contentDisposition,
    this.mimeType,
    this.contentLength = -1,
    this.cookies,
    this.referer,
    this.imageOnly = false,
  });

  factory DownloadRequest.fromMap(
    Map<dynamic, dynamic> m, {
    bool imageOnly = false,
  }) => DownloadRequest(
    url: (m['url'] as String?) ?? '',
    userAgent: m['userAgent'] as String?,
    contentDisposition: m['contentDisposition'] as String?,
    mimeType: m['mimeType'] as String?,
    contentLength: (m['contentLength'] as num?)?.toInt() ?? -1,
    cookies: m['cookies'] as String?,
    referer: m['referer'] as String?,
    imageOnly: imageOnly,
  );

  final String url;
  final String? userAgent;
  final String? contentDisposition;
  final String? mimeType;
  final int contentLength;
  final String? cookies;
  final String? referer;

  /// Long-press "Save image to vault": only images are accepted.
  final bool imageOnly;
}

enum DownloadTarget { photos, files }

enum DownloadFailure { unsupported, tooLarge, notImage, network, empty }

class DownloadException implements Exception {
  const DownloadException(this.failure);
  final DownloadFailure failure;
  @override
  String toString() => 'DownloadException($failure)';
}

class DownloadedFile {
  const DownloadedFile(this.name, this.mime, this.bytes);
  final String name;
  final String mime;
  final Uint8List bytes;

  DownloadTarget get target => BrowserDownloadLogic.targetFor(mime);
}

/// Pure (unit-tested) rules: which URLs, limits, MIME detection, file names.
class BrowserDownloadLogic {
  BrowserDownloadLogic._();

  static const int maxImageBytes = 25 * 1024 * 1024;
  static const int maxFileBytes = 100 * 1024 * 1024;

  static int limitFor({required bool imageOnly}) =>
      imageOnly ? maxImageBytes : maxFileBytes;

  /// http(s) and data: only (no blob:, file:, content:, javascript: …).
  static bool isSupportedUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null) return false;
    final s = u.scheme.toLowerCase();
    if (s == 'data') return true;
    return (s == 'http' || s == 'https') && u.host.isNotEmpty;
  }

  /// `Image/PNG; charset=x` → `image/png`; empty/null → null.
  static String? normalizeMime(String? mime) {
    if (mime == null) return null;
    final m = mime.split(';').first.trim().toLowerCase();
    return m.isEmpty ? null : m;
  }

  static bool isImageMime(String? mime) =>
      (normalizeMime(mime) ?? '').startsWith('image/');

  static DownloadTarget targetFor(String mime) =>
      isImageMime(mime) ? DownloadTarget.photos : DownloadTarget.files;

  /// Detects common image formats from their first bytes.
  static String? sniffImageMime(List<int> b) {
    bool at(int off, List<int> sig) {
      if (b.length < off + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[off + i] != sig[i]) return false;
      }
      return true;
    }

    if (at(0, [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (at(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    if (at(0, ascii.encode('GIF87a')) || at(0, ascii.encode('GIF89a'))) {
      return 'image/gif';
    }
    if (at(0, ascii.encode('RIFF')) && at(8, ascii.encode('WEBP'))) {
      return 'image/webp';
    }
    if (at(0, ascii.encode('BM'))) return 'image/bmp';
    if (at(4, ascii.encode('ftyp'))) {
      if (at(8, ascii.encode('avif')) || at(8, ascii.encode('avis'))) {
        return 'image/avif';
      }
      for (final brand in ['heic', 'heix', 'hevc', 'mif1', 'msf1']) {
        if (at(8, ascii.encode(brand))) return 'image/heic';
      }
    }
    final head = utf8
        .decode(b.take(256).toList(), allowMalformed: true)
        .trimLeft();
    if (head.startsWith('<svg') ||
        (head.startsWith('<?xml') && head.contains('<svg'))) {
      return 'image/svg+xml';
    }
    return null;
  }

  /// Final MIME: image bytes win over a wrong/generic server type.
  static String resolveMime(String? declared, List<int> bytes) {
    final sniffed = sniffImageMime(bytes);
    final d = normalizeMime(declared);
    if (sniffed != null &&
        (d == null || !d.startsWith('image/') || d == 'image/*')) {
      return sniffed;
    }
    return d ?? sniffed ?? 'application/octet-stream';
  }

  static const _extForMime = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/gif': 'gif',
    'image/webp': 'webp',
    'image/bmp': 'bmp',
    'image/heic': 'heic',
    'image/avif': 'avif',
    'image/svg+xml': 'svg',
    'application/pdf': 'pdf',
    'application/zip': 'zip',
    'text/plain': 'txt',
    'video/mp4': 'mp4',
    'audio/mpeg': 'mp3',
  };

  static String? extensionFor(String mime) => _extForMime[normalizeMime(mime)];

  /// `attachment; filename*=UTF-8''r%C3%A9sum%C3%A9.pdf` / `filename="a.png"`.
  static String? nameFromContentDisposition(String? cd) {
    if (cd == null || cd.isEmpty) return null;
    final star = RegExp(
      r"filename\*\s*=\s*([^']*)'[^']*'([^;]+)",
      caseSensitive: false,
    ).firstMatch(cd);
    if (star != null) {
      try {
        return Uri.decodeComponent(star.group(2)!.trim().replaceAll('"', ''));
      } catch (_) {}
    }
    final plain = RegExp(
      r'filename\s*=\s*("([^"]*)"|[^;]+)',
      caseSensitive: false,
    ).firstMatch(cd);
    if (plain != null) {
      final v = (plain.group(2) ?? plain.group(1)!).trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  /// Safe file name: from Content-Disposition, else the URL's last path
  /// segment, else "download"; an extension matching [mime] is added when
  /// missing. Never contains path separators.
  static String fileName({
    required String url,
    String? contentDisposition,
    required String mime,
  }) {
    var name = nameFromContentDisposition(contentDisposition);
    if (name == null) {
      final u = Uri.tryParse(url);
      if (u != null && u.scheme != 'data' && u.pathSegments.isNotEmpty) {
        final last = u.pathSegments.lastWhere(
          (s) => s.isNotEmpty,
          orElse: () => '',
        );
        if (last.isNotEmpty) name = last;
      }
    }
    name = (name ?? '')
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim();
    name = p.basename(name);
    if (name.isEmpty || name == '.' || name == '..') {
      name = isImageMime(mime) ? 'image' : 'download';
    }
    if (name.length > 120) name = name.substring(name.length - 120);
    final ext = extensionFor(mime);
    if (ext != null && p.extension(name).isEmpty) name = '$name.$ext';
    return name;
  }

  /// Checks a finished download against the request's rules.
  static void validate(DownloadRequest r, String mime, int length) {
    if (length == 0) throw const DownloadException(DownloadFailure.empty);
    if (length > limitFor(imageOnly: r.imageOnly)) {
      throw const DownloadException(DownloadFailure.tooLarge);
    }
    if (r.imageOnly && !isImageMime(mime)) {
      throw const DownloadException(DownloadFailure.notImage);
    }
  }
}

/// Fetches a [DownloadRequest] into memory (never to disk).
class BrowserDownloader {
  BrowserDownloader({HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  final HttpClient Function() _client;

  Future<DownloadedFile> fetch(DownloadRequest r) async {
    if (!BrowserDownloadLogic.isSupportedUrl(r.url)) {
      throw const DownloadException(DownloadFailure.unsupported);
    }
    final limit = BrowserDownloadLogic.limitFor(imageOnly: r.imageOnly);
    final uri = Uri.parse(r.url.trim());
    Uint8List bytes;
    String? declared;
    String? headerCd;
    if (uri.scheme.toLowerCase() == 'data') {
      final data = uri.data;
      if (data == null) {
        throw const DownloadException(DownloadFailure.unsupported);
      }
      // Rough pre-check before decoding (base64 is ~4/3 of the payload).
      if (r.url.length > limit * 4 ~/ 3 + 1024) {
        throw const DownloadException(DownloadFailure.tooLarge);
      }
      try {
        bytes = data.contentAsBytes();
      } catch (_) {
        throw const DownloadException(DownloadFailure.unsupported);
      }
      declared = data.mimeType;
    } else {
      if (r.contentLength > limit) {
        throw const DownloadException(DownloadFailure.tooLarge);
      }
      final client = _client()..connectionTimeout = const Duration(seconds: 20);
      try {
        final req = await client.getUrl(uri);
        if (r.userAgent != null) {
          req.headers.set(HttpHeaders.userAgentHeader, r.userAgent!);
        }
        if (r.cookies != null && r.cookies!.isNotEmpty) {
          req.headers.set(HttpHeaders.cookieHeader, r.cookies!);
        }
        final ref = r.referer;
        if (ref != null &&
            BrowserDownloadLogic.isSupportedUrl(ref) &&
            !ref.startsWith('data:')) {
          req.headers.set(HttpHeaders.refererHeader, ref);
        }
        final res = await req.close().timeout(const Duration(seconds: 30));
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw const DownloadException(DownloadFailure.network);
        }
        if (res.contentLength > limit) {
          throw const DownloadException(DownloadFailure.tooLarge);
        }
        declared = res.headers.contentType?.mimeType ?? r.mimeType;
        final b = BytesBuilder(copy: false);
        await for (final chunk in res.timeout(const Duration(seconds: 60))) {
          b.add(chunk);
          if (b.length > limit) {
            throw const DownloadException(DownloadFailure.tooLarge);
          }
        }
        bytes = b.takeBytes();
        headerCd = res.headers.value('content-disposition');
      } on DownloadException {
        rethrow;
      } catch (_) {
        throw const DownloadException(DownloadFailure.network);
      } finally {
        client.close(force: true);
      }
    }
    return _finish(
      r,
      declared ?? r.mimeType,
      bytes,
      r.contentDisposition ?? headerCd,
    );
  }

  DownloadedFile _finish(
    DownloadRequest r,
    String? declared,
    Uint8List bytes,
    String? contentDisposition,
  ) {
    final mime = BrowserDownloadLogic.resolveMime(declared, bytes);
    BrowserDownloadLogic.validate(r, mime, bytes.length);
    final name = BrowserDownloadLogic.fileName(
      url: r.url,
      contentDisposition: contentDisposition,
      mime: mime,
    );
    return DownloadedFile(name, mime, bytes);
  }
}
