import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/vault_events.dart';
import '../theme.dart';

/// Vault-only notification list: the app's own events for the open space
/// (imports, exports, deletions, second-phone changes, failed unlocks).
/// Visible only inside the unlocked vault; GizliAlan posts no system
/// notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Captured once (the session may close while this route animates away).
  VaultEventLog? _logRef;
  VaultEventLog get _log => _logRef!;
  late Future<List<VaultEvent>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logRef == null) {
      _logRef = GizliAlanApp.of(context).session!.events;
      _future = _log.list();
    }
  }

  void _reload() => setState(() => _future = _log.list());

  Future<void> _markAllRead() async {
    await _log.markAllRead();
    if (mounted) _reload();
  }

  Future<void> _clearAll() async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('notifClearAll')),
        content: Text(t('notifClearConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            key: const ValueKey('notif_clear_ok'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GizliTheme.danger),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _log.clear();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final fmt = DateFormat.yMMMd(L10n.lang).add_Hm();
    return Scaffold(
      appBar: AppBar(
        title: Text(t('notifications')),
        actions: [
          IconButton(
            key: const ValueKey('notif_mark_read'),
            tooltip: t('notifMarkAllRead'),
            icon: const Icon(Icons.done_all),
            onPressed: _markAllRead,
          ),
          IconButton(
            key: const ValueKey('notif_clear'),
            tooltip: t('notifClearAll'),
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: FutureBuilder<List<VaultEvent>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data!;
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t('notifEmpty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GizliTheme.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: events.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == events.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t('notifFooter'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: GizliTheme.textSecondary,
                    ),
                  ),
                );
              }
              final e = events[i];
              final (icon, color) = eventIcon(e.type);
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(
                  eventMessage(t, e),
                  style: TextStyle(
                    fontWeight: e.read ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                subtitle: Text(fmt.format(e.at)),
                trailing: e.read
                    ? null
                    : const Icon(
                        Icons.circle,
                        size: 10,
                        color: GizliTheme.mint,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Localized one-line message for [e].
String eventMessage(L10n t, VaultEvent e) {
  String fill(String key) {
    var s = t(key);
    e.params.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  return switch (e.type) {
    VaultEventType.galleryImported => fill('evGalleryImported'),
    VaultEventType.filesImported => fill('evFilesImported'),
    VaultEventType.itemExported => fill('evItemExported'),
    VaultEventType.itemDeleted => fill('evItemDeleted'),
    VaultEventType.failedUnlocks => fill('evFailedUnlocks'),
    VaultEventType.secondPhoneCreated => fill('evSecondPhoneCreated'),
    VaultEventType.secondPhoneAppAdded => fill('evSecondPhoneAppAdded'),
    VaultEventType.secondPhoneRemoved => fill('evSecondPhoneRemoved'),
  };
}

(IconData, Color) eventIcon(VaultEventType type) => switch (type) {
  VaultEventType.galleryImported => (
    Icons.photo_library_outlined,
    const Color(0xFF7CB8FF),
  ),
  VaultEventType.filesImported => (
    Icons.folder_outlined,
    const Color(0xFFB79CFF),
  ),
  VaultEventType.itemExported => (Icons.ios_share, GizliTheme.mint),
  VaultEventType.itemDeleted => (Icons.delete_outline, GizliTheme.danger),
  VaultEventType.failedUnlocks => (Icons.warning_amber, GizliTheme.warning),
  VaultEventType.secondPhoneCreated ||
  VaultEventType.secondPhoneAppAdded ||
  VaultEventType.secondPhoneRemoved => (
    Icons.phone_android_outlined,
    const Color(0xFF6FD6FF),
  ),
};
