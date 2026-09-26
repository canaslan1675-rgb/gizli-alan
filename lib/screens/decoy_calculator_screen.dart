import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/calculator_engine.dart';
import '../services/pro_entitlement.dart';
import '../services/vault_space.dart';
import '../theme.dart';

/// A fully working calculator.
///
/// When [vaultEntry] is true it is also the (disclosed) vault entrance:
/// typing the PIN and pressing `=` opens the vault; long-pressing `=` starts
/// biometric unlock if enabled. The info button in the app bar explains this,
/// as do onboarding and the store listing — nothing is hidden from users or
/// reviewers. Inside the vault the same calculator is available as a plain
/// tool ([vaultEntry] = false).
class DecoyCalculatorScreen extends StatefulWidget {
  const DecoyCalculatorScreen({super.key, this.vaultEntry = false});

  final bool vaultEntry;

  @override
  State<DecoyCalculatorScreen> createState() => _DecoyCalculatorScreenState();
}

class _DecoyCalculatorScreenState extends State<DecoyCalculatorScreen> {
  final _engine = CalculatorEngine();
  bool _checking = false;

  Future<void> _press(String key) async {
    if (_checking) return;
    if (key == '=' && widget.vaultEntry) {
      final candidate = _engine.pinCandidate;
      if (candidate != null) {
        final app = GizliAlanApp.of(context);
        setState(() => _checking = true);
        final result = await app.auth.check(candidate, countFailure: false);
        if (!mounted) return;
        setState(() => _checking = false);
        if (result == PinCheck.real || result == PinCheck.decoy) {
          setState(_engine.clear);
          await app.enterVault(
            result == PinCheck.real ? VaultSpace.real : VaultSpace.decoy,
          );
          return;
        }
      }
    }
    setState(() => _engine.input(key));
  }

  Future<void> _biometric() async {
    if (!widget.vaultEntry) return;
    final app = GizliAlanApp.of(context);
    if (!app.settings.biometricEnabled) return;
    await app.unlockWithBiometrics();
  }

  void _showInfo() {
    final t = L10n.current;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('calcInfoTitle')),
        content: Text(
          ProEntitlement.available
              ? '${t('calcInfoBody')}\n\n${t('calcInfoProHint')}'
              : t('calcInfoBody'),
          key: const ValueKey('calc_info_body'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('ok'))),
        ],
      ),
    );
  }

  Widget _key(String label, {Color? bg, Color? fg, int flex = 1}) {
    final isEq = label == '=';
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: bg ?? GizliTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: ValueKey('calc_$label'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => _press(label),
            onLongPress: isEq ? _biometric : null,
            child: SizedBox(
              height: 68,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: fg ?? GizliTheme.textPrimary,
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
    final t = L10n.of(context);
    const opBg = GizliTheme.bgElevated;
    const opFg = GizliTheme.mint;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('decoyTitle')),
        actions: [
          // Pro members may opt in to hide this button (ProEntitlement);
          // when hidden it is removed entirely (no empty tap target).
          if (widget.vaultEntry &&
              !ProEntitlement.hideCalculatorInfo(
                GizliAlanApp.of(context).settings,
              ))
            IconButton(
              key: const ValueKey('calc_info'),
              icon: const Icon(Icons.info_outline),
              tooltip: t('calcInfoTitle'),
              onPressed: _showInfo,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.bottomRight,
                // scaleDown keeps the display readable on short screens.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _engine.expression,
                        key: const ValueKey('calc_expression'),
                        maxLines: 2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          color: GizliTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _engine.display,
                          key: const ValueKey('calc_display'),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            color: GizliTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      _key('C', bg: opBg, fg: GizliTheme.danger),
                      _key('⌫', bg: opBg, fg: opFg),
                      _key('%', bg: opBg, fg: opFg),
                      _key('÷', bg: opBg, fg: opFg),
                    ],
                  ),
                  Row(
                    children: [
                      _key('7'),
                      _key('8'),
                      _key('9'),
                      _key('×', bg: opBg, fg: opFg),
                    ],
                  ),
                  Row(
                    children: [
                      _key('4'),
                      _key('5'),
                      _key('6'),
                      _key('−', bg: opBg, fg: opFg),
                    ],
                  ),
                  Row(
                    children: [
                      _key('1'),
                      _key('2'),
                      _key('3'),
                      _key('+', bg: opBg, fg: opFg),
                    ],
                  ),
                  Row(
                    children: [
                      _key('±', bg: opBg, fg: opFg),
                      _key('0'),
                      _key('.'),
                      _key('=', bg: GizliTheme.mint, fg: GizliTheme.bg),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
