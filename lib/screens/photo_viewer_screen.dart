import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/vault_storage.dart';
import '../theme.dart';
import '../widgets/vault_actions.dart';

/// Full-screen viewer for decrypted photos (in memory only) with swipe,
/// pinch-zoom, export and delete.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.store,
    required this.items,
    required this.initialIndex,
  });

  final VaultStorage store;
  final List<VaultItem> items;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pc = PageController(
    initialPage: widget.initialIndex,
  );
  late final List<VaultItem> _items = List.of(widget.items);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!await VaultActions.confirmDelete(context)) return;
    final item = _items[_index];
    await widget.store.delete(item);
    await widget.store.events?.add(VaultEventType.itemDeleted, {
      'name': item.name,
    });
    if (!mounted) return;
    setState(() {
      _items.removeAt(_index);
      if (_index >= _items.length) _index = _items.length - 1;
    });
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    if (_items.isEmpty) return const Scaffold();
    final item = _items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: t('export'),
            icon: const Icon(Icons.ios_share),
            onPressed: () => VaultActions.export(context, widget.store, item),
          ),
          IconButton(
            tooltip: t('delete'),
            icon: const Icon(Icons.delete_outline, color: GizliTheme.danger),
            onPressed: _delete,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: _items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) =>
            _Page(store: widget.store, item: _items[i]),
      ),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page({required this.store, required this.item});
  final VaultStorage store;
  final VaultItem item;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  late final Future<Uint8List> _bytes = widget.store.read(widget.item);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Icon(Icons.broken_image_outlined));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image.memory(
              snap.data!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined, size: 48),
            ),
          ),
        );
      },
    );
  }
}
