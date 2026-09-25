import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'screens/decoy_calculator_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/vault_home_screen.dart';
import 'services/auth_service.dart';
import 'services/notes_repository.dart';
import 'services/settings_service.dart';
import 'services/vault_storage.dart';
import 'theme.dart';

/// Root app with lifecycle auto-lock.
/// Leaving vault clears the navigator stack back to decoy/root.
class GizliAlanApp extends StatefulWidget {
  const GizliAlanApp({
    super.key,
    required this.settings,
    required this.auth,
    required this.vault,
    required this.notes,
    this.preferDirectVault = false,
  });

  final SettingsService settings;
  final AuthService auth;
  final VaultStorage vault;
  final NotesRepository notes;

  /// True when launched via "GizliAlan Kasa" / Private Vault activity.
  final bool preferDirectVault;

  @override
  State<GizliAlanApp> createState() => GizliAlanAppState();

  static GizliAlanAppState of(BuildContext context) =>
      context.findAncestorStateOfType<GizliAlanAppState>()!;
}

class GizliAlanAppState extends State<GizliAlanApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  bool _unlocked = false;
  bool _ready = false;
  bool _needsOnboarding = true;
  Timer? _lockTimer;
  DateTime? _pausedAt;

  SettingsService get settings => widget.settings;
  AuthService get auth => widget.auth;
  VaultStorage get vault => widget.vault;
  NotesRepository get notes => widget.notes;

  bool get isUnlocked => _unlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final onboarded = await auth.isOnboarded();
    setState(() {
      _needsOnboarding = !onboarded;
      _ready = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_unlocked) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
      _lockTimer?.cancel();
      final timeout = settings.lockTimeoutSec;
      if (timeout <= 0) {
        lockVault(popToRoot: false);
      } else {
        _lockTimer = Timer(Duration(seconds: timeout), () {
          lockVault(popToRoot: false);
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      if (_pausedAt != null && settings.lockTimeoutSec > 0) {
        final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
        if (elapsed >= settings.lockTimeoutSec) {
          lockVault(popToRoot: false);
        }
      }
      _pausedAt = null;
    }
  }

  void unlock() => setState(() => _unlocked = true);

  void lockVault({bool popToRoot = true}) {
    setState(() => _unlocked = false);
    if (popToRoot) {
      navKey.currentState?.popUntil((r) => r.isFirst);
    }
  }

  /// After successful PIN from decoy: push vault; Leave pops to decoy.
  Future<void> enterVaultAfterPin() async {
    unlock();
    navKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
    );
  }

  void leaveVaultToDecoy() => lockVault(popToRoot: true);

  void markOnboarded() => setState(() => _needsOnboarding = false);

  void refreshL10n() => setState(() {});

  Widget _home() {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_needsOnboarding) return const OnboardingScreen();

    // Transparent vault entry (second launcher / decoy off).
    final direct = widget.preferDirectVault || !settings.decoyEnabled;
    if (direct) {
      return PinLockScreen(
        onSuccess: () {
          unlock();
          navKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
          );
        },
      );
    }
    return const DecoyCalculatorScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: L10n.current('appName'),
      debugShowCheckedModeBanner: false,
      theme: GizliTheme.dark(),
      navigatorKey: navKey,
      home: _home(),
    );
  }
}
