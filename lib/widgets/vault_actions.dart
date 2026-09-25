import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/vault_storage.dart';
import '../theme.dart';

/// Shared UI actions for encrypted vault items.
class VaultActions {
  /// Decrypts [item] and lets the user pick a destination via the system
  /// "save as" dialog (Storage Access Framework — no storage permission, no
  /// plaintext temp copy written by us).
  static Future<void> export(
    BuildContext context,
    VaultStorage storage,
    VaultItem item,
  ) async {
    final app = GizliAlanApp.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final t = L10n.current;
    try {
      final bytes = await storage.read(item);
      final uri = await app.withExternalUi(
        () => FilePicker.saveFile(
          fileName: item.name,
          bytes: bytes,
          mimeType: item.mime,
          dialogTitle: t('export'),
        ),
      );
      if (uri != null) {
        messenger.showSnackBar(SnackBar(content: Text(t('exported'))));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${t('exportFailed')}: $e')),
      );
    }
  }

  static Future<bool> confirmDelete(BuildContext context) async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('deleteItemConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GizliTheme.danger),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Shows a modal progress dialog while [task] runs.
Future<T> runWithProgress<T>(
  BuildContext context,
  String label,
  Future<T> Function() task,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
