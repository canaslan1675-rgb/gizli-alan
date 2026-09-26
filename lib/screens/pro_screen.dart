import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/pro_entitlement.dart';
import '../theme.dart';

/// "GizliAlan Pro" plans — UI stub only.
///
/// Shows the planned pricing from the brief (§4). There is NO billing code:
/// no Play Billing library, no network, no purchase. The buttons only explain
/// that purchases are not available in this test build. The free item limit
/// is displayed but not enforced (see DECISIONS.md).
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  /// Planned free-tier limit (brief: 30–50 items). Display only for now.
  static const int freeItemLimit = 50;

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  int? _items;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _count();
  }

  Future<void> _count() async {
    final s = GizliAlanApp.of(context).session;
    if (s == null) return;
    final n =
        await s.gallery.count() + await s.files.count() + await s.notes.count();
    if (mounted) setState(() => _items = n);
  }

  void _notAvailable() {
    final t = L10n.current;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('proNotAvailableTitle')),
        content: Text(t('proNotAvailableBody')),
        actions: [
          TextButton(
            key: const ValueKey('pro_dialog_ok'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final usage = _items == null
        ? null
        : t('proUsage')
              .replaceAll('{n}', '$_items')
              .replaceAll('{max}', '${ProScreen.freeItemLimit}');
    return Scaffold(
      appBar: AppBar(title: Text(t('proTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GizliTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GizliTheme.warning.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: GizliTheme.warning),
                const SizedBox(width: 10),
                Expanded(
                  key: const ValueKey('pro_test_build_note'),
                  child: Text(t('proTestBuildNote')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Test builds only: simulate an active Pro entitlement (no billing).
          SwitchListTile(
            key: const ValueKey('pro_stub_toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(t('proStubToggle')),
            subtitle: Text(t('proStubToggleHint')),
            value: ProEntitlement.isActive(app.settings),
            onChanged: (v) async {
              await app.settings.setProStubActive(v);
              app.refresh();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _PlanCard(
            key: const ValueKey('plan_free'),
            title: t('proFree'),
            price: t('proFreePrice'),
            features: [
              t('proFreeF1').replaceAll('{max}', '${ProScreen.freeItemLimit}'),
              t('proFreeF2'),
              t('proFreeF3'),
            ],
            footer: usage,
            current: true,
          ),
          _PlanCard(
            key: const ValueKey('plan_monthly'),
            title: t('proMonthly'),
            price: t('proMonthlyPrice'),
            features: [t('proF1'), t('proF2'), t('proF3')],
            action: t('proSubscribe'),
            onAction: _notAvailable,
          ),
          _PlanCard(
            key: const ValueKey('plan_yearly'),
            title: t('proYearly'),
            price: t('proYearlyPrice'),
            badge: t('proYearlyHint'),
            features: [t('proF1'), t('proF2'), t('proF3')],
            action: t('proSubscribe'),
            onAction: _notAvailable,
          ),
          const SizedBox(height: 8),
          Text(
            t('proFooter'),
            style: const TextStyle(
              fontSize: 12,
              color: GizliTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    this.footer,
    this.action,
    this.onAction,
    this.current = false,
    this.badge,
  });

  /// Highlight chip, e.g. "En avantajlı / Best value".
  final String? badge;

  final String title;
  final String price;
  final List<String> features;
  final String? footer;
  final String? action;
  final VoidCallback? onAction;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (current)
                  Chip(
                    label: Text(t('proCurrent')),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(fontSize: 16, color: GizliTheme.mint),
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Chip(
                key: const ValueKey('plan_best_value'),
                label: Text(badge!),
                visualDensity: VisualDensity.compact,
                backgroundColor: GizliTheme.mint.withValues(alpha: 0.18),
              ),
            ],
            const SizedBox(height: 8),
            for (final f in features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 18, color: GizliTheme.mint),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: const TextStyle(color: GizliTheme.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAction,
                  child: Text(action!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
