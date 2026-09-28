import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/play_billing_backend.dart';
import 'services/pro_billing.dart';
import 'services/pro_entitlement.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/settings_service.dart';

/// GizliAlan — personal vault for the device owner.
///
/// PLAY COMPLIANCE:
/// - Not spyware / stalkerware; nothing about other people is collected.
/// - No SMS/call access, no Accessibility Service, no main-device admin, no
///   Notification Listener, no analytics/telemetry/ads/own server. INTERNET
///   (v0.4.0, #32) is used only by the in-vault private browser for pages the
///   user opens.
/// - The calculator entry is disclosed in onboarding, in-app and in the
///   store listing; reviewers see exactly what users see. The launcher
///   label is "Calculator"/"Hesap Makinesi" (a real calculator).
/// - Optional "second phone": profile owner of the user's own work profile
///   only (no device-owner / main-profile admin powers).
/// - AES-GCM uses Android's native implementation via cryptography_flutter
///   (registered automatically as a Dart plugin).
/// - Screens are protected with FLAG_SECURE (set in MainActivity).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = await SettingsService.create();

  // Play build: Pro via Google Play Billing. Not awaited — the cached
  // entitlement is used until Play answers (offline-safe).
  if (ProEntitlement.viaPlayBilling) {
    final billing = ProBilling(settings, PlayBillingBackend());
    ProBilling.instance = billing;
    billing.start();
  }

  runApp(
    GizliAlanApp(
      settings: settings,
      auth: AuthService(),
      biometrics: BiometricService(),
    ),
  );
}
