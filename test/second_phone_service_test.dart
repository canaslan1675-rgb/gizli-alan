import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/second_phone_service.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('gizlialan/second_phone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void mock(Object? Function(MethodCall c) handler) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return handler(c);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('availability', () {
    SecondPhoneAvailability av({
      bool feature = true,
      bool allowed = true,
      bool exists = false,
      bool linked = false,
      bool xiaomi = false,
    }) => SecondPhoneStatus(
      featureSupported: feature,
      provisioningAllowed: allowed,
      exists: exists,
      linked: linked,
      isXiaomi: xiaomi,
    ).availability;

    test('existing linked profile is ready, unlinked is flagged', () {
      expect(av(exists: true, linked: true), SecondPhoneAvailability.ready);
      expect(av(exists: true), SecondPhoneAvailability.unlinked);
    });

    test('setup available, with a Xiaomi warning on MIUI/HyperOS', () {
      expect(av(), SecondPhoneAvailability.canSetUp);
      expect(av(xiaomi: true), SecondPhoneAvailability.canSetUpXiaomiRisk);
    });

    test('blocked / unsupported cases', () {
      expect(av(allowed: false), SecondPhoneAvailability.notAllowed);
      expect(
        av(allowed: false, xiaomi: true),
        SecondPhoneAvailability.blockedXiaomi,
      );
      expect(
        av(feature: false, allowed: false),
        SecondPhoneAvailability.unsupported,
      );
      expect(
        av(feature: false, allowed: false, xiaomi: true),
        SecondPhoneAvailability.blockedXiaomi,
      );
    });

    test('Private Space fallback hint only on Android 15+', () {
      expect(const SecondPhoneStatus(sdkInt: 34).privateSpaceAvailable, false);
      expect(const SecondPhoneStatus(sdkInt: 35).privateSpaceAvailable, true);
    });
  });

  test('status() parses the platform map', () async {
    mock(
      (_) => {
        'featureSupported': true,
        'provisioningAllowed': false,
        'exists': true,
        'linked': true,
        'quietMode': true,
        'manufacturer': 'Xiaomi',
        'brand': 'Redmi',
        'isXiaomi': true,
        'sdkInt': 34,
      },
    );
    final st = await SecondPhoneService().status();
    expect(st.availability, SecondPhoneAvailability.ready);
    expect(st.quietMode, isTrue);
    expect(st.isXiaomi, isTrue);
    expect(st.manufacturer, 'Xiaomi');
  });

  test('no platform implementation → unavailable, never throws', () async {
    final sp = SecondPhoneService(
      channel: const MethodChannel('gizlialan/nothing_here'),
    );
    expect(
      (await sp.status()).availability,
      SecondPhoneAvailability.unsupported,
    );
    expect(await sp.listApps(), isEmpty);
    expect(await sp.provision(), 'unavailable');
    expect(await sp.close(SecondPhoneCloseMode.freeze), isNull);
  });

  test('close(quiet) falls back to freezing when Android refuses', () async {
    mock((c) {
      switch (c.method) {
        case 'setQuietMode':
          return {'status': 'not_permitted'};
        case 'freeze':
          return {'status': 'frozen', 'count': 3};
      }
      return null;
    });
    final applied = await SecondPhoneService().close(
      SecondPhoneCloseMode.quiet,
    );
    expect(applied, SecondPhoneCloseMode.freeze);
    expect(calls.map((c) => c.method), ['setQuietMode', 'freeze']);
    expect(calls.first.arguments, {'enabled': true});
  });

  test(
    'close(quiet) uses quiet mode when permitted; open reverses it',
    () async {
      mock((c) => {'status': 'ok'});
      final sp = SecondPhoneService();
      expect(
        await sp.close(SecondPhoneCloseMode.quiet),
        SecondPhoneCloseMode.quiet,
      );
      expect(await sp.open(SecondPhoneCloseMode.quiet), isTrue);
      expect(calls.last.arguments, {'enabled': false});
    },
  );

  test('close(off) does nothing', () async {
    mock((c) => {'status': 'frozen'});
    expect(await SecondPhoneService().close(SecondPhoneCloseMode.off), isNull);
    expect(calls, isEmpty);
  });

  test('clone and listApps map arguments and results', () async {
    mock((c) {
      if (c.method == 'listApps') {
        return [
          {'label': 'Chat', 'package': 'com.example.chat', 'activity': 'A'},
        ];
      }
      return {'status': 'store_opened'};
    });
    final sp = SecondPhoneService();
    final apps = await sp.listApps();
    expect(apps.single.packageName, 'com.example.chat');
    final r = await sp.clone(
      const CloneCandidate(label: 'X', packageName: 'com.x', isSystem: false),
    );
    expect(r, 'store_opened');
    expect(calls.last.arguments, {
      'package': 'com.x',
      'isSystem': false,
      'openStoreFallback': true,
    });
  });

  test('settings: close mode defaults to freeze and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.freeze);
    expect(s.secondPhoneClosedBy, isNull);
    await s.setSecondPhoneCloseMode(SecondPhoneCloseMode.quiet);
    await s.setSecondPhoneClosedBy(SecondPhoneCloseMode.freeze);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.quiet);
    expect(s.secondPhoneClosedBy, SecondPhoneCloseMode.freeze);
    await s.setSecondPhoneClosedBy(null);
    expect(s.secondPhoneClosedBy, isNull);
    expect(SecondPhoneCloseMode.parse('bogus'), SecondPhoneCloseMode.freeze);
  });
}
