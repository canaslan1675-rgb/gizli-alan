import 'package:flutter/material.dart';

import '../flavor.dart';
import '../l10n/l10n.dart';
import '../services/pro_entitlement.dart';
import '../theme.dart';

/// Short in-app guide (v0.5.3 polish): expandable sections for calculator
/// entry, appearance, share/rate/feedback, decoy PIN, vault, PIN recovery
/// and — in builds that have it — the Second phone (work profile).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = GizliColors.of(context);
    final sections = <(IconData, String, String, bool)>[
      (Icons.calculate_outlined, t('helpCalcTitle'), t('helpCalcBody'), true),
      (
        Icons.palette_outlined,
        t('helpAppearanceTitle'),
        t('helpAppearanceBody'),
        false,
      ),
      (Icons.share_outlined, t('helpShareTitle'), t('helpShareBody'), false),
      (
        Icons.theater_comedy_outlined,
        t('helpDecoyTitle'),
        t('helpDecoyBody'),
        false,
      ),
      (Icons.lock_outline, t('helpVaultTitle'), t('helpVaultBody'), false),
      if (Flavor.hasSecondPhone)
        (
          Icons.phone_android_outlined,
          t('helpSecondPhoneTitle'),
          ProEntitlement.available
              ? '${t('helpSecondPhoneBody')} ${t('helpSecondPhonePro')}'
              : t('helpSecondPhoneBody'),
          false,
        ),
      (Icons.key_off_outlined, t('helpPinTitle'), t('helpPinBody'), false),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t('helpTitle'))),
      body: ListView(
        key: const ValueKey('help_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final (icon, title, body, initiallyExpanded) in sections)
            _HelpSection(
              icon: icon,
              title: title,
              body: body,
              initiallyExpanded: initiallyExpanded,
              colors: c,
            ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.initiallyExpanded,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool initiallyExpanded;
  final GizliColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.textSecondary.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('help_section_$title'),
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Icon(icon, color: c.accent),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            iconColor: c.accent,
            collapsedIconColor: c.textSecondary,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  body,
                  style: TextStyle(color: c.textSecondary, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
