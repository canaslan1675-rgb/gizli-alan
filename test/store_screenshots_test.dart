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
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

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
  final outRoot = Directory('docs/store/screenshots');
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
    SharedPreferences.setMockInitialValues({'lang': lang});
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
          baseDirProvider: () async => tmp,
        ),
      ),
    );
    await settle(tester, 3);
    return (tester.state<GizliAlanAppState>(find.byType(GizliAlanApp)), auth);
  }

  Future<void> capture(WidgetTester tester, String lang, String name) async {
    final flavor = Flavor.current.name;
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
      final dir = Directory('${outRoot.path}/$flavor/$lang')
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

  for (final flavor in AppFlavor.values) {
    for (final lang in ['tr', 'en']) {
      group('store screenshots ${flavor.name}/$lang', skip: !_enabled, () {
        setUp(() => Flavor.debugOverride = flavor);

        testWidgets('01 calculator with info dialog', (tester) async {
          await start(tester, lang);
          for (final k in ['1', '2', '4', '8', '×', '3', '=']) {
            await tester.tap(find.byKey(ValueKey('calc_$k')));
            await tester.pump();
          }
          await tester.tap(find.byIcon(Icons.info_outline));
          await settle(tester, 2);
          await capture(tester, lang, '01_calculator_info');
        });

        testWidgets('02 onboarding calculator disclosure', (tester) async {
          await start(tester, lang, onboarded: false);
          await tester.tap(find.byKey(const ValueKey('own_device')));
          await tester.pump();
          await tester.tap(find.text(L10n.current('continue')).first);
          await settle(tester, 2);
          await capture(tester, lang, '02_onboarding_disclosure');
        });

        testWidgets('03 vault home', (tester) async {
          final (app, _) = await start(tester, lang);
          await openVault(tester, app);
          await capture(tester, lang, '03_vault_home');
        });

        testWidgets('04 gallery', (tester) async {
          final (app, _) = await start(tester, lang);
          await openVault(tester, app);
          await tester.runAsync(() async {
            for (var i = 0; i < 12; i++) {
              await app.session!.gallery.add(
                name: 'demo_$i.png',
                bytes: await _patternPng(i),
                mime: 'image/png',
              );
            }
          });
          await tester.tap(find.text(L10n.current('gallery')).first);
          await settle(tester, 12);
          await capture(tester, lang, '04_gallery');
        });

        testWidgets('05 notes', (tester) async {
          final (app, _) = await start(tester, lang);
          await openVault(tester, app);
          await tester.runAsync(() async {
            for (final (title, body) in _notes[lang]!.reversed) {
              await app.session!.notes.create(title: title, body: body);
            }
          });
          await tester.tap(find.text(L10n.current('notes')).first);
          await settle(tester);
          await capture(tester, lang, '05_notes');
        });

        testWidgets('06 settings', (tester) async {
          final (app, _) = await start(tester, lang);
          await openVault(tester, app);
          await tester.tap(find.text(L10n.current('settings')).first);
          await settle(tester);
          await capture(tester, lang, '06_settings');
        });
      });
    }
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
