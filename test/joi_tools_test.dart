import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/crypto_service.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/update_service.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCommons extends CommonsSearch {
  int calls = 0;
  @override
  Future<List<CommonsImage>> search(String q) async {
    calls++;
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('gizlialan/joi');
  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, null);
  });

  group('intent detection', () {
    test('photo download (TR/EN)', () {
      final a = JoiIntent.parse("Galata Kulesi'nin fotoğrafını indir");
      expect(a, isA<JoiImageSearch>());
      expect((a as JoiImageSearch).query, 'Galata Kulesi');
      final b = JoiIntent.parse('Kedilerin fotoğrafını bul');
      expect((b as JoiImageSearch).query, 'Kedilerin');
      final c = JoiIntent.parse('Download a photo of the Eiffel Tower');
      expect((c as JoiImageSearch).query, 'the Eiffel Tower');
    });

    test('write to notes: generated and literal', () {
      final a = JoiIntent.parse(
        "Not defterime Sokrates'in hayatının kısa bir özetini yaz",
      );
      expect(a, isA<JoiWriteNote>());
      expect((a as JoiWriteNote).literal, isNull);
      expect(a.request, contains('Sokrates'));
      expect(a.prompt(), contains('Sokrates'));
      final b = JoiIntent.parse('not defterime şunu yaz: süt, ekmek, yumurta');
      expect((b as JoiWriteNote).literal, 'süt, ekmek, yumurta');
      expect(
        JoiIntent.parse("Sokrates'in hayatını not defterime özetle"),
        isA<JoiWriteNote>(),
      );
    });

    test('plain questions are not tools', () {
      for (final q in [
        'Aristoteles kim?',
        'nasılsın',
        'Bana bir motivasyon sözü söyle',
        'Fotoğrafçılık nedir?',
      ]) {
        expect(JoiIntent.parse(q), isNull, reason: q);
      }
    });

    test('note title/body split', () {
      final (t, b) = JoiWriteNote.titleBody(
        '**Sokrates**\n\n- Atina, MÖ 470\n- Sorgulama',
      );
      expect(t, 'Sokrates');
      expect(b, contains('Atina'));
      final (t2, b2) = JoiWriteNote.titleBody('tek satır', fallback: 'Joi');
      expect(t2, 'Joi');
      expect(b2, 'tek satır');
    });
  });

  test('Commons parse: free licences only, attribution kept', () {
    Map<String, dynamic> page(
      int i,
      String lic, {
      String mime = 'image/jpeg',
    }) => {
      'title': 'File:P$i.jpg',
      'index': i,
      'imageinfo': [
        {
          'thumburl': 'https://x/$i.jpg',
          'descriptionurl': 'https://commons.wikimedia.org/wiki/File:P$i.jpg',
          'mime': mime,
          'extmetadata': {
            'Artist': {'value': '<a href="x">Ali</a>'},
            'LicenseShortName': {'value': lic},
          },
        },
      ],
    };
    final r = CommonsSearch.parse({
      'query': {
        'pages': [
          page(2, 'CC BY-SA 4.0'),
          page(1, 'Public domain'),
          page(3, 'Fair use'),
          page(4, ''),
          page(5, 'CC0', mime: 'image/tiff'),
        ],
      },
    });
    expect(r.map((e) => e.title), ['P1.jpg', 'P2.jpg']);
    expect(r[1].author, 'Ali');
    expect(r[1].attribution, contains('CC BY-SA 4.0'));
    expect(
      CommonsSearch.searchUri('Galata Kulesi').host,
      'commons.wikimedia.org',
    );
  });

  test('online history: last 20, never note-derived messages', () {
    final msgs = [
      for (var i = 0; i < 30; i++)
        JoiChatMsg(
          fromUser: i.isEven,
          text: 'm$i',
          online: i.isOdd ? true : null,
        ),
      const JoiChatMsg(fromUser: false, text: 'GIZLI NOT', private: true),
      const JoiChatMsg(fromUser: false, text: 'Notlarında bunları buldum'),
    ];
    final h = joiOnlineHistory(msgs);
    expect(h, hasLength(20));
    expect(h.map((e) => e['text']).join(), isNot(contains('GIZLI')));
    expect(h.last['text'], 'm29');
    expect(h.last['role'], 'model');
  });

  test('chat history persists encrypted', () async {
    final dir = await Directory.systemTemp.createTemp('joi');
    final files = EncryptedFiles(CryptoService.newKey(), CryptoService());
    final f = File('${dir.path}/joi_chat.gae');
    final st = JoiChatStore(files, f);
    await st.save(const [
      JoiChatMsg(fromUser: true, text: 'Merhaba gizli'),
      JoiChatMsg(fromUser: false, text: 'Selam', online: true),
    ]);
    expect(
      utf8.decode(await f.readAsBytes(), allowMalformed: true),
      isNot(contains('Merhaba')),
    );
    final again = await JoiChatStore(files, f).load();
    expect(again.map((m) => m.text), ['Merhaba gizli', 'Selam']);
    expect(again[1].online, isTrue);
    await st.clear();
    expect(await st.load(), isEmpty);
    await dir.delete(recursive: true);
  });

  test('settings: resume where left + Joi speak', () async {
    SharedPreferences.setMockInitialValues({});
    final s = SettingsService(await SharedPreferences.getInstance());
    expect(s.resumeWhereLeft, isFalse);
    expect(s.effectiveLockTimeoutSec, s.lockTimeoutSec);
    await s.setResumeWhereLeft(true);
    expect(s.effectiveLockTimeoutSec, 5 * 60);
    await s.setResumeMaxMin(15);
    expect(s.effectiveLockTimeoutSec, 15 * 60);
    await s.setResumeMaxMin(7);
    expect(s.resumeMaxMin, 5);
    await s.setResumeWhereLeft(false);
    expect(s.effectiveLockTimeoutSec, s.lockTimeoutSec);
    expect(s.joiSpeak, isFalse);
  });

  test('update service rules + bundled changelog', () {
    final now = DateTime(2026, 10, 27, 12);
    expect(UpdateService.snoozeOver(null, now), isTrue);
    expect(
      UpdateService.snoozeOver(
        now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        now,
      ),
      isFalse,
    );
    expect(
      UpdateService.snoozeOver(
        now
            .subtract(const Duration(days: 1, minutes: 1))
            .millisecondsSinceEpoch,
        now,
      ),
      isTrue,
    );
    expect(UpdateService.showWhatsNew(current: 46, lastSeen: 45), isTrue);
    expect(UpdateService.showWhatsNew(current: 46, lastSeen: null), isFalse);
    expect(UpdateService.showWhatsNew(current: 46, lastSeen: 46), isFalse);
    final json = File('assets/changelog.json').readAsStringSync();
    expect(UpdateService.notesFor(json, 45, 'tr'), isNotEmpty);
    expect(UpdateService.notesFor(json, 45, 'ru'), isNotEmpty);
    expect(UpdateService.notesFor(json, 999, 'tr'), isEmpty);
  });

  test('note text: online uses only the request, never notes', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          return c.method == 'status' ? 'unavailable' : 'Sokrates\n\n- Atina';
        });
    final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
    await j.status();
    final a = await j.writeNoteText(
      const JoiWriteNote(request: "Sokrates'in hayatı"),
      lang: 'tr',
    );
    expect(a.text, contains('Atina'));
    final sent = calls.singleWhere((c) => c.method == 'onlineGenerate');
    expect(sent.arguments['question'], contains("Sokrates'in hayatı"));
  });

  Widget app(Widget w) => MaterialApp(theme: GizliTheme.light(), home: w);

  testWidgets('free user: tool intents upsell, no network', (tester) async {
    L10n.setLang('tr');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ch,
          (c) async => c.method == 'status' ? 'unavailable' : 'x',
        );
    final commons = _FakeCommons();
    var notes = 0;
    await tester.pumpWidget(
      app(
        JoiScreen(
          service: JoiService(onlineConfig: cfg, hasOnlineConsent: () => true),
          consent: () => true,
          commons: commons,
          isPro: () => false,
          createNote: (_, _) async {
            notes++;
            return 'n';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Examples shown, Pro ones badged.
    expect(find.byKey(const ValueKey('joi_example_0')), findsOneWidget);
    expect(find.text('Pro'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('joi_input')),
      "Galata Kulesi'nin fotoğrafını indir",
    );
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('pro_required')), findsOneWidget);
    expect(commons.calls, 0);
    expect(notes, 0);
  });

  testWidgets('pro user: writes a note and offers to open it', (tester) async {
    L10n.setLang('tr');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ch,
          (c) async => c.method == 'status'
              ? 'unavailable'
              : 'Sokrates\n\nAtinalı filozof.',
        );
    String? title;
    String? body;
    await tester.pumpWidget(
      app(
        JoiScreen(
          service: JoiService(onlineConfig: cfg, hasOnlineConsent: () => true),
          consent: () => true,
          isPro: () => true,
          createNote: (t, b) async {
            title = t;
            body = b;
            return 'n1';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('joi_input')),
      "Not defterime Sokrates'in hayatının kısa bir özetini yaz",
    );
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(title, 'Sokrates');
    expect(body, 'Atinalı filozof.');
    expect(find.byKey(const ValueKey('joi_open_note')), findsOneWidget);
  });

  test('platform save is a no-op without the channel', () async {
    expect(await const JoiPlatform().canSaveToPictures(), isFalse);
    expect(
      await const JoiPlatform().saveToPictures(
        Uint8List(1),
        name: 'a.jpg',
        mime: 'image/jpeg',
        description: 'x',
      ),
      isNull,
    );
  });
}
