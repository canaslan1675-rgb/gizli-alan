import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/app.dart';
import 'package:gizlialan/app_version.dart';
import 'package:gizlialan/flavor.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/l10n/tr.dart';
import 'package:gizlialan/screens/help_screen.dart';
import 'package:gizlialan/screens/settings_screen.dart';
import 'package:gizlialan/services/app_actions.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/biometric_service.dart';
import 'package:gizlialan/services/privacy_link.dart';
import 'package:gizlialan/services/secure_kv.dart';
import 'package:gizlialan/services/settings_service.dart';
import 'package:gizlialan/services/vault_space.dart';
import 'package:gizlialan/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v0.5.1 tester feedback: Share / Rate / Feedback / Help rows and the
/// System / Light / Dark appearance setting.
class _NoBiometrics extends BiometricService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_extras');
    Flavor.debugOverride = AppFlavor.play;
  });

  tearDown(() async {
    L10n.setLang('tr');
    Flavor.debugOverride = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('AppActions', () {
    test('Play link is the GizliAlan listing', () {
      expect(
        AppActions.storeUrl,
        'https://play.google.com/store/apps/details?id=com.offerforge.gizlialan',
      );
      expect(AppActions.feedbackEmail, 'delibaltabaris5@gmail.com');
    });

    test('shared text is neutral (never mentions the vault) + link', () {
      for (final m in [tr, en]) {
        final text = AppActions.shareText(m['shareAppText']!);
        expect(text, endsWith(AppActions.storeUrl));
        final intro = m['shareAppText']!.toLowerCase();
        for (final w in ['kasa', 'vault', 'gizli', 'hidden', 'secret', 'pin']) {
          expect(intro.contains(w), isFalse, reason: '"$intro" contains $w');
        }
        expect(text.length, lessThan(500)); // native side limit
      }
    });

    test('feedback subject carries the app version', () {
      expect(
        AppActions.feedbackSubject('GizliAlan geri bildirim', '0.5.1', 20),
        'GizliAlan geri bildirim v0.5.1 (20)',
      );
    });

    test('TR and EN both have every new string', () {
      for (final k in [
        'appearance',
        'themeSystem',
        'themeLight',
        'themeDark',
        'helpTitle',
        'helpCalcBody',
        'helpDecoyBody',
        'helpVaultBody',
        'helpPinBody',
        'helpSecondPhoneBody',
        'shareApp',
        'rateApp',
        'feedback',
        'feedbackSubject',
        'shareAppFailed',
        'rateAppFailed',
        'feedbackFailed',
      ]) {
        expect(tr[k], isNotNull, reason: 'tr $k');
        expect(en[k], isNotNull, reason: 'en $k');
      }
    });
  });

  group('theme setting', () {
    test('default dark, persists, survives a vault reset', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await SettingsService.create();
      expect(s.themeMode, ThemeMode.dark);
      await s.setThemeMode(ThemeMode.light);
      expect(s.themeMode, ThemeMode.light);
      await s.setThemeMode(ThemeMode.system);
      final again = await SettingsService.create();
      expect(again.themeMode, ThemeMode.system);
      await again.resetAll();
      expect(again.themeMode, ThemeMode.system);
      expect(SettingsService.parseThemeMode('bogus'), ThemeMode.dark);
    });

    test('light palette: dark text and darker accent', () {
      final l = GizliTheme.light();
      expect(l.brightness, Brightness.light);
      expect(l.extension<GizliColors>(), GizliColors.light);
      expect(GizliTheme.dark().extension<GizliColors>(), GizliColors.dark);
      double ratio(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
      }

      const c = GizliColors.light;
      expect(ratio(c.textPrimary, c.bg), greaterThan(7));
      expect(ratio(c.textSecondary, c.bg), greaterThan(4.5));
      expect(ratio(c.accent, c.bg), greaterThan(4.5));
      expect(ratio(c.danger, c.bg), greaterThan(4.5));
      expect(ratio(c.warning, c.bg), greaterThan(4.5));
      expect(ratio(c.onAccent, c.accent), greaterThan(4.5));
      expect(ratio(c.textPrimary, c.calcKey), greaterThan(7));
    });
  });

  group('Settings rows', () {
    Future<void> settle(WidgetTester tester, [int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    late List<MethodCall> calls;
    late bool channelOk;
    String? clip;

    Future<GizliAlanAppState> openSettings(
      WidgetTester tester, {
      VaultSpace space = VaultSpace.real,
    }) async {
      calls = [];
      channelOk = true;
      clip = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        PrivacyLink.channel,
        (call) async {
          calls.add(call);
          if (call.method == 'appInfo') return null;
          return channelOk;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clip = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          PrivacyLink.channel,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await initializeDateFormatting();
      SharedPreferences.setMockInitialValues({'lang': 'tr'});
      final settings = await SettingsService.create();
      final auth = AuthService(
        storage: MemorySecureKv(),
        pbkdf2Iterations: 1000,
      );
      await tester.runAsync(() async {
        await auth.setPin('2580');
        await auth.setDecoyPin('1111');
      });
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GizliAlanApp(
          settings: settings,
          auth: auth,
          biometrics: _NoBiometrics(),
          baseDirProvider: () async => tmp,
        ),
      );
      await settle(tester, 2);
      final state = tester.state<GizliAlanAppState>(find.byType(GizliAlanApp));
      await tester.runAsync(() => state.enterVault(space));
      await settle(tester);
      state.navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      await settle(tester);
      return state;
    }

    Future<void> tapRow(WidgetTester tester, String key) async {
      final list = find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(key)),
        200,
        scrollable: list,
      );
      // Bring the row fully into view (not just its top edge).
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(key)));
      await settle(tester, 3);
    }

    testWidgets('share, rate and feedback use plain intents', (tester) async {
      await openSettings(tester);

      await tapRow(tester, 'settings_share');
      final share = calls.lastWhere((c) => c.method == 'shareApp');
      final text = (share.arguments as Map)['text'] as String;
      expect(text, '${tr['shareAppText']} ${AppActions.storeUrl}');

      await tapRow(tester, 'settings_rate');
      expect(calls.where((c) => c.method == 'openStore'), hasLength(1));

      await tapRow(tester, 'settings_feedback');
      final fb = calls.lastWhere((c) => c.method == 'sendFeedback');
      expect(
        (fb.arguments as Map)['subject'],
        'GizliAlan geri bildirim v$appVersion ($appBuild)',
      );
      expect(clip, isNull);
    });

    testWidgets('no app for the intent: link / address copied', (tester) async {
      await openSettings(tester);
      channelOk = false;
      await tapRow(tester, 'settings_rate');
      expect(clip, AppActions.storeUrl);
      expect(find.text(tr['rateAppFailed']!), findsOneWidget);
      await tapRow(tester, 'settings_feedback');
      expect(clip, AppActions.feedbackEmail);
    });

    testWidgets('help guide opens (TR); decoy vault has the rows too', (
      tester,
    ) async {
      await openSettings(tester, space: VaultSpace.decoy);
      for (final k in [
        'settings_share',
        'settings_rate',
        'settings_feedback',
      ]) {
        final list = find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(k)),
          200,
          scrollable: list,
        );
      }
      await tapRow(tester, 'settings_help');
      expect(find.byType(HelpScreen), findsOneWidget);
      expect(find.text(tr['helpCalcTitle']!), findsOneWidget);
      expect(find.text(tr['helpDecoyTitle']!), findsOneWidget);
      // play flavor: no Second phone section.
      expect(find.text(tr['helpSecondPhoneTitle']!), findsNothing);
    });

    testWidgets('appearance: Light applies to the app and is saved', (
      tester,
    ) async {
      final state = await openSettings(tester);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      await tapRow(tester, 'settings_theme');
      await tester.tap(find.byKey(const ValueKey('theme_light')));
      await tester.pumpAndSettle();
      expect(state.settings.themeMode, ThemeMode.light);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light,
      );
    });
  });

  testWidgets('help shows the Second phone section in the full build', (
    tester,
  ) async {
    Flavor.debugOverride = AppFlavor.full;
    await tester.pumpWidget(
      MaterialApp(theme: GizliTheme.light(), home: const HelpScreen()),
    );
    await tester.scrollUntilVisible(
      find.text(tr['helpSecondPhoneTitle']!),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(tr['helpSecondPhoneTitle']!), findsOneWidget);
  });
}
