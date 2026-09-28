import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../screens/paywall_screen.dart';
import '../screens/pro_screen.dart';
import '../services/pro_entitlement.dart';

/// Pro page for this build: Google Play paywall, or the local test stub
/// (debug builds only, see [Flavor.hasProStub]).
Widget proScreen() =>
    ProEntitlement.viaPlayBilling ? const PaywallScreen() : const ProScreen();

Future<void> openPro(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => proScreen()));

/// Honest "this needs Pro" dialog with a way to the paywall.
Future<void> showProRequired(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final t = L10n.current;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('pro_required'),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t('notNow')),
        ),
        FilledButton(
          key: const ValueKey('pro_required_open'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(t('proSeePlans')),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await openPro(context);
}

/// Free tier: at most [freeItemLimit] items (photos + files + notes) per
/// vault space. Items already stored are never locked or deleted; only new
/// additions stop at the limit.
class ItemLimit {
  const ItemLimit._();

  static const int freeItemLimit = 50;

  /// How many more items may be added (null = unlimited, Pro).
  static Future<int?> remaining(BuildContext context) async {
    final app = GizliAlanApp.of(context);
    if (ProEntitlement.isActive(app.settings)) return null;
    final s = app.session;
    if (s == null) return 0;
    final n =
        await s.gallery.count() + await s.files.count() + await s.notes.count();
    return leftFor(pro: false, stored: n);
  }

  /// Pure rule: null = unlimited (Pro); otherwise free slots, never < 0
  /// (a vault already above the limit keeps everything, it just can't grow).
  static int? leftFor({required bool pro, required int stored}) {
    if (pro) return null;
    final left = freeItemLimit - stored;
    return left < 0 ? 0 : left;
  }

  /// False (after showing the limit dialog) when nothing more may be added.
  static Future<bool> ensureRoom(BuildContext context) async {
    final left = await remaining(context);
    if (left == null || left > 0) return true;
    if (context.mounted) await showLimitReached(context);
    return false;
  }

  static Future<void> showLimitReached(BuildContext context) {
    final t = L10n.current;
    return showProRequired(
      context,
      title: t('limitTitle'),
      body: t('limitBody').replaceAll('{max}', '$freeItemLimit'),
    );
  }
}
