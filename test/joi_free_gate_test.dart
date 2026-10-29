import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/joi_quota.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/theme.dart';

/// 0.6.4: free users get plain Q&A (10/day); only notes search/summary is
/// Pro. Regression for 0.6.3, where every question showed the notes upsell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  L10n.setLang('tr');
  const ch = MethodChannel('gizlialan/joi');
  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');
  Widget app(Widget w) => MaterialApp(theme: GizliTheme.light(), home: w);

  late List<MethodCall> calls;
  void mockOnline() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          if (c.method == 'status') return 'unavailable'; // no Gemini Nano
          if (c.method == 'onlineGenerate') return 'Atinalı bir filozof.';
          return null;
        });
  }

  int online() => calls.where((c) => c.method == 'onlineGenerate').length;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, null);
  });

  Future<void> send(WidgetTester tester, String q) async {
    await tester.enterText(find.byKey(const ValueKey('joi_input')), q);
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<JoiDailyQuota> pumpFree(
    WidgetTester tester, {
    JoiOnlineConfig config = cfg,
  }) async {
    L10n.setLang('tr');
    final q = JoiDailyQuota.memory();
    await tester.pumpWidget(
      app(
        JoiScreen(
          service: JoiService(
            onlineConfig: config,
            hasOnlineConsent: () => true,
          ),
          consent: () => true,
          isPro: () => false,
          quota: q,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return q;
  }

  final proNotesLine = L10n.current(
    'joiProOnly',
  ).replaceAll('{what}', L10n.current('joiProNotes'));

  group('notes-request detection', () {
    test('plain questions are not notes requests', () {
      for (final q in [
        'Sokrates kimdir?',
        'Bugün hava nasıl?',
        'Bana bir fıkra anlat',
        'Not almak neden faydalı?',
        'What is the capital of France?',
      ]) {
        expect(JoiIntent.isNotesRequest(q), isFalse, reason: q);
      }
    });
    test('explicit notes search / summary', () {
      for (final q in [
        'Notlarımda Sokrates ara',
        'notlarımı özetle',
        'Bunu özetle',
        'Özetler misin',
        'Search my notes for Paris',
        'Summarize this',
      ]) {
        expect(JoiIntent.isNotesRequest(q), isTrue, reason: q);
      }
    });
  });

  testWidgets('free user: normal question goes to chat, not Pro', (
    tester,
  ) async {
    mockOnline();
    final q = await pumpFree(tester);
    await send(tester, 'Sokrates kimdir?');
    expect(find.byKey(const ValueKey('pro_required')), findsNothing);
    expect(find.text(proNotesLine), findsNothing);
    expect(find.textContaining('Atinalı bir filozof.'), findsWidgets);
    expect(online(), 1);
    expect(q.used, 1);
  });

  for (final ask in ['Notlarımda Sokrates ara', 'Notlarımı özetle']) {
    testWidgets('free user: "$ask" -> Pro message, nothing sent', (
      tester,
    ) async {
      mockOnline();
      final q = await pumpFree(tester);
      await send(tester, ask);
      expect(find.byKey(const ValueKey('pro_required')), findsOneWidget);
      expect(find.text(proNotesLine), findsOneWidget);
      expect(online(), 0);
      expect(q.used, 0);
    });
  }

  testWidgets('free user: 10 questions answered, 11th -> Pro prompt', (
    tester,
  ) async {
    mockOnline();
    final q = await pumpFree(tester);
    for (var i = 1; i <= 10; i++) {
      await send(tester, 'Soru $i: Sokrates kimdir?');
      expect(find.byKey(const ValueKey('pro_required')), findsNothing);
      expect(q.used, i);
    }
    expect(online(), 10);
    await send(tester, 'Soru 11: Platon kimdir?');
    expect(find.byKey(const ValueKey('pro_required')), findsOneWidget);
    expect(find.text(L10n.current('joiDailyLimitReached')), findsOneWidget);
    expect(online(), 10);
    expect(q.used, 10);
  });

  testWidgets('free user, no AI backend: honest message, no notes upsell', (
    tester,
  ) async {
    mockOnline();
    await pumpFree(
      tester,
      config: const JoiOnlineConfig(apiKey: '', appId: '', projectId: ''),
    );
    await send(tester, 'Sokrates kimdir?');
    expect(find.text(proNotesLine), findsNothing);
    expect(find.byKey(const ValueKey('pro_required')), findsNothing);
    expect(find.text(L10n.current('joiChatUnavailable')), findsOneWidget);
    expect(online(), 0);
  });
}
