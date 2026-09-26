import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/pro_entitlement.dart';
import '../services/vault_storage.dart';
import '../theme.dart';
import '../widgets/import_delete_originals.dart';
import '../widgets/vault_actions.dart';
import 'photo_viewer_screen.dart';

/// Encrypted document vault (PDFs, any file). Imports only via the system
/// file picker (user-initiated, Storage Access Framework, no permission).
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  VaultStorage? _storeRef;
  VaultStorage get _store => _storeRef!;
  late Future<List<VaultItem>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storeRef == null) {
      _storeRef = GizliAlanApp.of(context).session!.files;
      _future = _store.list();
    }
  }

  void _reload() => setState(() => _future = _store.list());

  Future<void> _import() async {
    final app = GizliAlanApp.of(context);
    if (ProEntitlement.deleteOriginalAfterImport(app.settings)) {
      await importDeletingOriginals(
        context,
        _store,
        images: false,
        event: VaultEventType.filesImported,
      );
      if (mounted) _reload();
      return;
    }
    final t = L10n.current;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await app.withExternalUi(() => FilePicker.pickFiles());
    if (picked.isEmpty || !mounted) return;
    var count = 0;
    var tooBig = 0;
    await runWithProgress(context, t('importing'), () async {
      for (final f in picked) {
        try {
          final len = await f.length();
          if (len != null && len > VaultStorage.maxItemBytes) {
            tooBig++;
            continue;
          }
          await _store.add(name: f.name, bytes: await f.readAsBytes());
          count++;
        } catch (e) {
          debugPrint('file import failed: $e');
        }
      }
      await FilePicker.clearTemporaryFiles();
    });
    if (count > 0) {
      await _store.events?.add(VaultEventType.filesImported, {'n': '$count'});
    }
    if (!mounted) return;
    var msg = t('importedFilesN').replaceAll('{n}', '$count');
    if (tooBig > 0) msg += ' ${t('tooBig')}';
    messenger.showSnackBar(SnackBar(content: Text(msg)));
    _reload();
  }

  Future<void> _itemMenu(VaultItem item, List<VaultItem> all) async {
    final t = L10n.current;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(item.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(VaultActions.formatSize(item.size)),
            ),
            if (item.isImage)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(t('view')),
                onTap: () => Navigator.pop(ctx, 'view'),
              ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(t('export')),
              onTap: () => Navigator.pop(ctx, 'export'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: GizliTheme.danger,
              ),
              title: Text(t('delete')),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'view':
        final images = all.where((i) => i.isImage).toList();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhotoViewerScreen(
              store: _store,
              items: images,
              initialIndex: images.indexOf(item),
            ),
          ),
        );
        _reload();
        break;
      case 'export':
        await VaultActions.export(context, _store, item);
        break;
      case 'delete':
        if (await VaultActions.confirmDelete(context)) {
          await _store.delete(item);
          await _store.events?.add(VaultEventType.itemDeleted, {
            'name': item.name,
          });
          _reload();
        }
        break;
    }
  }

  IconData _iconFor(VaultItem i) {
    if (i.isImage) return Icons.image_outlined;
    if (i.mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (i.mime.startsWith('video/')) return Icons.movie_outlined;
    if (i.mime.startsWith('text/')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('files'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.file_upload_outlined),
        label: Text(t('importFile')),
      ),
      body: FutureBuilder<List<VaultItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t('emptyFiles'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GizliTheme.textSecondary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: Icon(_iconFor(item), color: GizliTheme.mint),
                title: Text(item.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  VaultActions.formatSize(item.size),
                  style: const TextStyle(
                    color: GizliTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.more_vert),
                onTap: () => _itemMenu(item, items),
              );
            },
          );
        },
      ),
    );
  }
}
