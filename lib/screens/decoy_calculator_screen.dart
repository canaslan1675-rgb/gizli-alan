import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'pin_lock_screen.dart';

/// Optional decoy calculator UI.
///
/// PLAY COMPLIANCE: This is NOT the only entry point. A second launcher
/// activity labeled "GizliAlan Kasa" / "Hidden Space Vault" opens PIN directly.
/// Settings inside vault can disable decoy. Long-press "=" OR tap the small
/// vault link opens PIN — transparent, not deceptive-only.
class DecoyCalculatorScreen extends StatefulWidget {
  const DecoyCalculatorScreen({super.key});

  @override
  State<DecoyCalculatorScreen> createState() => _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends State<DecoyCalculatorScreen> {
  String _display = '0';
  String _expr = '';
  // Secret sequence buffer: entering PIN digits then long-press = also works
  // via dedicated long-press; sequence "====" as alternate.
  int _eqTapCount = 0;

  void _digit(String d) {
    setState(() {
      if (_display == '0') {
        _display = d;
      } else {
        _display += d;
      }
      _expr += d;
    });
  }

  void _op(String o) {
    setState(() {
      _expr = '$_display $o ';
      _display = '0';
      _eqTapCount = 0;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _expr = '';
      _eqTapCount = 0;
    });
  }

  void _equals() {
    // Simple eval for decoy realism ( +, -, *, / )
    try {
      final parts = _expr.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final a = double.parse(parts[0]);
        final op = parts[1];
        final b = double.parse(_display);
        double r;
        switch (op) {
          case '+':
            r = a + b;
            break;
          case '-':
            r = a - b;
            break;
          case '×':
          case '*':
            r = a * b;
            break;
          case '÷':
          case '/':
            r = b == 0 ? double.nan : a / b;
            break;
          default:
            r = b;
        }
        setState(() {
          _display = r.isNaN
              ? 'Err'
              : (r == r.roundToDouble()
                  ? r.toInt().toString()
                  : r.toStringAsFixed(4));
          _expr = '';
        });
      }
    } catch (_) {
      setState(() => _display = 'Err');
    }
  }

  void _openVaultPin() {
    final app = GizliAlanApp.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinLockScreen(
          onSuccess: () => app.enterVaultAfterPin(),
        ),
      ),
    );
  }

  Widget _btn(
    String label, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: color ?? GizliTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(
              height: 64,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: color == GizliTheme.mint
                        ? GizliTheme.bg
                        : GizliTheme.textPrimary,
                  ),
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
      backgroundColor: GizliTheme.bg,
      appBar: AppBar(
        title: Text(t('decoyTitle')),
        actions: [
          // Transparent path: always visible vault entry (not stealth-only).
          TextButton(
            onPressed: _openVaultPin,
            child: Text(t('openVault')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Text(
                  _display,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: GizliTheme.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                t('hintDecoy'),
                style: const TextStyle(
                  color: GizliTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Row(children: [
              _btn('C', onTap: _clear, color: GizliTheme.bgElevated),
              _btn('÷', onTap: () => _op('÷')),
              _btn('×', onTap: () => _op('×')),
              _btn('⌫', onTap: () {
                setState(() {
                  if (_display.length <= 1) {
                    _display = '0';
                  } else {
                    _display = _display.substring(0, _display.length - 1);
                  }
                });
              }),
            ]),
            Row(children: [
              _btn('7', onTap: () => _digit('7')),
              _btn('8', onTap: () => _digit('8')),
              _btn('9', onTap: () => _digit('9')),
              _btn('-', onTap: () => _op('-')),
            ]),
            Row(children: [
              _btn('4', onTap: () => _digit('4')),
              _btn('5', onTap: () => _digit('5')),
              _btn('6', onTap: () => _digit('6')),
              _btn('+', onTap: () => _op('+')),
            ]),
            Row(children: [
              _btn('1', onTap: () => _digit('1')),
              _btn('2', onTap: () => _digit('2')),
              _btn('3', onTap: () => _digit('3')),
              // Long-press "=" opens vault PIN (documented, not stealth spyware).
              _btn(
                '=',
                color: GizliTheme.mint,
                onTap: () {
                  _eqTapCount++;
                  if (_eqTapCount >= 4) {
                    _eqTapCount = 0;
                    _openVaultPin();
                  } else {
                    _equals();
                  }
                },
                onLongPress: _openVaultPin,
              ),
            ]),
            Row(children: [
              _btn('0', onTap: () => _digit('0'), flex: 2),
              _btn('.', onTap: () {
                if (!_display.contains('.')) {
                  setState(() => _display = '$_display.');
                }
              }),
              _btn('=', onTap: _equals, color: GizliTheme.mintDim),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
