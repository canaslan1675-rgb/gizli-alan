import '../services/crypto_service.dart';
import '../app_version.dart';
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
import '../services/second_phone_service.dart';
import '../widgets/profile_app_tile.dart';
import 'notes_list_screen.dart';
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
    }
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
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (mounted) setState(() {}); // e.g. wallpaper changed in settings
      _loadProfileApps();
      _loadUnread();
      _loadBackground();
    });
  }

  /// Launches a second-phone app in the work profile. The vault then goes to
  /// the background and auto-locks as usual; the app keeps running.
  Future<void> _launchProfileApp(ProfileApp a) async {
    final sp = GizliAlanApp.of(context).secondPhoneIfUnlocked;
    if (sp == null) return;
    final r = await sp.launch(a);
    if (r != 'ok' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.current('spFailed').replaceAll('{s}', r))),
      );
    }
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
        if (!didPop) app.lockVaultExplicit();
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
                      Colors.black.withValues(alpha: GizliTheme.homePhotoScrim),
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
                  Text(
                    DateFormat.Hm(locale).format(_now),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: GizliTheme.textPrimary,
                      shadows: _homeTextShadow,
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
                  const SizedBox(height: 32),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        _grid(
                          apps
                              .map((a) => _AppTile(key: a.key, icon: a))
                              .toList(),
                        ),
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
                  const _HomeWatermark(),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
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

/// Subtle terminal-style signature above the dock (vault home only, never
/// on the calculator). Every term is taken from the code it describes:
/// version/build from the installed APK ([AppInfo]), flavor from
/// [Flavor.current], cipher and PIN-hash parameters from [CryptoService].
/// Not interactive and excluded from accessibility.
class _HomeWatermark extends StatefulWidget {
  const _HomeWatermark();

  @override
  State<_HomeWatermark> createState() => _HomeWatermarkState();
}

class _HomeWatermarkState extends State<_HomeWatermark> {
  AppInfo _info = AppInfo.fallback;

  @override
  void initState() {
    super.initState();
    AppInfo.load().then((i) {
      if (mounted) setState(() => _info = i);
    });
  }

  static String get cipherLine {
    const bits = CryptoService.keyLength * 8;
    const k = CryptoService.defaultPbkdf2Iterations ~/ 1000;
    return 'AES-$bits-GCM  ·  PIN: PBKDF2-SHA256 ${k}k  ·  FLAG_SECURE';
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['RobotoMono', 'Courier New', 'Courier'],
      fontSize: 9.5,
      height: 1.45,
      letterSpacing: 0.2,
      color: Colors.white.withValues(alpha: 0.42),
      shadows: [
        Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 3),
      ],
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Padding(
          key: const ValueKey('home_watermark'),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: DefaultTextStyle(
            style: style,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GizliAlan Vault  ·  v${_info.version} (build ${_info.build})'
                  '  ·  ${Flavor.current.name}',
                ),
                Text(cipherLine),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '● ',
                        style: TextStyle(
                          color: GizliTheme.mint.withValues(alpha: 0.7),
                        ),
                      ),
                      const TextSpan(text: 'vault: unlocked  ·  © OfferForge'),
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

/// Soft shadow for text drawn directly on the home background.
const List<Shadow> _homeTextShadow = [
  Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
];
