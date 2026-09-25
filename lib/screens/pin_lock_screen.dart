import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (_pin.length < 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await GizliAlanApp.of(context).auth.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      widget.onSuccess();
    } else {
      setState(() {
        _busy = false;
        _error = L10n.current('wrongPin');
        _pin = '';
      });
    }
  }

  void _add(String d) {
    if (_pin.length >= 8) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length >= 4) {
      // auto-try at 4+ if user taps unlock; keep manual for variable length
    }
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
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: GizliTheme.mint)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 24,
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
    final t = L10n.current;
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
              children: List.generate(6, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? GizliTheme.mint
                        : GizliTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: GizliTheme.danger)),
            ],
            const Spacer(),
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(
                children: row
                    .map((d) => _key(d, onTap: _busy ? null : () => _add(d)))
                    .toList(),
              ),
            Row(
              children: [
                _key('', onTap: _busy ? null : _back, icon: Icons.backspace_outlined),
                _key('0', onTap: _busy ? null : () => _add('0')),
                _key('', onTap: _busy ? null : _submit, icon: Icons.check_circle),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
