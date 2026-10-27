// Store screenshot generator (issue #6). SKIPPED by default so it never
// affects `flutter test`. Generate with:
//
//   tool/gen_store_screenshots.sh
//   # = flutter test test/store_screenshots_test.dart \
//   #     --dart-define=STORE_SCREENSHOTS=true
//
// It pumps the REAL app screens (GizliAlanApp) with fabricated demo content
// (generated pattern images, neutral fake notes) in a widget test, renders
// them through a RepaintBoundary and writes 1080×1920 RGB PNGs (no alpha) to
// docs/store/screenshots/{play,full}/{tr,en}/ (one set per build flavor,
// issue #11; the Play listing uses play/). No emulator, no device, and no change to
// FLAG_SECURE (which stays unconditional in MainActivity).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:gizlialan/screens/joi_screen.dart';
import 'package:gizlialan/screens/second_phone_screen.dart';
import 'package:gizlialan/services/joi_service.dart';
import 'package:gizlialan/services/joi_tools.dart';
import 'package:gizlialan/services/joi_quota.dart';
import 'second_phone_flow_test.dart' show FakeSecondPhone;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool _enabled = bool.fromEnvironment('STORE_SHOTS_062');

/// Output size required by the owner: exactly 1080×1920.
const int _w = 1080;
const int _h = 1920;
const double _dpr = 2.625; // → 411.4 × 731.4 logical px (typical phone)

/// Pretends a fingerprint is enrolled so Settings shows biometrics as on.
/// Never actually authenticates.
class _DemoBiometrics extends BiometricService {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate(String reason) async => false;
}

/// Neutral fake notes (no personal data).
const _notes = {
  'tr': [
    ('Alışveriş listesi', 'Süt, ekmek, domates, zeytinyağı'),
    ('Kitap önerileri', 'Bilim kurgu ve tarih kitapları'),
    ('Tatil planı', 'Rota, otel ve müze saatleri'),
    ('Spor programı', 'Pazartesi koşu, çarşamba yüzme'),
  ],
  'en': [
    ('Shopping list', 'Milk, bread, tomatoes, olive oil'),
    ('Book ideas', 'Science fiction and history'),
    ('Trip plan', 'Route, hotel and museum hours'),
    ('Workout plan', 'Monday run, Wednesday swim'),
  ],
};

void main() {
  late Directory tmp;
  final outRoot = Directory('/workspace/gizlialan-store-0.6.2/raw');
  final boundaryKey = GlobalKey();

  setUpAll(() async {
    if (!_enabled) return;
    await initializeDateFormatting();
    // Real fonts instead of the test "Ahem" boxes.
    final fontDir =
        '${Platform.environment['FLUTTER_ROOT'] ?? '/workspace/tools/flutter'}'
        '/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final f in ['Light', 'Medium', 'Bold', 'Thin']) {
      roboto.addFont(_fontBytes('$fontDir/Roboto-$f.ttf'));
    }
    // Roboto Regular + the "ⓘ" glyph (the test engine has no system font
    // fallback; phones render it with Noto). See
    // tool/patch_roboto_circled_i.py.
    roboto.addFont(
      _fontBytes('test/fixtures/fonts/Roboto-Regular-circled-i.ttf'),
    );
    await roboto.load();
    // Android's "monospace" (vault home signature); DejaVu Sans Mono has the
    // "●" glyph, Roboto Mono (Flutter cache) is the fallback.
    final monoPath = [
      '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
      '${Platform.environment['FLUTTER_ROOT'] ?? '/workspace/tools/flutter'}'
          '/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/'
          'Roboto_Mono/RobotoMono-Regular.ttf',
    ].where((p) => File(p).existsSync());
    if (monoPath.isNotEmpty) {
      await (FontLoader(
        'monospace',
      )..addFont(_fontBytes(monoPath.first))).load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(_fontBytes('$fontDir/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_shots');
  });

  tearDown(() async {
    Flavor.debugOverride = null;
    L10n.setLang('tr');
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1)); // finish animations
  }

  Future<(GizliAlanAppState, AuthService)> start(
    WidgetTester tester,
    String lang, {
    bool onboarded = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'lang': lang,
      'free_banner_dismissed': true,
    });
    final settings = await SettingsService.create();
    await settings.setBiometricEnabled(true);
    final auth = AuthService(storage: MemorySecureKv(), pbkdf2Iterations: 1000);
    if (onboarded) {
      await tester.runAsync(() => auth.setPin('2580'));
    }
    tester.view.physicalSize = const Size(_w + 0.0, _h + 0.0);
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: _DemoBiometrics(),
          secondPhone: FakeSecondPhone(),
          baseDirProvider: () async => tmp,
        ),
      ),
    );
    await settle(tester, 3);
    return (tester.state<GizliAlanAppState>(find.byType(GizliAlanApp)), auth);
  }

  Future<void> capture(WidgetTester tester, String lang, String name) async {
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _dpr);
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(image.width, _w);
      expect(image.height, _h);
      final dir = Directory('${outRoot.path}/$lang')
        ..createSync(recursive: true);
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(encodeRgbPng(rgba, image.width, image.height));
      image.dispose();
    });
  }

  Future<void> openVault(WidgetTester tester, GizliAlanAppState app) async {
    await tester.runAsync(() => app.enterVault(VaultSpace.real));
    await settle(tester);
  }

  Future<void> pushOn(WidgetTester tester, Widget w) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
    nav.push(MaterialPageRoute<void>(builder: (_) => w));
    await settle(tester, 10);
  }

  const cfg = JoiOnlineConfig(apiKey: 'k', appId: 'a', projectId: 'p');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('gizlialan/joi'),
          (c) async => c.method == 'status' ? 'unavailable' : 'x',
        );
  });

  for (final lang in ['tr', 'en']) {
    group('0.6.2 store $lang', skip: !_enabled, () {
      setUp(() => Flavor.debugOverride = AppFlavor.full);

      testWidgets('joi pro chat', (tester) async {
        final (app, _) = await start(tester, lang);
        await openVault(tester, app);
        final chats = <String, List<JoiChatMsg>>{
          'tr': [
            JoiChatMsg(
              fromUser: true,
              text: "Bugün biraz yorgunum, akşam ne yapsam?",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Yorgunluğa iyi gelecek üç fikrim var:\n\n1. **20 dakikalık yürüyüş** — hava alırsın, kafan boşalır.\n2. Sıcak bir duş ve sevdiğin bir dizi.\n3. Telefonu kenara bırakıp kitaba dönmek.\n\nİstersen sana kısa bir akşam planı da yazarım.",
              online: true,
            ),
            JoiChatMsg(
              fromUser: true,
              text: "Not defterime yarınki toplantı için 3 madde yaz",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Yazdım: **Yarınki toplantı** notu kasanda şifreli duruyor.",
              online: true,
              noteId: 'n1',
            ),
          ],
          'en': [
            JoiChatMsg(
              fromUser: true,
              text: "I'm a bit tired today, what should I do tonight?",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Three ideas that help when you're tired:\n\n1. **A 20-minute walk** — fresh air clears your head.\n2. A warm shower and a show you love.\n3. Put the phone down and pick up a book.\n\nWant me to write you a short evening plan?",
              online: true,
            ),
            JoiChatMsg(
              fromUser: true,
              text: "Write 3 points for tomorrow's meeting in my notes",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Done: the **Tomorrow's meeting** note is saved encrypted in your vault.",
              online: true,
              noteId: 'n1',
            ),
          ],
        };
        await tester.runAsync(() => app.session!.joiChat.save(chats[lang]!));
        await pushOn(
          tester,
          JoiScreen(
            service: JoiService(
              onlineConfig: cfg,
              hasOnlineConsent: () => true,
            ),
            consent: () => true,
            isPro: () => true,
            chatStore: app.session!.joiChat,
          ),
        );
        await capture(tester, lang, 'raw_joi_pro');
      });

      testWidgets('joi free counter', (tester) async {
        final (app, _) = await start(tester, lang);
        await openVault(tester, app);
        final q = JoiDailyQuota.memory();
        for (var i = 0; i < 3; i++) {
          await q.consume();
        }
        await pushOn(
          tester,
          JoiScreen(
            service: JoiService(
              onlineConfig: cfg,
              hasOnlineConsent: () => true,
            ),
            consent: () => true,
            isPro: () => false,
            quota: q,
          ),
        );
        final free = <String, List<JoiChatMsg>>{
          'tr': [
            JoiChatMsg(
              fromUser: true,
              text: "Kahve mi çay mı daha az kafein içerir?",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Genelde **çay**: bir fincan siyah çayda yaklaşık 40–50 mg, filtre kahvede ise 80–100 mg kafein olur. Yeşil çay daha da azdır.",
              online: true,
            ),
          ],
          'en': [
            JoiChatMsg(
              fromUser: true,
              text: "Which has less caffeine, coffee or tea?",
            ),
            JoiChatMsg(
              fromUser: false,
              text:
                  "Usually **tea**: a cup of black tea has about 40–50 mg, filter coffee about 80–100 mg. Green tea has even less.",
              online: true,
            ),
          ],
        };
        // Free chat is in-memory only: type the question via the UI is not
        // possible offline, so show the empty free screen with the counter.
        expect(free, isNotEmpty);
        await capture(tester, lang, 'raw_joi_free');
      });

      testWidgets('vault home full', (tester) async {
        final (app, _) = await start(tester, lang);
        await openVault(tester, app);
        await capture(tester, lang, 'raw_vault_home');
      });

      testWidgets('second phone', (tester) async {
        final (app, _) = await start(tester, lang);
        await openVault(tester, app);
        await pushOn(tester, const SecondPhoneScreen());
        await capture(tester, lang, 'raw_second_phone');
      });
    });
  }
}

Future<ByteData> _fontBytes(String path) async =>
    ByteData.sublistView(File(path).readAsBytesSync());

/// A generated abstract placeholder "photo" (gradient + circles), PNG bytes.
Future<Uint8List> _patternPng(int seed) async {
  const size = 480.0;
  final rnd = math.Random(seed * 7919 + 17);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final hue = (seed * 37) % 360.0;
  final c1 = HSVColor.fromAHSV(1, hue, 0.55, 0.85).toColor();
  final c2 = HSVColor.fromAHSV(1, (hue + 60) % 360, 0.65, 0.45).toColor();
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(size, size), [
        c1,
        c2,
      ]),
  );
  for (var i = 0; i < 6; i++) {
    canvas.drawCircle(
      Offset(rnd.nextDouble() * size, rnd.nextDouble() * size),
      30 + rnd.nextDouble() * 110,
      Paint()
        ..color = Colors.white.withValues(
          alpha: 0.08 + rnd.nextDouble() * 0.15,
        ),
    );
  }
  final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}

/// Minimal PNG encoder: 8-bit RGB (colour type 2, no alpha). Pixels are
/// composited over black, which is a no-op for the opaque app frames.
Uint8List encodeRgbPng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder(copy: false);
  final row = Uint8List(1 + width * 3);
  for (var y = 0; y < height; y++) {
    row[0] = 0; // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final a = rgba[i + 3];
      for (var c = 0; c < 3; c++) {
        row[1 + x * 3 + c] = a == 255 ? rgba[i + c] : (rgba[i + c] * a) ~/ 255;
      }
    }
    raw.add(Uint8List.fromList(row));
  }
  final out = BytesBuilder();
  out.add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length);
    out.add(len.buffer.asUint8List());
    final td = [...type.codeUnits, ...data];
    out.add(td);
    final crc = ByteData(4)..setUint32(0, _crc32(td));
    out.add(crc.buffer.asUint8List());
  }

  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // colour type RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes()));
  chunk('IEND', const []);
  return out.takeBytes();
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
