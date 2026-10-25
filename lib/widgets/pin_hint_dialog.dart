import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';

/// Edit the PIN hint (0.6.0 F). Returns true when saved.
Future<bool> editPinHint(BuildContext context) async {
  final app = GizliAlanApp.of(context);
  final t = L10n.current;
  final ctrl = TextEditingController(text: await app.auth.pinHint() ?? '');
  if (!context.mounted) return false;
  String? error;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        key: const ValueKey('pin_hint_dialog'),
        title: Text(t('pinHint')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('pinHintExplain')),
            TextField(
              key: const ValueKey('pin_hint_field'),
              controller: ctrl,
              maxLength: AuthService.maxHintLength,
              decoration: InputDecoration(
                labelText: t('pinHint'),
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('pin_hint_save'),
            onPressed: () async {
              try {
                await app.auth.setPinHint(ctrl.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } on ArgumentError {
                setLocal(() => error = t('pinHintBad'));
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return saved == true;
}
