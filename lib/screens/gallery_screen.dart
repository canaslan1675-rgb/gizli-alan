import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/vault_session.dart';
import '../services/vault_storage.dart';
import '../theme.dart';
import '../widgets/vault_actions.dart';
import 'photo_viewer_screen.dart';

/// Encrypted photo gallery. Imports go through the system Photo Picker
/// (image_picker) — user-selected photos only, no media permission needed.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<VaultItem>> _future;

  VaultSession? _sessionRef;

  // Captured once: the session may be closed (auto-lock) while this route is
  // animating away, so never look it up again during build.
  VaultStorage? _storeRef;
  VaultStorage get _store => _storeRef!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storeRef == null) {
      _sessionRef = GizliAlanApp.of(context).session!;
      _storeRef = _sessionRef!.gallery;
      _future = _store.list();
    }
  }

  void _reload() => setState(() => _future = _store.list());

  Future<void> _import() async {
    final app = GizliAlanApp.of(context);
    final t = L10n.current;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await app.withExternalUi(
      () => ImagePicker().pickMultiImage(requestFullMetadata: false),
    );
    if (picked.isEmpty || !mounted) return;
    var count = 0;
    await runWithProgress(context, t('importing'), () async {
      for (final x in picked) {
        try {
          final bytes = await x.readAsBytes();
          await _store.add(name: x.name, bytes: bytes, mime: x.mimeType);
          count++;
        } catch (e) {
          debugPrint('import failed: $e');
        } finally {
          // image_picker copies picks into our cache dir: remove plaintext.
          try {
            final f = File(x.path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
    });
    if (count > 0) {
      await _store.events?.add(VaultEventType.galleryImported, {'n': '$count'});
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t('importedN').replaceAll('{n}', '$count')),
        duration: const Duration(seconds: 5),
      ),
    );
    _reload();
  }

  Future<void> _openViewer(List<VaultItem> items, int i) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PhotoViewerScreen(store: _store, items: items, initialIndex: i),
      ),
    );
    _reload();
  }

  /// Long-press options: open, export, set as vault home background, delete.
  Future<void> _showOptions(List<VaultItem> items, int i) async {
    final t = L10n.current;
    final item = items[i];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              key: const ValueKey('photo_opt_open'),
              leading: const Icon(Icons.open_in_full),
              title: Text(t('open')),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            if (item.isImage)
              ListTile(
                key: const ValueKey('photo_opt_background'),
                leading: const Icon(Icons.wallpaper_outlined),
                title: Text(t('setAsHomeBackground')),
                onTap: () => Navigator.pop(ctx, 'background'),
              ),
            ListTile(
              key: const ValueKey('photo_opt_export'),
              leading: const Icon(Icons.ios_share),
              title: Text(t('export')),
              onTap: () => Navigator.pop(ctx, 'export'),
            ),
            ListTile(
              key: const ValueKey('photo_opt_delete'),
              leading: const Icon(
                Icons.delete_outline,
                color: GizliTheme.danger,
              ),
              title: Text(
                t('delete'),
                style: const TextStyle(color: GizliTheme.danger),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (choice) {
      case 'open':
        await _openViewer(items, i);
      case 'background':
        // Stays inside the vault: only this photo's id is stored (encrypted);
        // the vault home decrypts it into memory.
        await _sessionRef!.setHomeBackgroundId(item.id);
        messenger.showSnackBar(SnackBar(content: Text(t('homeBackgroundSet'))));
      case 'export':
        await VaultActions.export(context, _store, item);
      case 'delete':
        if (!await VaultActions.confirmDelete(context)) return;
        await _store.delete(item);
        await _store.events?.add(VaultEventType.itemDeleted, {
          'name': item.name,
        });
        _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('gallery'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(t('importPhotos')),
      ),
      body: FutureBuilder<List<VaultItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return _Empty(text: t('emptyGallery'));
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 88),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _Thumb(
              key: ValueKey('gallery_thumb_$i'),
              store: _store,
              item: items[i],
              onTap: () => _openViewer(items, i),
              onLongPress: () => _showOptions(items, i),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({
    super.key,
    required this.store,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });
  final VaultStorage store;
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  late final Future<Uint8List> _bytes = widget.store.read(widget.item);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          color: GizliTheme.bgCard,
          child: FutureBuilder<Uint8List>(
            future: _bytes,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: GizliTheme.textSecondary,
                  ),
                );
              }
              return Image.memory(
                snap.data!,
                fit: BoxFit.cover,
                cacheWidth: 360,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: GizliTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GizliTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
