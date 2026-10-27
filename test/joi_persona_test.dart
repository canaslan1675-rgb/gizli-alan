import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/widgets/joi_markdown.dart';

void main() {
  test('Istanbul date/time is computed from UTC', () {
    expect(
      JoiService.istanbulNow(DateTime.utc(2026, 10, 27, 21, 30)),
      '28 Ekim 2026 Çarşamba, 00:30 (Türkiye saati, UTC+3)',
    );
  });

  test('online prompt: persona, style rules, date, few-shot, old rules', () {
    final p = JoiService.onlineSystemPrompt(
      'tr',
      now: DateTime.utc(2026, 10, 27, 11, 20),
    );
    for (final s in [
      "Ben Joi, GizliAlan'ın asistanıyım.",
      'Asla Gemini',
      'Eylemleri sen değil uygulama',
      '27 Ekim 2026 Salı, 14:20',
      'KISA',
      'netleştirme sorusu',
      'Markdown',
      'güncel olmayabileceğini',
      'notlarına erişimin yok',
      'ÖRNEKLER',
      "Bir yapay zekâ olarak",
    ]) {
      expect(p, contains(s), reason: s);
    }
    expect(p, isNot(contains(JoiService.notesMarker)));
  });

  test('history is multi-turn, capped at 20, private turns excluded', () {
    final msgs = [
      for (var i = 0; i < 30; i++)
        JoiChatMsg(
          fromUser: i.isEven,
          text: 'm$i',
          online: i.isEven ? null : true,
          private: i == 29,
        ),
    ];
    final h = joiOnlineHistory(msgs);
    expect(h, hasLength(20));
    expect(h.last['text'], 'm28');
    expect(h.map((e) => e['role']).toSet(), {'user', 'model'});
  });

  test('markdown: bold, italic, bullets, numbers, headings; plain text', () {
    const md =
        '# Başlık\n**Malzemeler:**\n- 1 su bardağı *mercimek*\n2. Kaynat';
    final span = JoiMarkdown.spans(md, const TextStyle());
    final bold = <String>[];
    span.visitChildren((s) {
      if (s is TextSpan && s.style?.fontWeight == FontWeight.bold) {
        bold.add(s.text ?? '');
      }
      return true;
    });
    expect(bold, containsAll(['Başlık', 'Malzemeler:']));
    expect(
      JoiMarkdown.plain(md),
      'Başlık\nMalzemeler:\n  •  1 su bardağı mercimek\n  2. Kaynat',
    );
    expect(JoiMarkdown.plain('2 * 3 = 6'), '2 * 3 = 6');
  });

  testWidgets('bubble renders markdown without asterisks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: JoiMarkdown('**Merhaba** dünya'))),
    );
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('Merhaba dünya'), findsOneWidget);
  });
}
