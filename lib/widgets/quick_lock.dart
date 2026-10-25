import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';

/// Quick lock (0.6.0 D): one tap in any vault screen's app bar locks the
/// vault immediately (same path as the dock's Lock button). In-app only — no
/// icon hiding, no second launcher, no accessibility service.
class QuickLockButton extends StatelessWidget {
  const QuickLockButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('quick_lock'),
    tooltip: L10n.of(context)('quickLock'),
    icon: const Icon(Icons.lock_outline),
    onPressed: () => GizliAlanApp.of(context).lockVaultExplicit(),
  );
}
