import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/quick_lock.dart';
import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/vault_session.dart';
import '../services/pro_entitlement.dart';
import '../services/gallery_albums.dart';
import '../services/vault_storage.dart';
import '../theme.dart';
import '../widgets/import_delete_originals.dart';
import '../widgets/pro_gate.dart';
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
  GizliColors get gc => GizliColors.of(context);

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
      _loadAlbums();
    }
  }

  void _reload() {
    final next = _store.list();
    setState(() {
      _future = next;
    });
    _loadAlbums();
  }

  // ------------------------------------------------------------ albums (H)
  List<Album> _albums = const [];
  String? _album; // selected album id; null = all photos

  Future<void> _loadAlbums() async {
    final a = await _sessionRef!.albums.list();
    if (!mounted) return;
    setState(() {
      _albums = a;
      if (_album != null && !a.any((x) => x.id == _album)) _album = null;
    });
  }

  Future<String?> _askName(String title, [String initial = '']) async {
    final t = L10n.current;
    final c = TextEditingController(text: initial);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: const ValueKey('album_name'),
          controller: c,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(labelText: t('albumName')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('album_name_ok'),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(t('save')),
          ),
        ],
      ),
    );
    c.dispose();
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<Album?> _createAlbum() async {
    final t = L10n.current;
    final pro = ProEntitlement.isActive(GizliAlanApp.of(context).settings);
    if (!AlbumLimit.canCreate(pro: pro, existing: _albums.length)) {
      await showProRequired(
        context,
        title: t('albumLimitTitle'),
        body: t('albumLimitBody'),
      );
      return null;
    }
    final name = await _askName(t('albumNew'));
    if (name == null || !mounted) return null;
    final a = await _sessionRef!.albums.create(name, pro: pro);
    await _loadAlbums();
    return a;
  }

  Future<void> _albumOptions(Album a) async {
    final t = L10n.current;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(t('albumRename')),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              key: const ValueKey('album_delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(t('albumDelete')),
              subtitle: Text(t('albumDeleteSub')),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'rename') {
      final n = await _askName(t('albumRename'), a.name);
      if (n != null) await _sessionRef!.albums.rename(a.id, n);
    } else if (choice == 'delete') {
      await _sessionRef!.albums.delete(a.id);
    }
    _reload();
  }

  Future<void> _moveToAlbum(VaultItem item) async {
    final t = L10n.current;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in _albums)
              ListTile(
                key: ValueKey('move_album_${a.id}'),
                leading: Icon(
                  item.album == a.id ? Icons.check : Icons.photo_album_outlined,
                ),
                title: Text(a.name),
                onTap: () => Navigator.pop(ctx, a.id),
              ),
            ListTile(
              key: const ValueKey('move_album_new'),
              leading: const Icon(Icons.add),
              title: Text(t('albumNew')),
              onTap: () => Navigator.pop(ctx, '+'),
            ),
            if (item.album != null)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(t('albumRemoveFrom')),
                onTap: () => Navigator.pop(ctx, '-'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    String? target;
    if (choice == '+') {
      target = (await _createAlbum())?.id;
      if (target == null) return;
    } else if (choice != '-') {
      target = choice;
    }
    await _sessionRef!.albums.move(item, target);
    _reload();
  }

  Widget _albumBar(L10n t) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            key: const ValueKey('album_all'),
            label: Text(t('albumAll')),
            selected: _album == null,
            onSelected: (_) => setState(() => _album = null),
          ),
        ),
        for (final a in _albums)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onLongPress: () => _albumOptions(a),
              child: ChoiceChip(
                key: ValueKey('album_${a.id}'),
                label: Text(a.name),
                selected: _album == a.id,
                onSelected: (_) => setState(() => _album = a.id),
              ),
            ),
          ),
        ActionChip(
          key: const ValueKey('album_add'),
          avatar: const Icon(Icons.add, size: 18),
          label: Text(t('albumNew')),
          onPressed: _createAlbum,
        ),
      ],
    ),
  );

  Future<void> _import() async {
    final app = GizliAlanApp.of(context);
    // Free tier: stop at the item limit (stored items are never touched).
    final left = await ItemLimit.remaining(context);
    if (!mounted) return;
    if (left == 0) return ItemLimit.showLimitReached(context);
    if (ProEntitlement.deleteOriginalAfterImport(app.settings)) {
      await importDeletingOriginals(
        context,
        _store,
        images: true,
        event: VaultEventType.galleryImported,
        maxCount: left,
      );
      if (mounted) _reload();
      return;
    }
    final t = L10n.current;
    final messenger = ScaffoldMessenger.of(context);
    var picked = await app.withExternalUi(
      () => ImagePicker().pickMultiImage(requestFullMetadata: false),
    );
    if (picked.isEmpty || !mounted) return;
    final overLimit = left != null && picked.length > left;
    if (overLimit) {
      // Remove the plaintext cache copies we won't import.
      for (final x in picked.skip(left)) {
        try {
          await File(x.path).delete();
        } catch (_) {}
      }
      picked = picked.take(left).toList();
    }
    if (!mounted) return;
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
    if (overLimit) {
      await ItemLimit.showLimitReached(context);
      return;
    }
    if (count > 0) await _askDeleteOriginalsOnce();
  }

  /// One-time prompt after the first successful gallery import while
  /// "Delete original after import" is off. The answer is remembered.
  Future<void> _askDeleteOriginalsOnce() async {
    if (!mounted) return;
    final s = GizliAlanApp.of(context).settings;
    if (s.deleteOriginalAfterImport || s.deleteOriginalAsked) return;
    final t = L10n.current;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('delete_original_ask'),
        title: Text(t('deleteOriginalAskTitle')),
        content: Text(t('deleteOriginalAskBody')),
        actions: [
          TextButton(
            key: const ValueKey('delete_original_ask_no'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('deleteOriginalAskNo')),
          ),
          TextButton(
            key: const ValueKey('delete_original_ask_yes'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('deleteOriginalAskYes')),
          ),
        ],
      ),
    );
    if (yes == null) return; // dismissed: ask again next time
    await s.setDeleteOriginalAsked();
    if (yes) await s.setDeleteOriginalAfterImport(true);
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
              key: const ValueKey('photo_opt_album'),
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(t('albumMoveTo')),
              onTap: () => Navigator.pop(ctx, 'album'),
            ),
            ListTile(
              key: const ValueKey('photo_opt_export'),
              leading: const Icon(Icons.ios_share),
              title: Text(t('export')),
              onTap: () => Navigator.pop(ctx, 'export'),
            ),
            ListTile(
              key: const ValueKey('photo_opt_delete'),
              leading: Icon(Icons.delete_outline, color: gc.danger),
              title: Text(t('delete'), style: TextStyle(color: gc.danger)),
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
      case 'album':
        await _moveToAlbum(item);
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
      appBar: AppBar(
        title: Text(t('gallery')),
        actions: const [QuickLockButton()],
      ),
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
          final all = snap.data!;
          if (all.isEmpty) {
            return _Empty(text: t('emptyGallery'));
          }
          final items = _album == null
              ? all
              : all.where((i) => i.album == _album).toList();
          return Column(
            children: [
              _albumBar(t),
              Expanded(
                child: items.isEmpty
                    ? _Empty(text: t('albumEmpty'))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 88),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                      ),
              ),
            ],
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
  GizliColors get gc => GizliColors.of(context);

  late final Future<Uint8List> _bytes = widget.store.read(widget.item);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          color: gc.bgCard,
          child: FutureBuilder<Uint8List>(
            future: _bytes,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                  child: Icon(Icons.lock_outline, color: gc.textSecondary),
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
    final gc = GizliColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: gc.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: gc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
