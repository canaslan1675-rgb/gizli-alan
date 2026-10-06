import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/privacy_link.dart';
import '../services/pro_billing.dart';
import '../theme.dart';
import '../widgets/pro_gate.dart';

/// Google Play subscription page for GizliAlan Pro (`play` flavor).
/// Prices always come from Play ([ProPlan.price]); nothing is preselected,
/// no countdowns, restore and "manage in Google Play" are always visible.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static const String manageUrl =
      'https://play.google.com/store/account/subscriptions'
      '?sku=$kProProductId&package=com.offerforge.gizlialan';

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  GizliColors get gc => GizliColors.of(context);

  ProBilling? _billing;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = GizliAlanApp.of(context).billing;
    if (b != _billing) {
      _billing?.removeListener(_changed);
      _billing = b?..addListener(_changed);
    }
  }

  @override
  void dispose() {
    _billing?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final n = _billing?.takeNotice();
    if (n != null) _show(n);
    setState(() {});
  }

  void _show(BillingNotice n) {
    final t = L10n.current;
    final key = switch (n) {
      BillingNotice.purchased => 'payPurchased',
      BillingNotice.pending => 'payPending',
      BillingNotice.canceled => 'payCanceled',
      BillingNotice.error => 'payError',
      BillingNotice.unavailable => 'payUnavailable',
      BillingNotice.restored => 'payRestored',
      BillingNotice.nothingToRestore => 'payNothing',
      BillingNotice.offline => 'payOffline',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t(key))));
  }

  Future<void> _run(Future<void> Function(ProBilling b) f) async {
    final b = _billing;
    if (b == null) {
      _show(BillingNotice.unavailable);
      return;
    }
    setState(() => _busy = true);
    try {
      // The Play sheet backgrounds the app: don't auto-lock meanwhile.
      await GizliAlanApp.of(context).withExternalUi(() => f(b));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manage() async {
    final ok = await GizliAlanApp.of(
      context,
    ).withExternalUi(() => PrivacyLink.open(PaywallScreen.manageUrl));
    if (!ok && mounted) _show(BillingNotice.unavailable);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final b = _billing;
    final app = GizliAlanApp.of(context);
    final isPro = app.settings.playProActive;
    final loading = b?.loading ?? false;
    final available = b?.available ?? false;
    final plans = b?.plans ?? const <ProPlan>[];
    Widget planButton(String id, String titleKey, String perKey) {
      final p = b?.plan(id);
      if (p == null) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          key: ValueKey('pay_$id'),
          title: Text(t(titleKey)),
          subtitle: Text(
            [
              t(perKey).replaceAll('{price}', p.price),
              if (p.hasTrial) t('payTrial'),
            ].join('\n'),
          ),
          trailing: FilledButton(
            onPressed: _busy || isPro ? null : () => _run((b) => b.buy(p)),
            child: Text(t('proSubscribe')),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('proTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('payIntro')),
          const SizedBox(height: 12),
          for (final f in [
            t('payF1'),
            t('payF2').replaceAll('{max}', '${ItemLimit.freeItemLimit}'),
            t('payF3'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 18, color: gc.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (isPro)
            ListTile(
              key: const ValueKey('pay_active'),
              leading: Icon(Icons.verified, color: gc.accent),
              title: Text(t('payActive')),
            )
          else if (loading)
            ListTile(
              leading: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(t('payLoading')),
            )
          else if (!available)
            Text(
              t('payUnavailable'),
              key: const ValueKey('pay_unavailable'),
              style: TextStyle(color: gc.textSecondary),
            )
          else if (plans.isEmpty)
            Text(
              t('payNoPlans'),
              key: const ValueKey('pay_no_plans'),
              style: TextStyle(color: gc.textSecondary),
            )
          else ...[
            planButton(kPlanMonthly, 'payMonthly', 'payPerMonth'),
            planButton(kPlanYearly, 'payYearly', 'payPerYear'),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('pay_restore'),
            onPressed: _busy ? null : () => _run((b) => b.restore()),
            icon: const Icon(Icons.restore),
            label: Text(t('payRestore')),
          ),
          TextButton.icon(
            key: const ValueKey('pay_manage'),
            onPressed: _manage,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(t('payManage')),
          ),
          const SizedBox(height: 8),
          Text(
            t('payTerms'),
            style: TextStyle(fontSize: 12, color: gc.textSecondary),
          ),
        ],
      ),
    );
  }
}
