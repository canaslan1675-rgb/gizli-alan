import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/services/original_import.dart';
import 'package:gizlialan/services/pro_entitlement.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => Flavor.debugOverride = null);

  group('gating (ProEntitlement.deleteOriginalAfterImport)', () {
    test('default off; play never deletes even if opted in', () async {
      SharedPreferences.setMockInitialValues({
        'delete_original_after_import': true,
        'pro_stub_active': true,
      });
      final s = await SettingsService.create();
      Flavor.debugOverride = AppFlavor.play;
      expect(ProEntitlement.deleteOriginalAfterImport(s), isFalse);
    });

    test('full: needs opt-in AND Pro; lapse turns it off', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsService.create();
      Flavor.debugOverride = AppFlavor.full;
      expect(s.deleteOriginalAfterImport, isFalse);
      await s.setDeleteOriginalAfterImport(true);
      expect(ProEntitlement.deleteOriginalAfterImport(s), isFalse);
      await s.setProStubActive(true);
      expect(ProEntitlement.deleteOriginalAfterImport(s), isTrue);
      await s.setProStubActive(false);
      expect(ProEntitlement.deleteOriginalAfterImport(s), isFalse);
    });
  });

  group('OriginalImport.importAll', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('imp'));
    tearDown(() async => tmp.delete(recursive: true));

    Future<ImportSource> src(String name, int len) async {
      final f = File('${tmp.path}/$name');
      await f.writeAsBytes(List.filled(len, 7));
      return ImportSource(uri: 'content://x/$name', path: f.path, name: name);
    }

    test(
      'only verified imports are returned for deletion; caches removed',
      () async {
        final a = await src('a.jpg', 10);
        final b = await src('b.jpg', 10); // store throws
        final c = await src('c.jpg', 10); // verify fails
        final d = await src('d.jpg', 50); // too big
        var tooBig = 0;
        final stored = <String, Uint8List>{};
        final safe = await OriginalImport.importAll(
          [a, b, c, d],
          maxBytes: 20,
          onTooBig: (_) => tooBig++,
          store: (s, bytes) async {
            if (s.name == 'b.jpg') throw StateError('disk full');
            stored[s.name] = bytes;
            return s.name;
          },
          verify: (id, bytes) async => id != 'c.jpg',
        );
        expect(safe, ['content://x/a.jpg']);
        expect(tooBig, 1);
        expect(stored.containsKey('d.jpg'), isFalse);
        for (final s in [a, b, c, d]) {
          expect(File(s.path).existsSync(), isFalse, reason: s.name);
        }
      },
    );

    test('deleteOriginals with nothing verified does nothing', () async {
      final r = await OriginalImport.deleteOriginals(const []);
      expect(r.deleted, 0);
      expect(r.failed, 0);
    });
  });

  test('no broad storage permission was added', () {
    final m = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      m.contains('MANAGE_EXTERNAL_STORAGE"/>') &&
          !m.contains('MANAGE_EXTERNAL_STORAGE" tools:node="remove"'),
      isFalse,
    );
    final k = File(
      'android/app/src/main/kotlin/com/offerforge/gizlialan/ImportChannel.kt',
    ).readAsStringSync();
    expect(k.contains('createDeleteRequest'), isTrue);
    expect(k.contains('RecoverableSecurityException'), isTrue);
    expect(k.contains('DocumentsContract.deleteDocument'), isTrue);
  });
}
