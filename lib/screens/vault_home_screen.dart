import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'decoy_calculator_screen.dart';
import 'files_screen.dart';
import 'gallery_screen.dart';
import 'notes_list_screen.dart';
import 'settings_screen.dart';

/// "Virtual phone" home inside the vault: wallpaper, clock and an app-icon
/// grid (Gallery, Notes, Files, Calculator, Settings) plus a dock with Lock.
/// The decoy vault looks identical but is empty.
class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (mounted) setState(() {}); // e.g. wallpaper changed in settings
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final locale = L10n.lang == 'en' ? 'en' : 'tr';

    final apps = <_AppIcon>[
      _AppIcon(
        Icons.photo_library_outlined,
        t('gallery'),
        const Color(0xFF7CB8FF),
        () => _open(const GalleryScreen()),
      ),
      _AppIcon(
        Icons.sticky_note_2_outlined,
        t('notes'),
        const Color(0xFFFFC857),
        () => _open(const NotesListScreen()),
      ),
      _AppIcon(
        Icons.folder_outlined,
        t('files'),
        const Color(0xFFB79CFF),
        () => _open(const FilesScreen()),
      ),
      _AppIcon(
        Icons.calculate_outlined,
        t('decoyTitle'),
        const Color(0xFF9AA8BC),
        () => _open(const DecoyCalculatorScreen()),
      ),
      _AppIcon(
        Icons.settings_outlined,
        t('settings'),
        GizliTheme.mint,
        () => _open(const SettingsScreen()),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) app.lockVault();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: GizliTheme.wallpaper(app.settings.wallpaper),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),
                Text(
                  DateFormat.Hm(locale).format(_now),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    color: GizliTheme.textPrimary,
                  ),
                ),
                Text(
                  DateFormat.MMMMEEEEd(locale).format(_now),
                  style: const TextStyle(
                    fontSize: 16,
                    color: GizliTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('appNameVault'),
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: GizliTheme.mint.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                    children: apps.map((a) => _AppTile(icon: a)).toList(),
                  ),
                ),
                // Dock
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _DockButton(
                        icon: Icons.photo_library_outlined,
                        tooltip: t('gallery'),
                        onTap: () => _open(const GalleryScreen()),
                      ),
                      _DockButton(
                        icon: Icons.sticky_note_2_outlined,
                        tooltip: t('notes'),
                        onTap: () => _open(const NotesListScreen()),
                      ),
                      _DockButton(
                        key: const ValueKey('lock_button'),
                        icon: Icons.lock_outline,
                        tooltip: t('lock'),
                        onTap: app.lockVault,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon {
  const _AppIcon(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.icon});
  final _AppIcon icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: icon.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: icon.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: icon.color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon.icon, color: icon.color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            icon.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: GizliTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 28,
      style: IconButton.styleFrom(
        backgroundColor: highlight
            ? GizliTheme.mint.withValues(alpha: 0.2)
            : Colors.transparent,
      ),
      icon: Icon(icon, color: highlight ? GizliTheme.mint : null),
    );
  }
}
