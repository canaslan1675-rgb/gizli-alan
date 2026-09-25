import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/vault_space.dart';
import '../theme.dart';

/// PIN pad entry (used when the calculator entry is turned off).
/// Real PIN → real vault, decoy PIN → decoy vault, biometrics → real vault.
/// Wrong PINs are throttled by [AuthService].
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  Duration? _lockout;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshLockout();
      if (!mounted) return;
      final app = GizliAlanApp.of(context);
      if (app.settings.biometricEnabled && _lockout == null) {
        await app.unlockWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockout() async {
    final left = await GizliAlanApp.of(context).auth.lockoutRemaining();
    if (!mounted) return;
    setState(() => _lockout = left);
    _ticker?.cancel();
    if (left != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
        final l = await GizliAlanApp.of(context).auth.lockoutRemaining();
        if (!mounted) return;
        setState(() => _lockout = l);
        if (l == null) _ticker?.cancel();
      });
    }
  }

  Future<void> _submit() async {
    if (_pin.length < AuthService.minPinLength || _busy) return;
    final app = GizliAlanApp.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await app.auth.check(_pin);
    if (!mounted) return;
    switch (result) {
      case PinCheck.real:
      case PinCheck.decoy:
        setState(() {
          _busy = false;
          _pin = '';
        });
        await app.enterVault(
          result == PinCheck.real ? VaultSpace.real : VaultSpace.decoy,
        );
        break;
      case PinCheck.invalid:
      case PinCheck.lockedOut:
        setState(() {
          _busy = false;
          _pin = '';
          _error = L10n.current('wrongPin');
        });
        await _refreshLockout();
        break;
    }
  }

  void _add(String d) {
    if (_pin.length >= AuthService.maxPinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String label, {VoidCallback? onTap, IconData? icon}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          key: ValueKey('pin_${icon?.codePoint ?? label}'),
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: GizliTheme.mint, size: 28)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 26,
                        color: GizliTheme.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final locked = _lockout != null;
    final disabled = _busy || locked;
    return Scaffold(
      appBar: AppBar(title: Text(t('appNameVault'))),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock, size: 48, color: GizliTheme.mint),
            const SizedBox(height: 16),
            Text(t('unlock'), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AuthService.maxPinLength, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? GizliTheme.mint
                        : GizliTheme.textSecondary.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            if (locked)
              Text(
                t('lockedOut').replaceAll(
                  '{s}',
                  '${(_lockout!.inMilliseconds / 1000).ceil()}',
                ),
                style: const TextStyle(color: GizliTheme.warning),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: GizliTheme.danger)),
            if (_busy) ...[
              const SizedBox(height: 12),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            const Spacer(),
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(
                children: row
                    .map((d) => _key(d, onTap: disabled ? null : () => _add(d)))
                    .toList(),
              ),
            Row(
              children: [
                _key(
                  '',
                  onTap: disabled ? null : _back,
                  icon: Icons.backspace_outlined,
                ),
                _key('0', onTap: disabled ? null : () => _add('0')),
                _key(
                  '',
                  onTap: disabled ? null : _submit,
                  icon: Icons.check_circle,
                ),
              ],
            ),
            if (app.settings.biometricEnabled)
              TextButton.icon(
                onPressed: locked ? null : app.unlockWithBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: Text(t('useBiometric')),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
