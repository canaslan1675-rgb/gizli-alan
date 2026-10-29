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

  test('Firebase Analytics: inactive without defines, no user text', () {
    expect(Analytics.firebaseConfigured, isFalse);
    final src = File('lib/services/analytics.dart').readAsStringSync();
    expect(src, contains("'joi_question'"));
    expect(src, contains("_faEvent('pro_purchase'"));
    final joi = File('lib/services/joi_service.dart').readAsStringSync();
    // The question text is never passed to analytics.
    expect(joi, isNot(contains('logJoiQuestion(question')));
    expect(RegExp(r'logJoiQuestion\(').allMatches(joi).length, 2);
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('com.google.firebase:firebase-analytics'));
  });

  test('logJoiQuestion is a safe no-op when inactive', () async {
    await Analytics.logJoiQuestion(online: true, ok: true);
  });
}
