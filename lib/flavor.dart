import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Build distribution (issue #11), set by `flutter build … --flavor play|full`
/// (Flutter exposes it as [appFlavor]); `--dart-define=FLAVOR=…` also works.
enum AppFlavor {
  /// Google Play build: vault + calculator only, NO Second phone. The Android
  /// side has no device-admin receiver or work-profile code either.
  play,

  /// Side-load/test build with the Second phone (own work profile).
  full,
}

class Flavor {
  Flavor._();

  static AppFlavor? _override;

  /// Unknown/missing flavor → [AppFlavor.play] (safe default: the Second
  /// phone UI is hidden; it could not work without the native side anyway).
  static AppFlavor parse(String? name) =>
      name == 'full' ? AppFlavor.full : AppFlavor.play;

  static AppFlavor get current =>
      _override ??
      parse(
        (appFlavor != null && appFlavor!.isNotEmpty)
            ? appFlavor
            : const String.fromEnvironment('FLAVOR'),
      );

  /// Whether this build contains the Second phone feature.
  static bool get hasSecondPhone => current == AppFlavor.full;

  @visibleForTesting
  static set debugOverride(AppFlavor? f) => _override = f;
}
