import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/second_phone_service.dart';
import 'package:gizlialan/services/work_settings_intents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkSettingsIntents.candidates', () {
    test('generic phone: profile settings → launcher → sync → settings', () {
      final c = WorkSettingsIntents.candidates(xiaomi: false);
      expect(c.map((e) => e.id), [
        'managed_profile',
        'launcher_default',
        'sync',
        'settings',
      ]);
      expect(c.first.action, 'android.settings.MANAGED_PROFILE_SETTINGS');
      expect(c[1].action, 'android.intent.action.APPLICATION_PREFERENCES');
      expect(c[1].package, '@home');
      expect(c[2].action, 'android.settings.SYNC_SETTINGS');
      expect(c.last.action, 'android.settings.SETTINGS');
    });

    test(
      'Xiaomi/POCO: MIUI launcher settings right after profile settings',
      () {
        final c = WorkSettingsIntents.candidates(xiaomi: true);
        expect(c.map((e) => e.id), [
          'managed_profile',
          'launcher_miui',
          'launcher_miui_prefs',
          'launcher_default',
          'sync',
          'settings',
        ]);
        expect(c[1].component, startsWith('com.miui.home/'));
        expect(c[2].package, 'com.miui.home');
      },
    );

    test('every candidate has an action or a component; ids unique', () {
      for (final x in [true, false]) {
        final c = WorkSettingsIntents.candidates(xiaomi: x);
        expect(c.every((e) => e.action != null || e.component != null), isTrue);
        expect(c.map((e) => e.id).toSet().length, c.length);
      }
    });
  });

  group('SecondPhoneService.openWorkSettings', () {
    const channel = MethodChannel('gizlialan/second_phone');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Future<(String, List<Object?>)> run({
      required bool xiaomi,
      Object? reply,
    }) async {
      List<Object?> sent = const [];
      messenger.setMockMethodCallHandler(channel, (c) async {
        if (c.method == 'status') return {'isXiaomi': xiaomi};
        if (c.method == 'openSystemScreen') {
          sent = (c.arguments as Map)['candidates'] as List<Object?>;
          return reply;
        }
        return null;
      });
      final r = await SecondPhoneService().openWorkSettings();
      return (r, sent);
    }

    test('passes the ordered list and returns the opened id', () async {
      final (r, sent) = await run(xiaomi: true, reply: {'opened': 'sync'});
      expect(r, 'sync');
      expect(
        sent.map((e) => (e as Map)['id']),
        WorkSettingsIntents.candidates(xiaomi: true).map((e) => e.id),
      );
    });

    test('nothing opened / channel missing → none', () async {
      expect((await run(xiaomi: false, reply: {'opened': 'none'})).$1, 'none');
      expect((await run(xiaomi: false, reply: null)).$1, 'none');
    });
  });
}
