import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/models/note.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/theme.dart';

Note _n(String id, String title, String body) => Note(
  id: id,
  title: title,
  body: body,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('gizlialan/joi');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, null);
  });

  test('name is exactly "Joi"', () => expect(JoiService.name, 'Joi'));

  test('system prompt identifies Joi and defaults to Turkish', () {
    final p = JoiService.systemPrompt('tr');
    expect(p, contains("Joi, GizliAlan'ın cihaz içi asistanı"));
    expect(p, contains('Türkçe'));
    expect(JoiService.systemPrompt('en'), contains('English'));
    final c = JoiService.chatPrompt('Aristoteles kim?', lang: 'tr');
    expect(c, contains('User: Aristoteles kim?'));
    expect(c, isNot(contains('(use them only if relevant)')));
  });

  test('both prompts carry Joi identity; online never claims on-device', () {
    for (final p in [
      JoiService.systemPrompt('tr'),
      JoiService.onlineSystemPrompt('tr'),
    ]) {
      expect(p, contains("Sen Joi'sin"));
      expect(p, contains('OfferForge'));
      expect(p, contains("Ben Joi, GizliAlan'ın asistanıyım."));
      expect(p, contains('Asla Gemini, Google'));
      expect(p, contains('insan olduğunu iddia etme'));
    }
    expect(JoiService.onlineSystemPrompt('tr'), isNot(contains('cihaz içi')));
    expect(
      JoiService.onlineSystemPrompt('tr'),
      isNot(contains('cihaz içinde')),
    );
  });

  test('notes context is capped', () {
    final big = _n('1', 'big', 'x' * 20000);
    expect(
      JoiService.notesContext([big]).length,
      lessThanOrEqualTo(JoiService.maxContextChars),
    );
    expect(
      JoiService.summarizePrompt(_n('2', 'Alışveriş', 'süt'), lang: 'tr'),
      contains('### Alışveriş'),
    );
  });

  test('keyword search: ranks title hits, Turkish case folding, stopwords', () {
    final notes = [
      _n('1', 'Market', 'süt, ekmek, İSTANBUL'),
      _n('2', 'Toplantı', 'market alışverişi sonra'),
      _n('3', 'Şifreler', 'wifi'),
    ];
    expect(JoiNoteSearch.search(notes, 'market').map((n) => n.id), ['1', '2']);
    expect(JoiNoteSearch.search(notes, 'istanbul').map((n) => n.id), ['1']);
    expect(JoiNoteSearch.search(notes, 'kim ne'), isEmpty);
    expect(JoiNoteSearch.search(notes, 'uzay'), isEmpty);
    expect(JoiNoteSearch.snippet(notes[1], 'alışveriş'), contains('alışveriş'));
  });

  test('status maps channel values; errors mean unavailable', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ch, (c) async => 'available');
    expect(await JoiService().status(), JoiStatus.available);
    messenger.setMockMethodCallHandler(ch, (c) async => 'downloadable');
    expect(await JoiService().status(), JoiStatus.downloadable);
    messenger.setMockMethodCallHandler(
      ch,
      (c) async => throw PlatformException(code: 'x'),
    );
    expect(await JoiService().status(), JoiStatus.unavailable);
    expect(await JoiService().generate('hi'), isNull);
  });

  test('Joi strings exist in tr/en/ru', () {
    for (final lang in ['tr', 'en', 'ru']) {
      L10n.setLang(lang);
      for (final k in ['joiUnavailable', 'joiIntro', 'remindShowAt']) {
        expect(L10n.current.t(k), isNot(k));
      }
    }
    L10n.setLang('tr');
  });

  test('pluggable backends: first usable wins', () async {
    final second = _FakeBackend(JoiStatus.available);
    final j = JoiService(
      backends: [_FakeBackend(JoiStatus.unavailable), second],
    );
    expect(await j.status(), JoiStatus.available);
    expect(j.activeBackend, same(second));
    expect(await j.generate('x'), 'ok');
  });

  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');

  test('online backend unavailable when not configured at build', () async {
    final o = JoiOnlineBackend(hasConsent: () => true);
    expect(o.config.configured, isFalse);
    expect(await o.status(), JoiStatus.unavailable);
    expect(
      await JoiService(
        backends: [_FakeBackend(JoiStatus.unavailable), o],
      ).status(),
      JoiStatus.unavailable,
    );
  });

  test('selection: Nano available/downloadable beats online', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          return c.method == 'status' ? 'downloadable' : 'x';
        });
    for (final nano in ['available', 'downloadable']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (c) async => nano);
      final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
      expect(await j.status(), JoiStatus.values.byName(nano));
      expect(j.activeBackend, isA<NanoBackend>());
      expect(j.isOnline, isFalse);
      expect(j.noteFeatures, isTrue);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async => 'unavailable');
    final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
    expect(await j.status(), JoiStatus.available);
    expect(j.isOnline, isTrue);
    expect(j.noteFeatures, isFalse);
  });

  test('consent gating: no network call without consent', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          return c.method == 'status' ? 'unavailable' : 'Bir filozof.';
        });
    var consent = false;
    final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => consent);
    await j.status();
    var a = await j.ask('Aristoteles kim?', lang: 'tr');
    expect(a.text, isNull);
    expect(a.error, JoiOnlineError.noConsent);
    expect(calls.where((c) => c.method == 'onlineGenerate'), isEmpty);
    consent = true;
    a = await j.ask('Aristoteles kim?', lang: 'tr');
    expect(a.text, 'Bir filozof.');
    expect(a.online, isTrue);
    final sent = calls.singleWhere((c) => c.method == 'onlineGenerate');
    expect(sent.arguments['question'], 'Aristoteles kim?');
    expect(sent.arguments['system'], isNot(contains('cihaz içi')));
  });

  test('notes are never sent online', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          return c.method == 'status' ? 'unavailable' : 'cevap';
        });
    final secret = _n('1', 'Gizli Başlık', 'banka şifresi 1234');
    final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
    await j.status();
    await j.ask('şifre nedir', lang: 'tr', notes: [secret]);
    expect(
      await j.generate(JoiService.summarizePrompt(secret, lang: 'tr')),
      isNull,
    );
    expect(
      await j.generate(JoiService.chatPrompt('x', lang: 'tr', notes: [secret])),
      isNull,
    );
    final o = j.activeBackend! as JoiOnlineBackend;
    expect(
      await o.generate(JoiService.chatPrompt('x', lang: 'tr', notes: [secret])),
      isNull,
    );
    final online = calls.where((c) => c.method == 'onlineGenerate').toList();
    expect(online, hasLength(1));
    for (final c in online) {
      final all = (c.arguments as Map).values.join('|');
      expect(all, isNot(contains('banka')));
      expect(all, isNot(contains('Gizli Başlık')));
    }
  });

  test(
    'online errors map to distinct classes with debug detail, never throw',
    () async {
      for (final (code, err) in [
        ('quota', JoiOnlineError.quota),
        ('timeout', JoiOnlineError.timeout),
        ('auth', JoiOnlineError.auth),
        ('model', JoiOnlineError.model),
        ('server', JoiOnlineError.server),
        ('offline', JoiOnlineError.offline),
        ('zzz', JoiOnlineError.failed),
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(ch, (c) async {
              if (c.method == 'status') return 'unavailable';
              throw PlatformException(code: code);
            });
        final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => true);
        await j.status();
        final a = await j.ask('soru', lang: 'tr');
        expect(a.text, isNull);
        expect(a.error, err);
        expect(a.detail, startsWith(code));
      }
    },
  );

  testWidgets('online: consent dialog, badge, no summarize chip', (
    tester,
  ) async {
    L10n.setLang('tr');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ch,
          (c) async => c.method == 'status' ? 'unavailable' : 'Filozof.',
        );
    var consent = false;
    final j = JoiService(onlineConfig: cfg, hasOnlineConsent: () => consent);
    await tester.pumpWidget(
      MaterialApp(
        theme: GizliTheme.dark(),
        home: JoiScreen(
          service: j,
          consent: () => consent,
          setConsent: (v) async => consent = v,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('notların asla gönderilmez'), findsWidgets);
    expect(find.text('Notu özetle'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('joi_input')),
      'Aristoteles kim?',
    );
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('joi_consent')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('joi_consent_allow')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(consent, isTrue);
    expect(find.text('Filozof.'), findsOneWidget);
    expect(find.byKey(const ValueKey('joi_badge_online')), findsOneWidget);
  });

  testWidgets('unsupported device: Joi box shows Turkish message', (
    tester,
  ) async {
    L10n.setLang('tr');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async => 'unavailable');
    await tester.pumpWidget(
      MaterialApp(theme: GizliTheme.dark(), home: const JoiScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Joi'), findsOneWidget);
    expect(find.byKey(const ValueKey('joi_status')), findsOneWidget);
    expect(find.textContaining('bu cihazda desteklenmiyor'), findsOneWidget);
    expect(find.byKey(const ValueKey('joi_input')), findsOneWidget);
  });
}

class _FakeBackend implements JoiBackend {
  _FakeBackend(this.s);
  final JoiStatus s;
  @override
  String get id => 'fake';
  @override
  Future<JoiStatus> status() async => s;
  @override
  Future<bool> download() async => false;
  @override
  Future<String?> generate(String prompt) async => 'ok';
}
