import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'flavor.dart';
import 'l10n/l10n.dart';
import 'models/vault_event.dart';
import 'screens/decoy_calculator_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/vault_home_screen.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/browser_engine.dart';
import 'services/pro_entitlement.dart';
import 'services/legacy_migration.dart';
import 'services/second_phone_service.dart';
import 'services/settings_service.dart';
import 'services/vault_session.dart';
import 'services/vault_space.dart';
import 'theme.dart';

/// Root widget. Owns the unlocked [VaultSession] and the auto-lock logic.
///
/// Navigation model: the first route is the entry screen (onboarding,
/// calculator or PIN pad). Unlocking pushes the vault on top; locking closes
/// the session and pops back to the entry screen.
class GizliAlanApp extends StatefulWidget {
  const GizliAlanApp({
    super.key,
    required this.settings,
    required this.auth,
    required this.biometrics,
    this.baseDirProvider,
    this.secondPhone,
    this.browserEngineFactory,
    this.wipeBrowserData,
  });

  final SettingsService settings;
  final AuthService auth;
  final BiometricService biometrics;

  /// Where vault data lives. Defaults to the app-private support directory.
  final Future<Directory> Function()? baseDirProvider;

  /// Android work-profile "second phone" bridge (injectable for tests).
  final SecondPhoneService? secondPhone;

  /// Private browser engine (injectable for tests; default Android WebView).
  final BrowserEngineFactory? browserEngineFactory;

  /// Wipes browser cookies/cache/storage (injectable for tests).
  final Future<bool> Function()? wipeBrowserData;

  @override
  State<GizliAlanApp> createState() => GizliAlanAppState();

  static GizliAlanAppState of(BuildContext context) =>
      context.findAncestorStateOfType<GizliAlanAppState>()!;
}

class GizliAlanAppState extends State<GizliAlanApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  bool _ready = false;
  bool _needsOnboarding = true;
  VaultSession? _session;
  DateTime? _backgroundedAt;

  /// >0 while a system UI we launched (photo picker, file dialog, biometric
  /// prompt) is in front, so auto-lock does not fire mid-import.
  int _externalUi = 0;

  SettingsService get settings => widget.settings;
  AuthService get auth => widget.auth;
  BiometricService get biometrics => widget.biometrics;

  late final SecondPhoneService _secondPhone =
      widget.secondPhone ?? SecondPhoneService();

  /// The second phone is only reachable while the REAL vault is unlocked
  /// (never from the calculator, the PIN screen or the decoy vault), and only
  /// in the `full` flavor (the `play` build has no Second phone at all).
  SecondPhoneService? get secondPhoneIfUnlocked =>
      (Flavor.hasSecondPhone && _session != null && !_session!.isDecoy)
      ? _secondPhone
      : null;

  BrowserEngineFactory get browserEngineFactory =>
      widget.browserEngineFactory ?? WebViewBrowserEngine.new;

  Future<bool> wipeBrowserData() =>
      (widget.wipeBrowserData ?? BrowserData.wipe)();

  /// "Kilitlenince temizle" (#32): on lock and on app start (in case the
  /// app was killed while unlocked).
  void _wipeBrowserIfEnabled() {
    if (settings.browserWipeOnLock) wipeBrowserData();
  }

  VaultSession? get session => _session;
  bool get isUnlocked => _session != null;

  Future<Directory> baseDir() async => widget.baseDirProvider != null
      ? widget.baseDirProvider!()
      : getApplicationSupportDirectory();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final onboarded = await auth.isOnboarded() || await auth.hasPin();
    if (!mounted) return;
    setState(() {
      _needsOnboarding = !onboarded;
      _ready = true;
    });
    _wipeBrowserIfEnabled();
    // App start while locked: make sure the work apps are hidden (#30).
    if (onboarded) ensureWorkAppsHiddenWhileLocked();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    secondPhoneChanged.dispose();
    _session?.close();
    super.dispose();
  }

  // ------------------------------------------------------------ auto-lock

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_externalUi > 0) return;
    if (!isUnlocked) {
      // Back in the foreground while locked: hide the work apps if a
      // background auto-lock could not (#30). A new foreground visit may try
      // again, so reset the per-visit guard when we really leave.
      if (state == AppLifecycleState.resumed) {
        ensureWorkAppsHiddenWhileLocked();
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        _hideTriedThisVisit = false;
      }
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt ??= DateTime.now();
        if (settings.lockTimeoutSec <= 0) lockVault();
        break;
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            DateTime.now().difference(since).inSeconds >=
                settings.lockTimeoutSec) {
          lockVault();
          ensureWorkAppsHiddenWhileLocked();
        }
        break;
      case AppLifecycleState.detached:
        lockVault();
        break;
      case AppLifecycleState.inactive:
        // Notification shade, system dialogs: FLAG_SECURE already hides
        // content from recents; don't lock for a mere shade pull.
        break;
    }
  }

  /// Runs [action] (which opens a system picker / prompt) without triggering
  /// auto-lock when our activity is briefly backgrounded.
  Future<T> withExternalUi<T>(Future<T> Function() action) async {
    _externalUi++;
    try {
      return await action();
    } finally {
      _externalUi--;
      _backgroundedAt = null;
    }
  }

  // ------------------------------------------------------------ unlock / lock

  /// Opens [space] and shows the vault home on top of the entry screen.
  Future<void> enterVault(VaultSpace space) async {
    final key = await auth.dataKey(space);
    final dir = await baseDir();
    _session?.close();
    final session = VaultSession(space: space, key: key, baseDir: dir);
    if (space == VaultSpace.real) {
      try {
        await LegacyMigration.run(
          session,
          await getApplicationDocumentsDirectory(),
        );
      } catch (e) {
        debugPrint('legacy migration skipped: $e');
      }
    }
    if (space == VaultSpace.real) {
      final failed = await auth.takeFailuresSinceUnlock();
      if (failed > 0) {
        await session.events.add(VaultEventType.failedUnlocks, {
          'n': '$failed',
        });
      }
    }
    setState(() => _session = session);
    navKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
      (r) => r.isFirst,
    );
    if (space == VaultSpace.real) _reopenSecondPhone();
  }

  /// Real vault unlocked (PIN/biometric): unhide the work apps we hid.
  /// If our "hidden" marker was lost but hiding is enabled, ask the profile
  /// anyway — it only unhides packages it recorded itself (#30).
  Future<void> _reopenSecondPhone() async {
    // A hide still in flight re-opens by itself when it finishes.
    if (!Flavor.hasSecondPhone || _closing) return;
    var closedBy = settings.secondPhoneClosedBy;
    if (closedBy == null) {
      if (!settings.hideWorkAppsWhenLocked) return;
      final st = await _secondPhone.status();
      if (st.availability != SecondPhoneAvailability.ready) return;
      closedBy = st.quietMode
          ? SecondPhoneCloseMode.quiet
          : SecondPhoneCloseMode.freeze;
    }
    final mode = closedBy;
    // Opening may briefly start a system/profile activity: don't auto-lock.
    final ok = await withExternalUi(() => _secondPhone.open(mode));
    if (ok) await settings.setSecondPhoneClosedBy(null);
    secondPhoneChanged.value++;
  }

  /// Bumped when the second phone opens/closes so the home grid reloads.
  final ValueNotifier<int> secondPhoneChanged = ValueNotifier(0);

  /// Lock button: lock the vault and, if enabled, hide the work apps.
  void lockVaultExplicit() {
    final wasReal = _session != null && !_session!.isDecoy;
    lockVault();
    if (wasReal) _closeSecondPhone();
  }

  bool _closing = false;
  bool _hideTriedThisVisit = false;
  DateTime? _lastHideAttempt;

  /// Minimum gap between automatic hide attempts. Each attempt briefly
  /// starts a (translucent) activity in the work profile, which pauses and
  /// resumes us; this guard prevents a resume → hide → resume loop.
  static const hideCooldown = Duration(seconds: 10);

  /// "Hide work apps while locked" (#30): called on app start, when the app
  /// returns to the foreground while locked, and after auto-lock on resume.
  ///
  /// Android does not let a backgrounded app start the cross-profile
  /// request, so a background auto-lock cannot hide immediately; it happens
  /// the next time GizliAlan is in the foreground while locked. Does nothing
  /// while unlocked, when the toggle is off, when already hidden by us, or
  /// in the `play` flavor.
  Future<void> ensureWorkAppsHiddenWhileLocked() async {
    if (!Flavor.hasSecondPhone || isUnlocked) return;
    if (!settings.hideWorkAppsWhenLocked) return;
    if (settings.secondPhoneClosedBy != null) return;
    if (_closing || _hideTriedThisVisit) return;
    final last = _lastHideAttempt;
    if (last != null && DateTime.now().difference(last) < hideCooldown) return;
    final lc = WidgetsBinding.instance.lifecycleState;
    if (lc != null && lc != AppLifecycleState.resumed) return;
    _hideTriedThisVisit = true;
    _lastHideAttempt = DateTime.now();
    await _closeSecondPhone();
  }

  Future<void> _closeSecondPhone() async {
    if (!Flavor.hasSecondPhone || _closing) return;
    final mode = settings.secondPhoneCloseMode;
    if (mode == SecondPhoneCloseMode.off) return;
    _closing = true;
    _lastHideAttempt = DateTime.now();
    try {
      final st = await _secondPhone.status();
      if (st.availability != SecondPhoneAvailability.ready) return;
      // Starts a translucent activity in the work profile: don't let the
      // resulting pause/resume count as leaving the app.
      final applied = await withExternalUi(() => _secondPhone.close(mode));
      // Unlocked again meanwhile? Then re-open right away.
      if (applied != null) await settings.setSecondPhoneClosedBy(applied);
      if (applied != null && isUnlocked && !_session!.isDecoy) {
        await _reopenSecondPhone();
      }
    } finally {
      _closing = false;
    }
  }

  /// Biometric unlock of the real vault. Returns true on success.
  Future<bool> unlockWithBiometrics() async {
    if (!settings.biometricEnabled) return false;
    final ok = await withExternalUi(
      () => biometrics.authenticate(L10n.current('biometricReason')),
    );
    if (!ok) return false;
    await auth.onBiometricSuccess();
    await enterVault(VaultSpace.real);
    return true;
  }

  void lockVault() {
    final s = _session;
    if (s == null) return;
    s.close();
    _wipeBrowserIfEnabled();
    // Drop decoded vault photos (gallery thumbnails, home background) from
    // Flutter's in-memory image cache.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    _backgroundedAt = null;
    setState(() => _session = null);
    navKey.currentState?.popUntil((r) => r.isFirst);
  }

  void markOnboarded() => setState(() => _needsOnboarding = false);

  /// Full reset: data of both spaces, keys, PINs and settings.
  Future<void> resetEverything() async {
    final dir = await baseDir();
    _session?.close();
    await VaultSession.wipeSpace(dir, VaultSpace.real);
    await VaultSession.wipeSpace(dir, VaultSpace.decoy);
    await auth.clearAuth();
    await settings.resetAll();
    setState(() {
      _session = null;
      _needsOnboarding = true;
    });
    navKey.currentState?.popUntil((r) => r.isFirst);
  }

  /// Rebuild after language / entry-mode changes.
  void refresh() => setState(() {});

  Widget _home() {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsOnboarding) return const OnboardingScreen();
    if (settings.calculatorEntryEnabled) {
      return const DecoyCalculatorScreen(vaultEntry: true);
    }
    return const PinLockScreen();
  }

  @override
  Widget build(BuildContext context) {
    return L10nScope(
      lang: L10n.lang,
      child: MaterialApp(
        title: L10n.current('launcherName'),
        debugShowCheckedModeBanner: false,
        theme: GizliTheme.dark(),
        navigatorKey: navKey,
        // Key on entry mode so switching it swaps the root screen cleanly.
        home: KeyedSubtree(
          key: ValueKey(
            '${_needsOnboarding}_${settings.calculatorEntryEnabled}_'
            '${ProEntitlement.hideCalculatorInfo(settings)}',
          ),
          child: _home(),
        ),
      ),
    );
  }
}
