import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../flavor.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'browser_screen.dart';
import 'decoy_calculator_screen.dart';
import 'files_screen.dart';
import 'gallery_screen.dart';
import '../services/pro_billing.dart';
import '../services/pro_entitlement.dart';
import '../services/second_phone_service.dart';
import '../widgets/pro_gate.dart';
import '../widgets/profile_app_tile.dart';
import 'notes_list_screen.dart';
import 'joi_screen.dart';
import 'note_edit_screen.dart';
import 'notifications_screen.dart';
import 'second_phone_screen.dart';
import 'settings_screen.dart';

/// "Virtual phone" home inside the vault: wallpaper, clock and an app-icon
/// grid (Gallery, Notes, Files, Calculator, Second phone, Settings) plus a
/// dock with Lock. Below the built-in icons it lists the apps of the owner's
/// "second phone" (Android work profile) if one was set up, and launches them
/// in that profile. The decoy vault has no second phone.
class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  List<ProfileApp> _profileApps = const [];
  ValueNotifier<int>? _spChanged;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
      _checkReminders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_spChanged == null) {
      _spChanged = GizliAlanApp.of(context).secondPhoneChanged
        ..addListener(_loadProfileApps);
      _loadProfileApps();
      _loadUnread();
      _loadBackground();
      _loadCount();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
    }
  }

  bool _remindersOpen = false;

  /// "Şu tarihte göster" (0.6.2): shows due note reminders, one after the
  /// other, while the vault is unlocked. Only when this home is the current
  /// route (not over another screen). Each shown reminder is cleared.
  Future<void> _checkReminders() async {
    if (_remindersOpen || !mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final repo = GizliAlanApp.of(context).session?.notes;
    if (repo == null) return;
    _remindersOpen = true;
    try {
      final due = await repo.dueReminders();
      for (final n in due) {
        if (!mounted) return;
        await repo.setReminder(n.id, null);
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final t = L10n.of(ctx);
            return AlertDialog(
              key: ValueKey('reminder_dialog_${n.id}'),
              icon: const Icon(Icons.alarm_on),
              title: Text(n.title.isEmpty ? t('untitled') : n.title),
              content: Text(
                n.body.length > 300 ? '${n.body.substring(0, 300)}…' : n.body,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t('remindDismiss')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(t('remindOpenNote')),
                ),
              ],
            );
          },
        );
        if (open == true && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NoteEditScreen(repo: repo, note: n..remindAt = null),
            ),
          );
        }
      }
    } finally {
      _remindersOpen = false;
    }
  }

  int? _stored;
  bool _failedSeen = false;

  /// Neutral text summary of wrong PIN attempts since the last entry (E).
  static String? failedSummary(int n, L10n t) =>
      n <= 0 ? null : t('failedSummary').replaceAll('{n}', '$n');

  Widget _failed(GizliAlanAppState app, L10n t) {
    final text = (_failedSeen || (app.session?.isDecoy ?? true))
        ? null
        : failedSummary(app.failedSinceLastUnlock, t);
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        key: const ValueKey('failed_summary'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _failedSeen = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: GizliTheme.textSecondary,
              shadows: _homeTextShadow,
            ),
          ),
        ),
      ),
    );
  }

  /// Item counter for free users (B): photos + files + notes vs the limit.
  Future<void> _loadCount() async {
    final s = GizliAlanApp.of(context).session;
    if (s == null) return;
    final n = await ItemLimit.storedIn(s);
    if (mounted && n != _stored) setState(() => _stored = n);
  }

  Widget _counter(GizliAlanAppState app, L10n t) {
    final pro = ProEntitlement.isActive(app.settings);
    final n = _stored;
    if (!ProEntitlement.available || n == null) return const SizedBox.shrink();
    final label = ItemLimit.counterLabel(pro: pro, stored: n);
    if (label == null) return const SizedBox.shrink();
    final full = ItemLimit.isFull(pro: pro, stored: n);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        key: const ValueKey('item_counter'),
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (full) {
            await ItemLimit.showLimitReached(context);
          } else {
            await openPro(context);
          }
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            t('itemCounter').replaceAll('{n}', label),
            style: TextStyle(
              fontSize: 12,
              color: full ? GizliTheme.warning : GizliTheme.textSecondary,
              shadows: _homeTextShadow,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadUnread() async {
    final events = GizliAlanApp.of(context).session?.events;
    if (events == null) return;
    final n = await events.unreadCount();
    if (mounted && n != _unread) setState(() => _unread = n);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _spChanged?.removeListener(_loadProfileApps);
    super.dispose();
  }

  Uint8List? _background;

  /// Vault-home background photo chosen in Settings (decrypted in memory).
  Future<void> _loadBackground() async {
    final session = GizliAlanApp.of(context).session;
    final bytes = await session?.homeBackgroundBytes();
    if (mounted) setState(() => _background = bytes);
  }

  Future<void> _loadProfileApps() async {
    final sp = GizliAlanApp.of(context).secondPhoneIfUnlocked;
    if (sp == null) return;
    final st = await sp.status();
    final apps = st.availability == SecondPhoneAvailability.ready
        ? await sp.listApps()
        : const <ProfileApp>[];
    if (mounted) setState(() => _profileApps = apps);
    _loadRecent();
  }

  List<String> _recent = const [];

  Future<void> _loadRecent() async {
    final r = await GizliAlanApp.of(context).session?.recentApps.list();
    if (mounted && r != null) setState(() => _recent = r);
  }

  /// Last opened apps that still exist in the profile, newest first.
  List<ProfileApp> get _recentApps => [
    for (final pkg in _recent)
      ..._profileApps.where((a) => a.packageName == pkg).take(1),
  ];

  Widget _sectionTitle(IconData icon, String text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: GizliTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                color: GizliTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (mounted) setState(() {}); // e.g. wallpaper changed in settings
      _loadProfileApps();
      _loadUnread();
      _loadBackground();
      _loadCount();
      _checkReminders();
    });
  }

  /// Launches a second-phone app in the work profile. The vault then goes to
  /// the background and auto-locks as usual; the app keeps running.
  Future<void> _launchProfileApp(ProfileApp a) async {
    final sp = GizliAlanApp.of(context).secondPhoneIfUnlocked;
    if (sp == null) return;
    // Recorded before launching: the launch may lock the vault (and drop
    // the session key) right away.
    final app = GizliAlanApp.of(context);
    final recent = app.session?.recentApps;
    final before = await recent?.list();
    await recent?.record(a.packageName);
    final r = await sp.launch(a);
    if (r != 'ok' && before != null && app.isUnlocked) {
      // Not opened: undo the record.
      await recent?.restore(before);
    }
    if (mounted) _loadRecent();
    if (r != 'ok' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.current('spFailed').replaceAll('{s}', r))),
      );
    }
  }

  /// Free tier notice on vault entry (and later, until dismissed): the
  /// item limit, the one-time Pro price and what Pro unlocks.
  /// Shown once: on the first vault entry where it applies it is marked as
  /// seen right away, so later entries/launches do not show it again.
  bool? _bannerThisSession;
  bool _showFreeBanner(GizliAlanAppState app) {
    if (_bannerThisSession == null) {
      final show =
          ProEntitlement.available &&
          !ProEntitlement.isActive(app.settings) &&
          !app.settings.freeBannerDismissed;
      _bannerThisSession = show;
      if (show) app.settings.setFreeBannerDismissed(true);
    }
    return _bannerThisSession! && !ProEntitlement.isActive(app.settings);
  }

  Widget _freeBanner(GizliAlanAppState app, L10n t) {
    final price = app.billing?.plan(kPlanLifetime)?.price ?? kProFallbackPrice;
    final body =
        (Flavor.hasSecondPhone ? t('freeBannerBody') : t('freeBannerBodyPlay'))
            .replaceAll('{price}', price);
    return Container(
      key: const ValueKey('free_banner'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GizliTheme.mint.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(
              'freeBannerTitle',
            ).replaceAll('{max}', '${ItemLimit.freeItemLimit}'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: GizliTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: GizliTheme.textSecondary,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const ValueKey('free_banner_dismiss'),
                onPressed: () async {
                  await app.settings.setFreeBannerDismissed(true);
                  if (mounted) setState(() => _bannerThisSession = false);
                },
                child: Text(t('freeBannerDismiss')),
              ),
              FilledButton(
                key: const ValueKey('free_banner_cta'),
                onPressed: () async {
                  await openPro(context);
                  if (mounted) setState(() {});
                },
                child: Text(t('freeBannerCta')),
              ),
            ],
          ),
        ],
      ),
    );
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
        Icons.travel_explore,
        t('browser'),
        const Color(0xFF7CFFB2),
        () => _open(const BrowserScreen()),
      ),
      _AppIcon(
        Icons.calculate_outlined,
        t('decoyTitle'),
        const Color(0xFF9AA8BC),
        () => _open(const DecoyCalculatorScreen()),
      ),
      _AppIcon(
        Icons.notifications_none,
        t('notifications'),
        GizliTheme.warning,
        () => _open(const NotificationsScreen()),
        badge: _unread,
        key: const ValueKey('tile_notifications'),
      ),
      if (Flavor.hasSecondPhone && !(app.session?.isDecoy ?? true))
        _AppIcon(
          Icons.phone_android_outlined,
          t('secondPhone'),
          const Color(0xFF6FD6FF),
          () => _open(const SecondPhoneScreen()),
          key: const ValueKey('tile_second_phone'),
        ),
      _AppIcon(
        Icons.settings_outlined,
        t('settings'),
        GizliTheme.mint,
        () => _open(const SettingsScreen()),
      ),
      _AppIcon(
        Icons.auto_awesome_outlined,
        'Joi',
        const Color(0xFFFF8FD8),
        () => _open(const JoiScreen()),
        key: const ValueKey('tile_joi'),
      ),
    ];

    // The home is always drawn on a dark wallpaper/photo with a scrim, so it
    // keeps the dark palette in every theme mode (v0.5.1 light mode).
    return Theme(
      data: GizliTheme.dark(),
      child: PopScope(
        // The vault route itself never pops: Back on this home locks.
        // Screens pushed on top (gallery, a photo, notes, settings) are
        // separate routes and pop normally. If a back event is ever delivered
        // here while one of those is still current, pop that screen instead
        // of locking the whole vault.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final route = ModalRoute.of(context);
          if (route != null && !route.isCurrent) {
            Navigator.of(context).maybePop();
            return;
          }
          app.lockVaultExplicit();
        },
        child: Scaffold(
          body: Container(
            key: const ValueKey('vault_home_background'),
            decoration: _background != null
                ? BoxDecoration(
                    color: GizliTheme.bg,
                    image: DecorationImage(
                      image: MemoryImage(_background!),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      // Scrim keeps the clock, labels and dock readable.
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(
                          alpha: GizliTheme.homePhotoScrim,
                        ),
                        BlendMode.srcATop,
                      ),
                    ),
                  )
                : app.settings.wallpaperImage
                ? const BoxDecoration(
                    color: GizliTheme.bg,
                    image: DecorationImage(
                      image: AssetImage(GizliTheme.defaultWallpaperAsset),
                      fit: BoxFit.cover,
                      // Low-res owner image: smooth (not pixelated) upscale.
                      filterQuality: FilterQuality.medium,
                    ),
                  )
                : BoxDecoration(
                    gradient: GizliTheme.wallpaper(app.settings.wallpaper),
                  ),
            child: DecoratedBox(
              // Top/bottom scrim for light pictures (clock, dock, signature).
              decoration: _background != null || app.settings.wallpaperImage
                  ? const BoxDecoration(gradient: GizliTheme.homeImageScrim)
                  : const BoxDecoration(),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    // Quick lock (D): double-tap the clock.
                    GestureDetector(
                      key: const ValueKey('clock_quick_lock'),
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: app.lockVaultExplicit,
                      child: Text(
                        DateFormat.Hm(locale).format(_now),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          color: GizliTheme.textPrimary,
                          shadows: _homeTextShadow,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat.MMMMEEEEd(locale).format(_now),
                      style: const TextStyle(
                        fontSize: 16,
                        color: GizliTheme.textSecondary,
                        shadows: _homeTextShadow,
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
                    _counter(app, t),
                    _failed(app, t),
                    const SizedBox(height: 32),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          if (_showFreeBanner(app))
                            SliverToBoxAdapter(child: _freeBanner(app, t)),
                          _grid(
                            apps
                                .map((a) => _AppTile(key: a.key, icon: a))
                                .toList(),
                          ),
                          if (_recentApps.isNotEmpty) ...[
                            _sectionTitle(Icons.history, t('recentApps')),
                            _grid(
                              _recentApps
                                  .map(
                                    (a) => ProfileAppTile(
                                      key: ValueKey('recent_${a.packageName}'),
                                      app: a,
                                      onTap: () => _launchProfileApp(a),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (_profileApps.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.work_outline,
                                      size: 16,
                                      color: GizliTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        t('secondPhoneApps'),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          letterSpacing: 1.1,
                                          color: GizliTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _grid(
                              _profileApps
                                  .map(
                                    (a) => ProfileAppTile(
                                      app: a,
                                      onTap: () => _launchProfileApp(a),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
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
                        // Translucent dark dock (readable on light pictures).
                        color: Colors.black.withValues(alpha: 0.28),
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
                            onTap: app.lockVaultExplicit,
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
        ),
      ),
    );
  }
}

Widget _grid(List<Widget> children) => SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  sliver: SliverGrid.count(
    crossAxisCount: 4,
    mainAxisSpacing: 18,
    crossAxisSpacing: 8,
    childAspectRatio: 0.78,
    children: children,
  ),
);

class _AppIcon {
  const _AppIcon(
    this.icon,
    this.label,
    this.color,
    this.onTap, {
    this.badge = 0,
    this.key,
  });
  final int badge;
  final Key? key;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _AppTile extends StatelessWidget {
  const _AppTile({super.key, required this.icon});
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
              // Dark base keeps tiles readable on light pictures.
              color: Color.alphaBlend(
                icon.color.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.30),
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: icon.color.withValues(alpha: 0.45)),
            ),
            child: Badge(
              isLabelVisible: icon.badge > 0,
              label: Text(icon.badge > 99 ? '99+' : '${icon.badge}'),
              backgroundColor: GizliTheme.danger,
              child: Icon(icon.icon, color: icon.color, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            icon.label,
            // Two lines so "Hesap Makinesi" is not cut to "Hesap Makin…".
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.15,
              color: GizliTheme.textPrimary,
              shadows: _homeTextShadow,
            ),
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

/// Soft shadow for text drawn directly on the home background.
const List<Shadow> _homeTextShadow = [
  Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
];
