import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/joi_memory_screen.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/crypto_service.dart';
import 'package:gizlialan/services/joi_memory.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/services/vault_session.dart';
import 'package:gizlialan/theme.dart';

JoiChatMsg u(String t) => JoiChatMsg(fromUser: true, text: t);
JoiChatMsg j(String t) => JoiChatMsg(fromUser: false, text: t, online: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('gizlialan/joi');
  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');
  late Directory dir;
  late EncryptedFiles files;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('joimem');
    files = EncryptedFiles(CryptoService.newKey(), CryptoService());
  });
  tearDown(() => dir.delete(recursive: true));

  test('parse ops, apply add/update/delete, sensitive dropped in code', () {
    final d = JoiMemoryData();
    final ops = parseMemoryOps('''```json
{"facts":[
 {"op":"add","text":"Kullanıcının adı Demirhan","category":"identity","importance":5,"target_id":null},
 {"op":"add","text":"Kedisinin adı Pamuk","category":"pets","importance":4},
 {"op":"add","text":"Şifresi 1234","category":"other","importance":5},
 {"op":"add","text":"Diyabet hastası","category":"health","importance":5},
 {"op":"add","text":"IBAN TR12 0006 1005 1978 6457 8413 26","category":"other"},
 {"op":"add","text":"x","category":"other"}
]}```''')!;
    expect(ops, hasLength(5)); // max 5
    final added = d.apply(ops);
    expect(added.map((f) => f.text), [
      'Kullanıcının adı Demirhan',
      'Kedisinin adı Pamuk',
    ]);
    final pamuk = d.facts[1];
    d.apply([
      MemoryOp(
        op: 'update',
        text: 'Kedisinin adı Pamuk, beyaz bir Van kedisi',
        category: 'pets',
        importance: 4,
        targetId: pamuk.id,
      ),
      MemoryOp(op: 'delete', targetId: d.facts[0].id),
    ]);
    expect(d.facts.single.text, contains('Van kedisi'));
    expect(parseMemoryOps('nope'), isNull);
    expect(joiMemorySensitive('other', 'Telefonum 0532 123 45 67'), isTrue);
    expect(joiMemorySensitive('preference', 'Kahveyi sütsüz sever'), isFalse);
  });

  test('memory input filters notes / tools / note-writing IN CODE', () {
    final input = joiMemoryInput([
      u('Benim adım Demirhan'),
      j('Memnun oldum Demirhan!'),
      const JoiChatMsg(
        fromUser: false,
        text: 'Not: banka şifrem',
        private: true,
      ),
      const JoiChatMsg(fromUser: false, text: 'Not oluşturuldu', noteId: 'n1'),
      const JoiChatMsg(fromUser: false, text: 'Hadise fotoğrafları'),
      u('Not defterime alışveriş listesi yaz: süt, ekmek'),
    ]);
    expect(input.map((e) => e['text']), [
      'Benim adım Demirhan',
      'Memnun oldum Demirhan!',
    ]);
  });

  test('Turkish-aware retrieval + profile + block', () {
    final now = DateTime(2026, 10, 27);
    final d = JoiMemoryData()
      ..apply([
        const MemoryOp(
          op: 'add',
          text: 'Kullanıcının adı Demirhan',
          category: 'identity',
          importance: 5,
        ),
        const MemoryOp(
          op: 'add',
          text: 'Kedisinin adı Pamuk',
          category: 'pets',
          importance: 3,
        ),
        const MemoryOp(
          op: 'add',
          text: 'Caz müziği sever',
          category: 'preference',
          importance: 2,
        ),
        const MemoryOp(
          op: 'add',
          text: 'Maraton koşmak istiyor',
          category: 'goal',
          importance: 2,
        ),
      ], now: now);
    expect(joiStems("Kedimin adı neydi?"), contains('ked'));
    final r = joiRetrieve(d.facts, 'Kedimin adı neydi?', now: now);
    expect(r.first.text, 'Kedisinin adı Pamuk');
    expect(
      joiRetrieve(d.facts, 'caz dinlemek', now: now).first.text,
      'Caz müziği sever',
    );
    final b = joiMemoryBlock(d, 'Kedimin adı neydi?', now: now);
    expect(b, contains('Demirhan'));
    expect(b, contains('Pamuk'));
    expect(b, isNot(contains('Maraton')));
    expect(b, contains('liste hâlinde'));
    final p = JoiService.onlineSystemPrompt('tr', memory: b);
    expect(p, contains('Pamuk'));
    expect(JoiService.onlineSystemPrompt('tr'), isNot(contains('HAFIZA')));
  });

  test('engine: extracts every 10 msgs / on force, summarizes old turns; '
      'store is encrypted and separate from the chat', () async {
    final calls = <Map>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          if (c.method == 'status') return 'unavailable';
          final a = c.arguments as Map;
          calls.add(a);
          if (a['system'] == joiMemoryExtractPrompt) {
            return '{"facts":[{"op":"add","text":"Kedisinin adı Pamuk","category":"pets","importance":4}]}';
          }
          return 'Kullanıcı kedisinden bahsetti.';
        });
    final svc = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
    await svc.status();
    final store = JoiMemoryStore(files, File('${dir.path}/joi_memory.gae'));
    final e = JoiMemoryEngine(store, svc);
    final chat = [u('Kedimin adı Pamuk'), j('Ne güzel bir isim!')];
    expect(await e.process(chat), isEmpty); // < 10, not forced
    expect(calls, isEmpty);
    final added = await e.process(chat, force: true);
    expect(added.single.text, 'Kedisinin adı Pamuk');
    expect(calls.single['question'], contains('User: Kedimin adı Pamuk'));
    // Encrypted on disk.
    final raw = await File('${dir.path}/joi_memory.gae').readAsBytes();
    expect(String.fromCharCodes(raw), isNot(contains('Pamuk')));
    // 40 messages → older part summarized.
    final long = [
      for (var i = 0; i < 20; i++) ...[u('soru $i'), j('cevap $i')],
    ];
    await store.chatCleared();
    calls.clear();
    await e.process(long, force: true);
    final d = await store.load();
    expect(d.summaries.single.text, 'Kullanıcı kedisinden bahsetti.');
    expect(d.summarizedUpTo, 20);
    expect(d.facts, hasLength(1)); // duplicate not re-added
    // Forget all.
    await store.forgetAll();
    expect((await store.load()).facts, isEmpty);
  });

  Widget app(Widget w) => MaterialApp(theme: GizliTheme.light(), home: w);

  testWidgets('memory screen: list, delete, forget all; free = upsell', (
    tester,
  ) async {
    L10n.setLang('tr');
    final store = JoiMemoryStore(files, File('${dir.path}/m.gae'));
    final d = JoiMemoryData()
      ..apply(const [
        MemoryOp(op: 'add', text: 'Kedisinin adı Pamuk', category: 'pets'),
        MemoryOp(op: 'add', text: 'Caz sever', category: 'preference'),
      ]);
    await tester.runAsync(() => store.save(d));
    await tester.pumpWidget(
      app(
        JoiMemoryScreen(store: store, isPro: () => true, enabled: () => true),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Kedisinin adı Pamuk'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('joi_fact_delete_${d.facts.last.id}')),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('Caz sever'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('joi_memory_forget_all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('joi_memory_forget_ok')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('joi_memory_empty')), findsOneWidget);

    await tester.pumpWidget(
      app(JoiMemoryScreen(store: store, isPro: () => false)),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('joi_memory_upsell')), findsOneWidget);
  });

  testWidgets('Joi screen: memory used in the prompt + chip; clear chat keeps '
      'memories; free users: no memory', (tester) async {
    L10n.setLang('tr');
    final sent = <Map>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          if (c.method == 'status') return 'unavailable';
          final a = c.arguments as Map;
          sent.add(a);
          if (a['system'] == joiMemoryExtractPrompt) {
            return '{"facts":[{"op":"add","text":"Köpeğinin adı Karabaş","category":"pets","importance":4}]}';
          }
          return 'Tamam!';
        });
    final store = JoiMemoryStore(files, File('${dir.path}/m2.gae'));
    await tester.runAsync(
      () => store.save(
        JoiMemoryData()..apply(const [
          MemoryOp(
            op: 'add',
            text: 'Kedisinin adı Pamuk',
            category: 'pets',
            importance: 4,
          ),
        ]),
      ),
    );
    Future<void> open({required bool pro}) async {
      await tester.pumpWidget(
        app(
          JoiScreen(
            service: JoiService(
              onlineConfig: cfg,
              hasOnlineConsent: () => true,
            ),
            consent: () => true,
            isPro: () => pro,
            memoryStore: store,
            memoryEnabled: () => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open(pro: true);
    await tester.enterText(
      find.byKey(const ValueKey('joi_input')),
      'Kedimin adı neydi?',
    );
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final chat = sent.firstWhere((a) => a['question'] == 'Kedimin adı neydi?');
    expect(chat['system'], contains('Kedisinin adı Pamuk'));
    // Exit → forced extraction → saved fact.
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    final d = await tester.runAsync(store.load);
    expect(d!.facts.map((f) => f.text), contains('Köpeğinin adı Karabaş'));

    // Free: nothing from memory goes into the prompt.
    sent.clear();
    await open(pro: false);
    await tester.enterText(
      find.byKey(const ValueKey('joi_input')),
      'Kedimin adı neydi?',
    );
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (final a in sent) {
      expect('${a['system']}', isNot(contains('Pamuk')));
    }
  });

  test('chip text key exists', () {
    L10n.setLang('tr');
    expect(L10n.current('joiMemorySaved'), 'Joi bunu hatırladı');
  });
}
