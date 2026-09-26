import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/original_import.dart';
import '../services/vault_storage.dart';
import 'vault_actions.dart';

/// Import flow used when "Delete original after import" is effective
/// (ProEntitlement.deleteOriginalAfterImport). Picks via the system document
/// picker, encrypts each item into [store], reads it back to verify, then
/// asks Android to delete ONLY the verified originals. Failures/declines keep
/// the vault copy and show a non-blocking notice.
Future<void> importDeletingOriginals(
  BuildContext context,
  VaultStorage store, {
  required bool images,
  required VaultEventType event,
}) async {
  final app = GizliAlanApp.of(context);
  final t = L10n.current;
  final messenger = ScaffoldMessenger.of(context);
  final picked = await app.withExternalUi(
    () => OriginalImport.pick(images: images),
  );
  if (picked.isEmpty || !context.mounted) return;
  var safe = <String>[];
  var tooBig = 0;
  await runWithProgress(context, t('importing'), () async {
    safe = await OriginalImport.importAll(
      picked,
      maxBytes: VaultStorage.maxItemBytes,
      onTooBig: (_) => tooBig++,
      store: (s, bytes) => store.add(name: s.name, bytes: bytes, mime: s.mime),
      verify: (stored, bytes) async {
        final back = await store.read(stored as VaultItem);
        return back.length == bytes.length;
      },
    );
  });
  if (safe.isNotEmpty) {
    await store.events?.add(event, {'n': '${safe.length}'});
  }
  // System confirmation dialog (Android 11+) → keep the vault unlocked.
  final outcome = await app.withExternalUi(
    () => OriginalImport.deleteOriginals(safe),
  );
  var msg = (images ? t('importedN') : t('importedFilesN')).replaceAll(
    '{n}',
    '${safe.length}',
  );
  if (tooBig > 0) msg += ' ${t('tooBig')}';
  if (outcome.deleted > 0) {
    msg += ' ${t('originalsDeletedN').replaceAll('{n}', '${outcome.deleted}')}';
  }
  if (outcome.failed > 0) {
    msg +=
        ' ${outcome.declined ? t('originalsDeclined') : t('originalsKeptN').replaceAll('{n}', '${outcome.failed}')}';
  }
  messenger.showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
  );
}
