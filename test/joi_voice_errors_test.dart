import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every SpeechRecognizer code has a distinct Turkish text + code', () {
    L10n.setLang('tr');
    final t = L10n.current;
    final texts = <String>{};
    for (var n = 1; n <= 13; n++) {
      final s = voiceErrorText(t, 'e$n');
      expect(s, endsWith('(kod $n)'), reason: 'e$n');
      texts.add(s.replaceAll(RegExp(r' \(kod \d+\)$'), ''));
    }
    expect(texts, hasLength(13));
    expect(voiceErrorText(t, 'e7'), contains('anlaşılamadı'));
    expect(voiceErrorText(t, 'e9'), contains('mikrofon izni'));
    expect(voiceErrorText(t, 'e12'), contains('Türkçe'));
    expect(voiceErrorText(t, 'e15'), 'Konuşma tanıma hata verdi. (kod 15)');
    expect(voiceErrorText(t, 'no_service'), contains('Speech Recognition'));
    expect(voiceErrorText(t, 'weird'), contains('(kod weird)'));
  });

  testWidgets('no speech service: message + Play buttons', (tester) async {
    L10n.setLang('tr');
    const voice = MethodChannel('gizlialan/voice');
    const joi = MethodChannel('gizlialan/joi');
    final calls = <MethodCall>[];
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(joi, (c) async => 'unavailable');
    m.setMockMethodCallHandler(voice, (c) async {
      calls.add(c);
      switch (c.method) {
        case 'hasMicPermission':
          return true;
        case 'listen':
          throw PlatformException(
            code: 'no_service',
            message: 'default:e7 > no_lang:e7 > dialog:none',
          );
        default:
          return true;
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: GizliTheme.light(),
        home: JoiScreen(
          service: JoiService(),
          consent: () => true,
          isPro: () => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('joi_mic')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Speech Recognition & Synthesis'),
      findsOneWidget,
    );
    expect(find.textContaining('default:e7 > no_lang:e7'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('joi_voice_open_speech')));
    await tester.pump();
    final open = calls.lastWhere((c) => c.method == 'openStore');
    expect((open.arguments as Map)['package'], 'com.google.android.tts');
  });
}
