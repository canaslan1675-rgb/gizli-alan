import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/pro_entitlement.dart';
import '../services/vault_backup.dart';
import 'pro_gate.dart';
import 'vault_actions.dart';

/// Settings actions for the encrypted one-file backup (0.6.0 L). The file
/// is written/read only through the system document dialog (SAF); no
/// account, server or network is involved.
class BackupActions {
  const BackupActions._();

  static Future<String?> _password(
    BuildContext context, {
    required bool confirm,
  }) async {
    final t = L10n.current;
    final p1 = TextEditingController();
    final p2 = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          key: const ValueKey('backup_password_dialog'),
          title: Text(t(confirm ? 'backupCreate' : 'backupRestore')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(confirm ? 'backupPasswordExplain' : 'backupRestoreExplain'),
              ),
              TextField(
                key: const ValueKey('backup_password'),
                controller: p1,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t('backupPassword'),
                  errorText: error,
                ),
              ),
              if (confirm)
                TextField(
                  key: const ValueKey('backup_password2'),
                  controller: p2,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t('backupPasswordConfirm'),
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
              key: const ValueKey('backup_password_ok'),
              onPressed: () {
                if (!VaultBackup.isValidPassword(p1.text)) {
                  setLocal(() => error = t('backupPasswordShort'));
                } else if (confirm && p1.text != p2.text) {
                  setLocal(() => error = t('pinMismatch'));
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(t('continue')),
            ),
          ],
        ),
      ),
    );
    final pw = ok == true ? p1.text : null;
    p1.dispose();
    p2.dispose();
    return pw;
  }

  /// Pro: encrypt the open space into one file the user saves via SAF.
  static Future<void> create(BuildContext context) async {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);
    if (!ProEntitlement.isActive(app.settings)) {
      return showProRequired(
        context,
        title: t('backupProTitle'),
        body: t('backupProBody'),
      );
    }
    final session = app.session;
    if (session == null) return;
    final pw = await _password(context, confirm: true);
    if (pw == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await runWithProgress(
        context,
        t('backupWorking'),
        () => VaultBackup().create(session, pw),
      );
      final uri = await app.withExternalUi(
        () => FilePicker.saveFile(
          fileName: VaultBackup.fileName,
          bytes: bytes,
          mimeType: 'application/octet-stream',
          dialogTitle: t('backupCreate'),
        ),
      );
      if (uri != null) {
        messenger.showSnackBar(SnackBar(content: Text(t('backupSaved'))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t('backupFailed'))));
    }
  }

  /// Restore (free, so nobody is ever locked out of their own backup):
  /// pick the file via SAF, enter its password, merge into this space.
  static Future<void> restore(BuildContext context) async {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);
    final session = app.session;
    if (session == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await app.withExternalUi(() => FilePicker.pickFiles());
    if (picked.isEmpty || !context.mounted) return;
    final pw = await _password(context, confirm: false);
    if (pw == null || !context.mounted) return;
    try {
      final data = await picked.first.readAsBytes();
      if (!context.mounted) return;
      final r = await runWithProgress(
        context,
        t('backupWorking'),
        () => VaultBackup().restore(session, data, pw),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t('backupRestored')
                .replaceAll('{p}', '${r.photos}')
                .replaceAll('{f}', '${r.files}')
                .replaceAll('{n}', '${r.notes}'),
          ),
        ),
      );
    } on BackupException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t(e.reason == 'password' ? 'backupWrongPassword' : 'backupBadFile'),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t('backupBadFile'))));
    } finally {
      await FilePicker.clearTemporaryFiles();
    }
  }
}
