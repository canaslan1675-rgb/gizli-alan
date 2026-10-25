import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/recycle_bin.dart';
import '../theme.dart';
import '../widgets/quick_lock.dart';

/// Recycle bin (0.6.0 G): restore or delete for good; empty all.
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashEntry>? _entries;
  RecycleBin? _bin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bin == null) {
      final s = GizliAlanApp.of(context).session;
      if (s != null) {
        _bin = RecycleBin(s);
        _reload();
      }
    }
  }

  Future<void> _reload() async {
    final e = await _bin!.entries();
    if (mounted) setState(() => _entries = e);
  }

  IconData _icon(TrashKind k) => switch (k) {
    TrashKind.photo => Icons.photo_outlined,
    TrashKind.file => Icons.insert_drive_file_outlined,
    TrashKind.note => Icons.sticky_note_2_outlined,
  };

  String _kind(L10n t, TrashKind k) => switch (k) {
    TrashKind.photo => t('trashKindPhoto'),
    TrashKind.file => t('trashKindFile'),
    TrashKind.note => t('trashKindNote'),
  };

  Future<bool> _confirm(String body) async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            key: const ValueKey('trash_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: GizliColors.of(ctx).danger,
            ),
            child: Text(t('trashDeleteForever')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final entries = _entries;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(t('trash')),
        actions: [
          if (entries != null && entries.isNotEmpty)
            IconButton(
              key: const ValueKey('trash_empty_all'),
              tooltip: t('trashEmptyAll'),
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                if (!await _confirm(t('trashEmptyConfirm'))) return;
                await _bin!.emptyAll();
                await _reload();
              },
            ),
          const QuickLockButton(),
        ],
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? Center(child: Text(t('trashEmpty')))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    t('trashSub'),
                    style: TextStyle(
                      color: GizliColors.of(context).textSecondary,
                    ),
                  ),
                ),
                for (final e in entries)
                  ListTile(
                    key: ValueKey('trash_${e.id}'),
                    leading: Icon(_icon(e.kind)),
                    title: Text(
                      e.name.isEmpty ? _kind(t, e.kind) : e.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_kind(t, e.kind)} · ${t('trashDaysLeft').replaceAll('{d}', '${e.daysLeft(now)}')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: ValueKey('trash_restore_${e.id}'),
                          tooltip: t('trashRestore'),
                          icon: const Icon(Icons.restore),
                          onPressed: () async {
                            await _bin!.restore(e);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t('trashRestored'))),
                            );
                            await _reload();
                          },
                        ),
                        IconButton(
                          key: ValueKey('trash_purge_${e.id}'),
                          tooltip: t('trashDeleteForever'),
                          icon: const Icon(Icons.delete_forever_outlined),
                          onPressed: () async {
                            if (!await _confirm(t('trashDeleteForever'))) {
                              return;
                            }
                            await _bin!.purge(e);
                            await _reload();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
