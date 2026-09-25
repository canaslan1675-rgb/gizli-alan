import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme.dart';

enum SetPinMode { change, decoy }

/// Change the real PIN (requires current PIN) or set the decoy PIN.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, required this.mode});

  final SetPinMode mode;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _current = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);
    final p1 = _pin.text.trim();
    final p2 = _confirm.text.trim();
    if (!AuthService.isValidPinFormat(p1)) {
      setState(() => _error = t('pinFormat'));
      return;
    }
    if (p1 != p2) {
      setState(() => _error = t('pinMismatch'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.mode == SetPinMode.change) {
        final r = await app.auth.check(_current.text.trim());
        if (r != PinCheck.real) {
          setState(() {
            _busy = false;
            _error = r == PinCheck.lockedOut
                ? t('lockedOutShort')
                : t('wrongCurrentPin');
          });
          return;
        }
        await app.auth.setPin(p1);
      } else {
        await app.auth.setDecoyPin(p1);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('pinSaved'))));
      Navigator.of(context).pop(true);
    } on ArgumentError {
      setState(() {
        _busy = false;
        _error = t('pinMustDiffer');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final isChange = widget.mode == SetPinMode.change;
    return Scaffold(
      appBar: AppBar(title: Text(isChange ? t('changePin') : t('decoyPin'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isChange) ...[
            Text(
              t('decoyPinExplain'),
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isChange) ...[
            TextField(
              controller: _current,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: AuthService.maxPinLength,
              decoration: InputDecoration(labelText: t('currentPin')),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AuthService.maxPinLength,
            decoration: InputDecoration(labelText: t('newPin')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AuthService.maxPinLength,
            decoration: InputDecoration(labelText: t('confirmPin')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: GizliTheme.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('save')),
          ),
        ],
      ),
    );
  }
}
