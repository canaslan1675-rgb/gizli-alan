import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'decoy_calculator_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = L10n.current;
    final p1 = _pin.text.trim();
    final p2 = _confirm.text.trim();
    if (p1.length < 4) {
      setState(() => _error = t('pinTooShort'));
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
    final app = GizliAlanApp.of(context);
    await app.auth.setPin(p1);
    app.markOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => app.settings.decoyEnabled
            ? const DecoyCalculatorScreen()
            : const DecoyCalculatorScreen(), // home rebuild handles direct
      ),
    );
    // Force app rebuild to correct home
    app.refreshL10n();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.lock_outline, size: 56, color: GizliTheme.mint),
            const SizedBox(height: 16),
            Text(
              t('onboardingTitle'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: GizliTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('onboardingBody'),
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GizliTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GizliTheme.mint.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                t('onboardingPrivacy'),
                style: const TextStyle(
                  color: GizliTheme.mint,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('setPin')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('confirmPin')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: GizliTheme.danger)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(t('continue')),
            ),
            const SizedBox(height: 16),
            Text(
              t('dataSafetyShort'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
