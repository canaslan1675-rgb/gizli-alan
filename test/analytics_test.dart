import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/analytics.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SDKs are inactive without injected keys (tests / local builds)', () {
    expect(Analytics.appMetricaConfigured, isFalse);
    expect(Analytics.tiktokConfigured, isFalse);
  });

  test('analytics toggle defaults on, persists and survives reset', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsService.create();
    expect(s.analyticsEnabled, isTrue);
    await s.setAnalyticsEnabled(false);
    expect(s.analyticsEnabled, isFalse);
    await s.resetAll();
    expect(s.analyticsEnabled, isFalse);
  });

  test('analytics source: location off, only Pro purchase event', () {
    final src = File('lib/services/analytics.dart').readAsStringSync();
    expect(src, contains('locationTracking: false'));
    expect(RegExp(r"reportEvent\w*\('").allMatches(src).length, 1);
    expect(src, contains("'pro_purchase'"));
    expect(src, isNot(contains('setUserProfileID')));
    expect(src, isNot(contains('identify(')));
    // Keys come only from --dart-define.
    expect(src, contains("String.fromEnvironment('APPMETRICA_API_KEY')"));
    expect(src, contains("String.fromEnvironment('TIKTOK_APP_SECRET')"));
  });
}
