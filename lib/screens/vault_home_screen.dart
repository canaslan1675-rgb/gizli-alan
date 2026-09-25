import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'files_screen.dart';
import 'notes_list_screen.dart';
import 'settings_screen.dart';

/// Vault hub after PIN unlock.
/// Leave Vault clears nav stack to decoy/root (Play-honest dual entry).
class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) app.leaveVaultToDecoy();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('vaultHome')),
          leading: IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: t('leaveVault'),
            onPressed: app.leaveVaultToDecoy,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              t('appNameVault'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GizliTheme.mint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('privacyNote'),
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _tile(
              context,
              icon: Icons.notes_outlined,
              title: t('notes'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotesListScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.folder_outlined,
              title: t('files'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FilesScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.settings_outlined,
              title: t('settings'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: app.leaveVaultToDecoy,
              icon: const Icon(Icons.logout),
              label: Text(t('leaveVault')),
              style: OutlinedButton.styleFrom(
                foregroundColor: GizliTheme.mint,
                side: const BorderSide(color: GizliTheme.mint),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: GizliTheme.mint),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
