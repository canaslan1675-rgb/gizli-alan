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

  test('close(quiet) hides first, then pause is refused -> freeze', () async {
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
    // Hiding always comes first: quiet mode alone leaves greyed icons.
    expect(calls.map((c) => c.method), ['freeze', 'setQuietMode']);
    expect(calls.last.arguments, {'enabled': true});
  });

  test('close(freeze) hides only; failure -> null', () async {
    mock((c) => {'status': 'frozen'});
    expect(
      await SecondPhoneService().close(SecondPhoneCloseMode.freeze),
      SecondPhoneCloseMode.freeze,
    );
    expect(calls.map((c) => c.method), ['freeze']);
    mock((c) => {'status': 'denied'});
    expect(
      await SecondPhoneService().close(SecondPhoneCloseMode.freeze),
      isNull,
    );
  });

  test('close(quiet) when permitted; open unpauses, waits, unhides', () async {
    var quiet = true;
    var statusCalls = 0;
    mock((c) {
      switch (c.method) {
        case 'freeze':
          return {'status': 'frozen'};
        case 'setQuietMode':
          return {'status': 'ok'};
        case 'status':
          // Android reports the profile running again on the 2nd poll.
          if (++statusCalls >= 2) quiet = false;
          return {'exists': true, 'linked': true, 'quietMode': quiet};
        case 'unfreeze':
          return {'status': 'unfrozen', 'count': 2};
      }
      return null;
    });
    final sp = SecondPhoneService();
    expect(
      await sp.close(SecondPhoneCloseMode.quiet),
      SecondPhoneCloseMode.quiet,
    );
    calls.clear();
    expect(
      await sp.open(SecondPhoneCloseMode.quiet, pollDelay: Duration.zero),
      isTrue,
    );
    expect(calls.map((c) => c.method), [
      'setQuietMode',
      'status',
      'status',
      'unfreeze',
    ]);
    expect(calls.first.arguments, {'enabled': false});
  });

  test('open: partial unhide counts as opened, errors do not', () async {
    mock((c) => {'status': 'partial', 'count': 1});
    expect(await SecondPhoneService().open(SecondPhoneCloseMode.freeze), true);
    mock((c) => {'status': 'denied'});
    expect(await SecondPhoneService().open(SecondPhoneCloseMode.freeze), false);
    expect(SecondPhoneService.isUnfrozen('unfrozen'), isTrue);
    expect(SecondPhoneService.isUnfrozen('no_profile'), isFalse);
  });

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

  test('settings: close mode defaults to quiet (#45) and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.quiet);
    expect(s.secondPhoneClosedBy, isNull);
    await s.setSecondPhoneCloseMode(SecondPhoneCloseMode.quiet);
    await s.setSecondPhoneClosedBy(SecondPhoneCloseMode.freeze);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.quiet);
    expect(s.secondPhoneClosedBy, SecondPhoneCloseMode.freeze);
    await s.setSecondPhoneClosedBy(null);
    expect(s.secondPhoneClosedBy, isNull);
    expect(SecondPhoneCloseMode.parse('bogus'), SecondPhoneCloseMode.quiet);
  });

  test('settings: "hide work apps while locked" defaults on (#30)', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    expect(s.hideWorkAppsWhenLocked, isTrue);
    expect(s.pauseWorkProfileWhenLocked, isTrue); // default since #45
    await s.setPauseWorkProfileWhenLocked(false);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.freeze);

    await s.setPauseWorkProfileWhenLocked(true);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.quiet);
    expect(s.hideWorkAppsWhenLocked, isTrue); // pause implies hide

    await s.setHideWorkAppsWhenLocked(false);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.off);
    expect(s.pauseWorkProfileWhenLocked, isFalse);
    await s.setPauseWorkProfileWhenLocked(true); // ignored while off
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.off);

    await s.setHideWorkAppsWhenLocked(true);
    expect(s.secondPhoneCloseMode, SecondPhoneCloseMode.freeze);
  });

  test('settings: legacy "off" choice is respected as toggle off', () async {
    SharedPreferences.setMockInitialValues({'second_phone_close': 'off'});
    final s = await SettingsService.create();
    expect(s.hideWorkAppsWhenLocked, isFalse);
  });

  test('settings: reset keeps the "apps hidden by us" marker', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    await s.setHideWorkAppsWhenLocked(false);
    await s.setSecondPhoneClosedBy(SecondPhoneCloseMode.freeze);
    await s.resetAll();
    expect(s.secondPhoneClosedBy, SecondPhoneCloseMode.freeze);
    expect(s.hideWorkAppsWhenLocked, isTrue); // settings back to defaults
  });
}
