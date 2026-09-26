import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/browser_download.dart';

final png = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13];
final jpeg = <int>[0xFF, 0xD8, 0xFF, 0xE0, 0, 16];

void main() {
  group('BrowserDownloadLogic', () {
    test('only http(s) and data: URLs are supported', () {
      expect(
        BrowserDownloadLogic.isSupportedUrl('https://a.com/x.jpg'),
        isTrue,
      );
      expect(BrowserDownloadLogic.isSupportedUrl('http://a.com/x'), isTrue);
      expect(
        BrowserDownloadLogic.isSupportedUrl('data:image/png;base64,AAAA'),
        isTrue,
      );
      for (final u in [
        'blob:https://a.com/1',
        'file:///sdcard/x.jpg',
        'content://media/1',
        'javascript:alert(1)',
        'https://',
        '',
      ]) {
        expect(BrowserDownloadLogic.isSupportedUrl(u), isFalse, reason: u);
      }
    });

    test('mime normalisation and image check', () {
      expect(
        BrowserDownloadLogic.normalizeMime('Image/PNG; charset=x'),
        'image/png',
      );
      expect(BrowserDownloadLogic.normalizeMime(''), isNull);
      expect(BrowserDownloadLogic.isImageMime('image/webp'), isTrue);
      expect(BrowserDownloadLogic.isImageMime('application/pdf'), isFalse);
      expect(
        BrowserDownloadLogic.targetFor('image/jpeg'),
        DownloadTarget.photos,
      );
      expect(
        BrowserDownloadLogic.targetFor('application/zip'),
        DownloadTarget.files,
      );
    });

    test('sniffs common image formats', () {
      expect(BrowserDownloadLogic.sniffImageMime(png), 'image/png');
      expect(BrowserDownloadLogic.sniffImageMime(jpeg), 'image/jpeg');
      expect(
        BrowserDownloadLogic.sniffImageMime(ascii.encode('GIF89a..')),
        'image/gif',
      );
      expect(
        BrowserDownloadLogic.sniffImageMime([
          ...ascii.encode('RIFF'),
          0,
          0,
          0,
          0,
          ...ascii.encode('WEBPVP8 '),
        ]),
        'image/webp',
      );
      expect(
        BrowserDownloadLogic.sniffImageMime([
          0,
          0,
          0,
          24,
          ...ascii.encode('ftypheic'),
        ]),
        'image/heic',
      );
      expect(
        BrowserDownloadLogic.sniffImageMime(ascii.encode('<svg xmlns="">')),
        'image/svg+xml',
      );
      expect(
        BrowserDownloadLogic.sniffImageMime(ascii.encode('%PDF-1.7')),
        isNull,
      );
    });

    test('image bytes win over a generic server type', () {
      expect(
        BrowserDownloadLogic.resolveMime('application/octet-stream', png),
        'image/png',
      );
      expect(BrowserDownloadLogic.resolveMime(null, jpeg), 'image/jpeg');
      expect(BrowserDownloadLogic.resolveMime('image/webp', png), 'image/webp');
      expect(
        BrowserDownloadLogic.resolveMime(
          'application/pdf',
          ascii.encode('%PDF'),
        ),
        'application/pdf',
      );
      expect(
        BrowserDownloadLogic.resolveMime(null, [1, 2, 3]),
        'application/octet-stream',
      );
    });

    test('file names: Content-Disposition, URL, extension, sanitising', () {
      expect(
        BrowserDownloadLogic.fileName(
          url: 'https://a.com/dl?id=1',
          contentDisposition:
              "attachment; filename*=UTF-8''r%C3%A9sum%C3%A9.pdf",
          mime: 'application/pdf',
        ),
        'résumé.pdf',
      );
      expect(
        BrowserDownloadLogic.fileName(
          url: 'https://a.com/x',
          contentDisposition: 'attachment; filename="report 1.zip"',
          mime: 'application/zip',
        ),
        'report 1.zip',
      );
      expect(
        BrowserDownloadLogic.fileName(
          url: 'https://a.com/img/cat',
          mime: 'image/png',
        ),
        'cat.png',
      );
      expect(
        BrowserDownloadLogic.fileName(
          url: 'https://a.com/',
          mime: 'image/jpeg',
        ),
        'image.jpg',
      );
      expect(
        BrowserDownloadLogic.fileName(
          url: 'data:image/png;base64,AAAA',
          mime: 'image/png',
        ),
        'image.png',
      );
      final evil = BrowserDownloadLogic.fileName(
        url: 'https://a.com/x',
        contentDisposition: 'attachment; filename="../../etc/passwd"',
        mime: 'text/plain',
      );
      expect(evil.contains('/'), isFalse);
      expect(evil.contains('..'), isTrue); // only as harmless characters
    });

    test(
      'limits: 25 MB images (long-press), 100 MB files; image-only check',
      () {
        expect(
          BrowserDownloadLogic.limitFor(imageOnly: true),
          25 * 1024 * 1024,
        );
        expect(
          BrowserDownloadLogic.limitFor(imageOnly: false),
          100 * 1024 * 1024,
        );
        const img = DownloadRequest(url: 'https://a/x', imageOnly: true);
        const any = DownloadRequest(url: 'https://a/x');
        BrowserDownloadLogic.validate(img, 'image/png', 10);
        BrowserDownloadLogic.validate(any, 'application/pdf', 30 * 1024 * 1024);
        expect(
          () =>
              BrowserDownloadLogic.validate(img, 'image/png', 26 * 1024 * 1024),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.tooLarge,
            ),
          ),
        );
        expect(
          () => BrowserDownloadLogic.validate(
            any,
            'video/mp4',
            101 * 1024 * 1024,
          ),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.tooLarge,
            ),
          ),
        );
        expect(
          () => BrowserDownloadLogic.validate(img, 'text/html', 10),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.notImage,
            ),
          ),
        );
        expect(
          () => BrowserDownloadLogic.validate(any, 'text/plain', 0),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.empty,
            ),
          ),
        );
      },
    );
  });

  group('BrowserDownloader', () {
    final dl = BrowserDownloader();

    test('data: image URL is decoded into memory as a photo', () async {
      final f = await dl.fetch(
        DownloadRequest(
          url: 'data:image/png;base64,${base64Encode(png)}',
          imageOnly: true,
        ),
      );
      expect(f.mime, 'image/png');
      expect(f.bytes, png);
      expect(f.target, DownloadTarget.photos);
      expect(f.name, 'image.png');
    });

    test('data: non-image on long-press is rejected', () async {
      await expectLater(
        dl.fetch(
          const DownloadRequest(url: 'data:text/plain,hello', imageOnly: true),
        ),
        throwsA(
          isA<DownloadException>().having(
            (e) => e.failure,
            'f',
            DownloadFailure.notImage,
          ),
        ),
      );
    });

    test('unsupported schemes are rejected without network', () async {
      await expectLater(
        dl.fetch(const DownloadRequest(url: 'blob:https://a.com/1')),
        throwsA(
          isA<DownloadException>().having(
            (e) => e.failure,
            'f',
            DownloadFailure.unsupported,
          ),
        ),
      );
    });

    test(
      'http: fetches with cookies/UA/referer, sniffs type, names file',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final seen = <String, String?>{};
        server.listen((req) {
          seen['cookie'] = req.headers.value(HttpHeaders.cookieHeader);
          seen['ua'] = req.headers.value(HttpHeaders.userAgentHeader);
          seen['referer'] = req.headers.value(HttpHeaders.refererHeader);
          if (req.uri.path == '/pic') {
            req.response.headers.contentType = ContentType.binary;
            req.response.add(jpeg);
          } else if (req.uri.path == '/doc') {
            req.response.headers.contentType = ContentType(
              'application',
              'pdf',
            );
            req.response.headers.set(
              'content-disposition',
              'attachment; filename="a.pdf"',
            );
            req.response.add(ascii.encode('%PDF-1.7 test'));
          } else {
            req.response.statusCode = 404;
          }
          req.response.close();
        });
        addTearDown(() => server.close(force: true));
        final base = 'http://127.0.0.1:${server.port}';

        final pic = await dl.fetch(
          DownloadRequest(
            url: '$base/pic',
            cookies: 'sid=1',
            userAgent: 'UA/1',
            referer: 'https://page.example/',
            imageOnly: true,
          ),
        );
        expect(pic.mime, 'image/jpeg');
        expect(pic.name, 'pic.jpg');
        expect(pic.target, DownloadTarget.photos);
        expect(seen['cookie'], 'sid=1');
        expect(seen['ua'], 'UA/1');
        expect(seen['referer'], 'https://page.example/');

        final doc = await dl.fetch(DownloadRequest(url: '$base/doc'));
        expect(doc.name, 'a.pdf');
        expect(doc.target, DownloadTarget.files);

        await expectLater(
          dl.fetch(DownloadRequest(url: '$base/missing')),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.network,
            ),
          ),
        );
        // Declared too large up front: refused before downloading.
        await expectLater(
          dl.fetch(
            DownloadRequest(url: '$base/pic', contentLength: 200 * 1024 * 1024),
          ),
          throwsA(
            isA<DownloadException>().having(
              (e) => e.failure,
              'f',
              DownloadFailure.tooLarge,
            ),
          ),
        );
      },
    );
  });
}
