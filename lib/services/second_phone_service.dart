import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What to do with the "second phone" (work profile) while the real vault is
/// locked (issue #30: "Kilitliyken iş uygulamalarını gizle", default on).
enum SecondPhoneCloseMode {
  /// Leave the work profile as it is (toggle off).
  off,

  /// Hide (freeze) the profile's launchable apps so they disappear from the
  /// phone launcher's Work/"İş" folder; unhidden again on the next real
  /// unlock.
  freeze,

  /// [freeze] AND additionally try to pause the work profile (quiet mode).
  /// Android only lets the default launcher / system apps pause a profile,
  /// so on most phones only the hiding part takes effect. Default since
  /// v0.4.4 (#45: owner wants the strictest possible lock).
  quiet;

  static SecondPhoneCloseMode parse(String? v) => SecondPhoneCloseMode.values
      .firstWhere((m) => m.name == v, orElse: () => SecondPhoneCloseMode.quiet);
}

/// How the second-phone screen should present itself on this device.
enum SecondPhoneAvailability {
  /// Our work profile exists and is linked to this vault.
  ready,

  /// A profile with GizliAlan exists but this install has no link to it
  /// (e.g. app data was cleared). It can only be removed from Android
  /// Settings → Accounts → Work profile.
  unlinked,

  /// Provisioning is available.
  canSetUp,

  /// Provisioning looks available, but this is a Xiaomi/Redmi/POCO device
  /// where MIUI/HyperOS often blocks or breaks work profiles.
  canSetUpXiaomiRisk,

  /// Blocked on a Xiaomi-family device.
  blockedXiaomi,

  /// Supported in principle but not allowed now (another work profile or a
  /// company policy already exists, or the OEM disabled it).
  notAllowed,

  /// The device has no managed-profile support at all.
  unsupported,
}

@immutable
class SecondPhoneStatus {
  const SecondPhoneStatus({
    this.featureSupported = false,
    this.provisioningAllowed = false,
    this.exists = false,
    this.linked = false,
    this.quietMode = false,
    this.manufacturer = '',
    this.brand = '',
    this.isXiaomi = false,
    this.sdkInt = 0,
  });

  factory SecondPhoneStatus.fromMap(Map<Object?, Object?> m) =>
      SecondPhoneStatus(
        featureSupported: m['featureSupported'] == true,
        provisioningAllowed: m['provisioningAllowed'] == true,
        exists: m['exists'] == true,
        linked: m['linked'] == true,
        quietMode: m['quietMode'] == true,
        manufacturer: (m['manufacturer'] as String?) ?? '',
        brand: (m['brand'] as String?) ?? '',
        isXiaomi: m['isXiaomi'] == true,
        sdkInt: (m['sdkInt'] as int?) ?? 0,
      );

  static const unavailable = SecondPhoneStatus();

  final bool featureSupported;
  final bool provisioningAllowed;
  final bool exists;
  final bool linked;
  final bool quietMode;
  final String manufacturer;
  final String brand;
  final bool isXiaomi;
  final int sdkInt;

  /// Android 15+ has the built-in Private Space (fallback suggestion).
  bool get privateSpaceAvailable => sdkInt >= 35;

  SecondPhoneAvailability get availability {
    if (exists) {
      return linked
          ? SecondPhoneAvailability.ready
          : SecondPhoneAvailability.unlinked;
    }
    if (!featureSupported) {
      return isXiaomi
          ? SecondPhoneAvailability.blockedXiaomi
          : SecondPhoneAvailability.unsupported;
    }
    if (!provisioningAllowed) {
      return isXiaomi
          ? SecondPhoneAvailability.blockedXiaomi
          : SecondPhoneAvailability.notAllowed;
    }
    return isXiaomi
        ? SecondPhoneAvailability.canSetUpXiaomiRisk
        : SecondPhoneAvailability.canSetUp;
  }
}

@immutable
class ProfileApp {
  const ProfileApp({
    required this.label,
    required this.packageName,
    required this.activity,
    this.icon,
  });

  factory ProfileApp.fromMap(Map<Object?, Object?> m) => ProfileApp(
    label: (m['label'] as String?) ?? '',
    packageName: (m['package'] as String?) ?? '',
    activity: (m['activity'] as String?) ?? '',
    icon: m['icon'] as Uint8List?,
  );

  final String label;
  final String packageName;
  final String activity;
  final Uint8List? icon;
}

@immutable
class CloneCandidate {
  const CloneCandidate({
    required this.label,
    required this.packageName,
    required this.isSystem,
    this.icon,
  });

  factory CloneCandidate.fromMap(Map<Object?, Object?> m) => CloneCandidate(
    label: (m['label'] as String?) ?? '',
    packageName: (m['package'] as String?) ?? '',
    isSystem: m['isSystem'] == true,
    icon: m['icon'] as Uint8List?,
  );

  final String label;
  final String packageName;
  final bool isSystem;
  final Uint8List? icon;
}

/// Dart side of the Android `gizlialan/second_phone` channel
/// (android/.../secondphone/SecondPhoneChannel.kt).
///
/// Every call returns a status string instead of throwing, so the UI can
/// show a clear message. Common statuses: `ok`, `canceled`, `unavailable`,
/// `blocked`, `no_profile`, `unreachable`, `denied`, `not_permitted`,
/// `frozen`, `unfrozen`, `partial`, `cloned`, `store_opened`, `needs_store`,
/// `no_store`, `removed`, `error`.
///
/// Only the vault (after PIN/biometric unlock) uses this; see
/// `GizliAlanAppState.secondPhoneIfUnlocked`.
class SecondPhoneService {
  SecondPhoneService({MethodChannel? channel})
    : _ch = channel ?? const MethodChannel('gizlialan/second_phone');

  final MethodChannel _ch;

  Future<Object?> _call(String method, [Map<String, Object?>? args]) async {
    try {
      return await _ch.invokeMethod<Object?>(method, args);
    } on MissingPluginException {
      return null; // tests / non-Android
    } on PlatformException catch (e) {
      debugPrint('second phone $method failed: ${e.message}');
      return null;
    }
  }

  Future<String> _status(String method, [Map<String, Object?>? args]) async {
    final r = await _call(method, args);
    if (r is Map) return (r['status'] as String?) ?? 'error';
    return 'unavailable';
  }

  Future<SecondPhoneStatus> status() async {
    final r = await _call('status');
    return r is Map
        ? SecondPhoneStatus.fromMap(r)
        : SecondPhoneStatus.unavailable;
  }

  /// Starts Android's managed-profile provisioning. `ok` = profile created.
  Future<String> provision() => _status('provision');

  Future<List<ProfileApp>> listApps() async {
    final r = await _call('listApps');
    if (r is! List) return const [];
    return r.whereType<Map>().map(ProfileApp.fromMap).toList();
  }

  Future<String> launch(ProfileApp app) => _status('launchApp', {
    'package': app.packageName,
    'activity': app.activity,
  });

  Future<List<CloneCandidate>> cloneCandidates() async {
    final r = await _call('cloneCandidates');
    if (r is! List) return const [];
    return r.whereType<Map>().map(CloneCandidate.fromMap).toList();
  }

  Future<String> clone(CloneCandidate c, {bool openStoreFallback = true}) =>
      _status('clone', {
        'package': c.packageName,
        'isSystem': c.isSystem,
        'openStoreFallback': openStoreFallback,
      });

  Future<String> openStore() => _status('openStore');

  Future<String> freeze() => _status('freeze');

  Future<String> unfreeze() => _status('unfreeze');

  Future<String> setQuietMode(bool enabled) =>
      _status('setQuietMode', {'enabled': enabled});

  Future<String> remove() => _status('remove');

  /// Closes the second phone. Always hides the apps first (quiet mode alone
  /// would leave greyed-out icons in the launcher, e.g. on Xiaomi); with
  /// [SecondPhoneCloseMode.quiet] it then also tries to pause the profile.
  /// Returns the mode that was actually applied, or null when nothing was
  /// done.
  Future<SecondPhoneCloseMode?> close(SecondPhoneCloseMode mode) async {
    if (mode == SecondPhoneCloseMode.off) return null;
    final frozen = await freeze() == 'frozen';
    if (mode == SecondPhoneCloseMode.quiet) {
      if (await setQuietMode(true) == 'ok') return SecondPhoneCloseMode.quiet;
    }
    return frozen ? SecondPhoneCloseMode.freeze : null;
  }

  /// `unfrozen`, or `partial` (some unhides failed; the profile keeps those
  /// recorded and retries them on the next unfreeze).
  static bool isUnfrozen(String status) =>
      status == 'unfrozen' || status == 'partial';

  /// Re-opens what [close] did. For quiet mode the profile must be running
  /// again before its apps can be unhidden, so this waits (up to
  /// [quietPolls] × [pollDelay]) for Android to report it unpaused.
  Future<bool> open(
    SecondPhoneCloseMode applied, {
    int quietPolls = 10,
    Duration pollDelay = const Duration(milliseconds: 500),
  }) async {
    switch (applied) {
      case SecondPhoneCloseMode.off:
        return true;
      case SecondPhoneCloseMode.quiet:
        if (await setQuietMode(false) != 'ok') return false;
        for (var i = 0; i < quietPolls; i++) {
          if (!(await status()).quietMode) break;
          await Future<void>.delayed(pollDelay);
        }
        return isUnfrozen(await unfreeze());
      case SecondPhoneCloseMode.freeze:
        return isUnfrozen(await unfreeze());
    }
  }
}
