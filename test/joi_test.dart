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
    expect(p, contains('Turkish'));
    expect(JoiService.systemPrompt('en'), contains('English'));
    final c = JoiService.chatPrompt('Aristoteles kim?', lang: 'tr');
    expect(c, contains('User: Aristoteles kim?'));
    expect(c, isNot(contains('(use them only if relevant)')));
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

  test(
    'pluggable backends: first usable wins; reserved slot is a stub',
    () async {
      expect(await const JoiReservedBackend().status(), JoiStatus.unavailable);
      final second = _FakeBackend(JoiStatus.available);
      final j = JoiService(
        backends: [_FakeBackend(JoiStatus.unavailable), second],
      );
      expect(await j.status(), JoiStatus.available);
      expect(j.activeBackend, same(second));
      expect(await j.generate('x'), 'ok');
      expect(
        await JoiService(backends: [const JoiReservedBackend()]).status(),
        JoiStatus.unavailable,
      );
    },
  );

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
