import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/theme.dart';

class _Commons extends CommonsSearch {
  final searched = <String>[];
  @override
  Future<List<CommonsImage>> search(String q) async {
    searched.add(q);
    return [
      CommonsImage(
        title: '$q.jpg',
        thumbUrl: 'https://x/t.jpg',
        url: 'https://x/$q.jpg',
        pageUrl: 'https://c/$q',
        author: 'a',
        license: 'CC0',
      ),
    ];
  }

  @override
  Future<Uint8List> download(CommonsImage img) async => Uint8List(4);
}

class _Platform extends JoiPlatform {
  _Platform();
  final saved = <String>[];
  @override
  Future<bool> canSaveToPictures() async => true;
  @override
  Future<String?> saveToPictures(
    Uint8List bytes, {
    required String name,
    required String mime,
    required String description,
  }) async {
    saved.add(name);
    return 'content://x';
  }
}

String kind(JoiIntent? i) => switch (i) {
  JoiImageSearch x => 'search:${x.query}',
  JoiImageNeedsSubject _ => 'needs',
  JoiImageFollowUp _ => 'followup',
  null => 'none',
  _ => 'other',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('gizlialan/joi');
  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');
  Widget app(Widget w) => MaterialApp(theme: GizliTheme.light(), home: w);

  test('detection variants (TR/EN)', () {
    final cases = {
      "Hadise'nin fotoğrafını indir": 'search:Hadise',
      'hadisenin fotoğrafını indirir misin': 'search:hadise',
      "Hadise'nin resmi": 'search:Hadise',
      'bana Hadise göster': 'search:Hadise',
      'Hadise fotosunu at': 'search:Hadise',
      "Galata Kulesi'nin görselini getir": 'search:Galata Kulesi',
      "Atatürk'ün fotoğrafını bul": 'search:Atatürk',
      'download a picture of Hadise': 'search:Hadise',
      'show me a photo of the Galata Tower': 'search:Galata Tower',
      'send me a pic of cats': 'search:cats',
      'fotoğrafı indir': 'needs',
      'fotoğrafını indir': 'needs',
      'bir resmini at': 'needs',
      'onun resmini at': 'needs',
      'fotoğrafını gönder': 'needs',
      'bir fotoğrafını indir': 'needs',
      'niye inmedi': 'followup',
      'indirdin mi': 'followup',
      'hani fotoğraf': 'followup',
      'fotoğraf nasıl çekilir': 'none',
      'bana notlarımı göster': 'none',
      'Hadise kimdir?': 'none',
    };
    cases.forEach(
      (q, want) => expect(kind(JoiIntent.parse(q)), want, reason: q),
    );
    expect(
      (JoiIntent.parse('fotoğrafı indir') as JoiImageNeedsSubject).explicit,
      isTrue,
    );
    expect(JoiIntent.hasImageWords('bir resmini at'), isTrue);
    expect(JoiIntent.hasImageWords('nasılsın'), isFalse);
  });

  test('context resolution helpers', () {
    expect(JoiIntent.topicOf('Hadise kimdir?'), 'Hadise');
    expect(JoiIntent.topicOf('Galata Kulesi nerede?'), 'Galata Kulesi');
    expect(JoiIntent.topicOf('who is Hadise?'), 'Hadise');
    expect(JoiIntent.topicOf('sen kimsin'), isNull);
    expect(
      JoiIntent.topicFromHistory([
        {'role': 'user', 'text': 'Hadise kimdir?'},
        {'role': 'model', 'text': 'Hadise Belçikalı-Türk şarkıcı.'},
      ]),
      'Hadise',
    );
    expect(
      parseImageClassifier(
        '```json\n{"is_image_request": true, "query": "Hadise"}\n```',
      ),
      (isImage: true, query: 'Hadise'),
    );
    expect(parseImageClassifier('{"is_image_request": false, "query": null}'), (
      isImage: false,
      query: null,
    ));
    expect(parseImageClassifier('bilmiyorum'), isNull);
  });

  test('hallucination guard', () {
    for (final s in [
      'Tamam, indireceğim!',
      'Biraz zaman alıyor, bekliyorum.',
      'Fotoğrafı indiriyorum.',
      'Galerine kaydettim.',
      "I'll download it now.",
    ]) {
      expect(joiClaimsAction(s), isTrue, reason: s);
    }
    for (final s in ['Hadise Türk bir şarkıcıdır.', 'Merhaba, nasılsın?']) {
      expect(joiClaimsAction(s), isFalse, reason: s);
    }
    expect(JoiService.identity('tr'), contains('Eylemleri sen değil uygulama'));
  });

  Future<(List<MethodCall>, _Commons, _Platform)> run(
    WidgetTester tester,
    List<String> msgs, {
    required Future<String> Function(MethodCall) online,
    bool pro = true,
  }) async {
    L10n.setLang('tr');
    tester.view.physicalSize = const Size(1080, 6000);
    addTearDown(tester.view.resetPhysicalSize);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          if (c.method == 'status') return 'unavailable';
          return online(c);
        });
    final commons = _Commons();
    final platform = _Platform();
    await tester.pumpWidget(
      app(
        JoiScreen(
          service: JoiService(onlineConfig: cfg, hasOnlineConsent: () => true),
          consent: () => true,
          isPro: () => pro,
          commons: commons,
          platform: platform,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final m in msgs) {
      await tester.enterText(find.byKey(const ValueKey('joi_input')), m);
      await tester.tap(find.byKey(const ValueKey('joi_send')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    return (calls, commons, platform);
  }

  bool isClassifier(MethodCall c) =>
      c.arguments is Map &&
      (c.arguments as Map)['system'] == JoiService.imageClassifierPrompt;

  testWidgets('"fotoğrafını indir" resolved from context by the model', (
    tester,
  ) async {
    final (calls, commons, platform) = await run(
      tester,
      ['Hadise kimdir?', 'fotoğrafını indir'],
      online: (c) async => isClassifier(c)
          ? '{"is_image_request": true, "query": "Hadise"}'
          : 'Hadise Türk-Belçikalı bir şarkıcıdır.',
    );
    expect(calls.where(isClassifier), hasLength(1));
    final q =
        (calls.where(isClassifier).single.arguments as Map)['question']
            as String;
    expect(q, contains('Hadise kimdir?'));
    expect(commons.searched.first, 'Hadise');
    expect(find.byKey(const ValueKey('joi_img_save_first')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('joi_img_save_first')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(platform.saved, hasLength(1));
    expect(find.textContaining('Galeriye kaydedildi ✓'), findsWidgets);
  });

  testWidgets('"bir resmini at" works offline-ish via the local fallback', (
    tester,
  ) async {
    final (_, commons, _) = await run(tester, [
      'Galata Kulesi nerede?',
      'bir resmini at',
    ], online: (c) async => isClassifier(c) ? 'garbage' : 'İstanbul’da.');
    expect(commons.searched.first, 'Galata Kulesi');
  });

  testWidgets('unknown subject: asks, then uses the next message', (
    tester,
  ) async {
    final (_, commons, _) = await run(tester, [
      'fotoğrafı indir',
    ], online: (c) async => '{"is_image_request": true, "query": null}');
    expect(find.textContaining('Neyin fotoğrafını indireyim?'), findsOneWidget);
    expect(commons.searched, isEmpty);
    await tester.enterText(find.byKey(const ValueKey('joi_input')), 'Hadise');
    await tester.tap(find.byKey(const ValueKey('joi_send')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(commons.searched.first, 'Hadise');
  });

  testWidgets('"niye inmedi" repeats the last image request', (tester) async {
    final (calls, commons, _) = await run(tester, [
      "Hadise'nin fotoğrafını indir",
      'niye inmedi',
    ], online: (c) async => 'x');
    expect(commons.searched.where((s) => s == 'Hadise'), hasLength(2));
    expect(calls.where((c) => c.method == 'onlineGenerate'), isEmpty);
  });

  testWidgets('hallucinated "indireceğim" is replaced + image flow runs', (
    tester,
  ) async {
    final (_, commons, _) = await run(
      tester,
      ['Hadise kimdir?', 'onun güzel bir fotoğrafı olsa keşke'],
      online: (c) async => isClassifier(c)
          ? '{"is_image_request": false, "query": null}'
          : (c.arguments as Map)['question'].toString().contains('keşke')
          ? 'Tamam, indireceğim, biraz zaman alıyor.'
          : 'Hadise bir şarkıcıdır.',
    );
    expect(find.textContaining('indireceğim'), findsNothing);
    expect(find.textContaining('Ben kendim bir şey indiremem'), findsOneWidget);
    expect(commons.searched.first, 'Hadise');
  });

  testWidgets('free user: image variants upsell, no search', (tester) async {
    final (_, commons, _) = await run(
      tester,
      ['bir resmini at'],
      online: (c) async => 'x',
      pro: false,
    );
    expect(commons.searched, isEmpty);
  });
}
