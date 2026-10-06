import 'package:flutter/material.dart';

import '../flavor.dart';
import '../l10n/l10n.dart';
import '../services/pro_entitlement.dart';
import '../theme.dart';

/// Short in-app guide (v0.5.1, tester feedback): calculator entry, decoy
/// PIN, vault, PIN recovery and — in builds that have it — the Second phone
/// (work profile). TR/EN via [L10n].
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = GizliColors.of(context);
    final sections = <(IconData, String, String)>[
      (Icons.calculate_outlined, t('helpCalcTitle'), t('helpCalcBody')),
      (Icons.theater_comedy_outlined, t('helpDecoyTitle'), t('helpDecoyBody')),
      (Icons.lock_outline, t('helpVaultTitle'), t('helpVaultBody')),
      if (Flavor.hasSecondPhone)
        (
          Icons.phone_android_outlined,
          t('helpSecondPhoneTitle'),
          ProEntitlement.available
              ? '${t('helpSecondPhoneBody')} ${t('helpSecondPhonePro')}'
              : t('helpSecondPhoneBody'),
        ),
      (Icons.key_off_outlined, t('helpPinTitle'), t('helpPinBody')),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t('helpTitle'))),
      body: ListView(
        key: const ValueKey('help_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final (icon, title, body) in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: c.textSecondary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: c.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(color: c.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
