import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper over local_auth (fingerprint / face via BiometricPrompt).
/// Needs only USE_BIOMETRIC; no biometric data ever reaches the app.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      debugPrint('biometric availability check failed: $e');
      return false;
    }
  }

  /// Returns true only on a successful biometric match.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
    } on LocalAuthException catch (e) {
      debugPrint('biometric auth: ${e.code.name}');
      return false;
    } catch (e) {
      debugPrint('biometric auth error: $e');
      return false;
    }
  }
}
