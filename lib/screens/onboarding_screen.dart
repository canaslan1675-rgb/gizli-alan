import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// First-run flow (3 steps):
/// 1. What the app is — a personal vault for the device owner, not a
///    monitoring tool. Owner confirms it is their own device.
/// 2. Entry mode — openly explains the calculator entry (PIN then `=`) and
///    lets the owner turn it off.
/// 3. PIN setup with an honest "forgotten PIN = no recovery" warning.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _ownDevice = false;
  bool _calculator = true;
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

  Future<void> _finish() async {
    final t = L10n.current;
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
    final app = GizliAlanApp.of(context);
    await app.settings.setCalculatorEntryEnabled(_calculator);
    await app.auth.setPin(p1);
    if (!mounted) return;
    app.markOnboarded();
  }

  Widget _langSwitch() {
    final app = GizliAlanApp.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'tr', label: Text('TR')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {L10n.lang},
        showSelectedIcon: false,
        onSelectionChanged: (s) async {
          await app.settings.setLanguage(s.first);
          app.refresh();
        },
      ),
    );
  }

  Widget _card(String text, {Color color = GizliTheme.mint}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: GizliTheme.bgCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 13, height: 1.45),
    ),
  );

  Widget _title(IconData icon, String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 52, color: GizliTheme.mint),
      const SizedBox(height: 14),
      Text(
        text,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: GizliTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(color: GizliTheme.textSecondary, height: 1.5),
  );

  List<Widget> _stepWelcome(L10n t) => [
    _title(Icons.shield_outlined, t('onboardingTitle')),
    _body(t('onboardingBody')),
    const SizedBox(height: 16),
    _card(t('onboardingPrivacy')),
    const SizedBox(height: 16),
    CheckboxListTile(
      key: const ValueKey('own_device'),
      value: _ownDevice,
      onChanged: (v) => setState(() => _ownDevice = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(t('ownDeviceConfirm')),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: _ownDevice ? () => setState(() => _step = 1) : null,
      child: Text(t('continue')),
    ),
  ];

  List<Widget> _stepEntry(L10n t) => [
    _title(Icons.calculate_outlined, t('entryTitle')),
    _body(t('entryBody')),
    const SizedBox(height: 16),
    _card(t('entryDisclosure'), color: GizliTheme.warning),
    const SizedBox(height: 12),
    SwitchListTile(
      value: _calculator,
      onChanged: (v) => setState(() => _calculator = v),
      contentPadding: EdgeInsets.zero,
      title: Text(t('calculatorEntry')),
      subtitle: Text(
        _calculator ? t('calculatorEntryOn') : t('calculatorEntryOff'),
        style: const TextStyle(color: GizliTheme.textSecondary),
      ),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: () => setState(() => _step = 2),
      child: Text(t('continue')),
    ),
    TextButton(
      onPressed: () => setState(() => _step = 0),
      child: Text(t('back')),
    ),
  ];

  List<Widget> _stepPin(L10n t) => [
    _title(Icons.pin_outlined, t('setPin')),
    _body(t('pinFormat')),
    const SizedBox(height: 16),
    TextField(
      key: const ValueKey('pin_new'),
      controller: _pin,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: AuthService.maxPinLength,
      decoration: InputDecoration(labelText: t('setPin')),
    ),
    const SizedBox(height: 8),
    TextField(
      key: const ValueKey('pin_confirm'),
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
    const SizedBox(height: 12),
    _card(t('pinNoRecovery'), color: GizliTheme.warning),
    const SizedBox(height: 20),
    ElevatedButton(
      key: const ValueKey('onboarding_finish'),
      onPressed: _busy ? null : _finish,
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(t('finishSetup')),
    ),
    TextButton(
      onPressed: _busy ? null : () => setState(() => _step = 1),
      child: Text(t('back')),
    ),
    const SizedBox(height: 8),
    Text(
      t('dataSafetyShort'),
      textAlign: TextAlign.center,
      style: const TextStyle(color: GizliTheme.textSecondary, fontSize: 12),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final steps = [_stepWelcome, _stepEntry, _stepPin];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Text(
                  '${_step + 1} / 3',
                  style: const TextStyle(color: GizliTheme.textSecondary),
                ),
                const Spacer(),
                _langSwitch(),
              ],
            ),
            const SizedBox(height: 16),
            ...steps[_step](t),
          ],
        ),
      ),
    );
  }
}
