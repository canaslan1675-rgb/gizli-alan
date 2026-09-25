import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../app_version.dart';
import '../flavor.dart';
import '../l10n/l10n.dart';
import '../services/browser_logic.dart';
import '../services/privacy_link.dart';
import '../services/pro_entitlement.dart';
import '../services/settings_service.dart';
import '../services/vault_session.dart';
import '../services/vault_space.dart';
import '../theme.dart';
import '../widgets/work_apps_hide_switches.dart';
import 'pro_screen.dart';
import 'set_pin_screen.dart';

/// Vault settings. In the decoy vault only neutral options are shown
/// (language, auto-lock, privacy info) so the real configuration can't be
/// changed from there.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _hasDecoy;
  bool _bioAvailable = false;
  bool _hasHomeBackground = false;
  late final bool _isDecoy;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = GizliAlanApp.of(context);
    _isDecoy = app.session?.isDecoy ?? false;
    _load();
  }

  Future<void> _load() async {
    final app = GizliAlanApp.of(context);
    final hasDecoy = await app.auth.hasDecoyPin();
    final bio = await app.biometrics.isAvailable();
    final bg = await app.session?.homeBackgroundId();
    if (!mounted) return;
    setState(() {
      _hasDecoy = hasDecoy;
      _bioAvailable = bio;
      _hasHomeBackground = bg != null;
    });
  }

  Future<void> _removeHomeBackground() async {
    await GizliAlanApp.of(context).session?.setHomeBackgroundId(null);
    if (mounted) setState(() => _hasHomeBackground = false);
  }

  Future<void> _toggleBiometric(bool v) async {
    final app = GizliAlanApp.of(context);
    final t = L10n.current;
    if (v) {
      final ok = await app.withExternalUi(
        () => app.biometrics.authenticate(t('biometricEnableReason')),
      );
      if (!ok) return;
    }
    await app.settings.setBiometricEnabled(v);
    if (mounted) setState(() {});
  }

  Future<void> _removeDecoy() async {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);
    final ok = await _confirm(t('decoyRemove'), t('decoyRemoveConfirm'));
    if (!ok) return;
    await app.auth.clearDecoyPin();
    await VaultSession.wipeSpace(await app.baseDir(), VaultSpace.decoy);
    await _load();
  }

  Future<void> _resetAll() async {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);
    final ok = await _confirm(t('wipeVault'), t('wipeConfirm'));
    if (!ok) return;
    await app.resetEverything();
  }

  Future<bool> _confirm(String title, String body) async {
    final t = L10n.current;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GizliTheme.danger),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
    return r == true;
  }

  void _privacyInfo() {
    final t = L10n.current;
    final url = PrivacyLink.url;
    final messenger = ScaffoldMessenger.of(context);
    Future<void> copy(String msgKey) async {
      await Clipboard.setData(ClipboardData(text: url!));
      messenger.showSnackBar(SnackBar(content: Text(t(msgKey))));
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('privacyTitle')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('privacyBody')),
              if (url != null) ...[
                const SizedBox(height: 16),
                Text(
                  t('privacyPolicyOnline'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  url,
                  key: const ValueKey('privacy_url'),
                  style: const TextStyle(color: GizliTheme.mint),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (url != null) ...[
            TextButton(
              key: const ValueKey('privacy_copy'),
              onPressed: () => copy('linkCopied'),
              child: Text(t('copyLink')),
            ),
            TextButton(
              key: const ValueKey('privacy_open'),
              onPressed: () async {
                final ok = await PrivacyLink.open(url);
                if (!ok) await copy('noBrowser');
              },
              child: Text(t('openInBrowser')),
            ),
          ],
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('ok'))),
        ],
      ),
    );
  }

  String _timeoutLabel(int s, L10n t) {
    if (s == 0) return t('lockImmediately');
    if (s < 60) return t('lockAfterSec').replaceAll('{n}', '$s');
    return t('lockAfterMin').replaceAll('{n}', '${s ~/ 60}');
  }

  /// "Hide info icon on calculator": Pro-only opt-in (default off).
  /// Pro active → switch. Pro obtainable but inactive → locked with a Pro
  /// badge, tap opens the Pro screen. No Pro in this build (`play`) →
  /// locked, "Pro yakında", not tappable.
  Widget _hideCalcInfoTile() {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final s = app.settings;
    const icon = Icon(Icons.info_outline);
    if (ProEntitlement.isActive(s)) {
      return SwitchListTile(
        key: const ValueKey('settings_hide_calc_info'),
        secondary: icon,
        title: Text(t('hideCalcInfo')),
        subtitle: Text(t('hideCalcInfoHint')),
        value: s.hideCalcInfoIcon,
        onChanged: (v) async {
          await s.setHideCalcInfoIcon(v);
          app.refresh();
          setState(() {});
        },
      );
    }
    final canGetPro = ProEntitlement.available;
    return ListTile(
      key: const ValueKey('settings_hide_calc_info'),
      leading: icon,
      enabled: canGetPro,
      title: Text(t('hideCalcInfo')),
      subtitle: Text(canGetPro ? t('hideCalcInfoLocked') : t('proSoon')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey('settings_hide_calc_info_pro_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: GizliTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GizliTheme.warning.withValues(alpha: 0.6),
              ),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: GizliTheme.warning,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 18),
        ],
      ),
      onTap: canGetPro
          ? () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProScreen()));
              if (mounted) setState(() {});
            }
          : null,
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: GizliTheme.mint,
        fontSize: 12,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final s = app.settings;

    final browser = <Widget>[
      _header(t('browser')),
      ListTile(
        key: const ValueKey('settings_browser_engine'),
        leading: const Icon(Icons.search),
        title: Text(t('browserEngine')),
        subtitle: Text(s.browserSearchEngine.label),
        onTap: () async {
          final picked = await showDialog<SearchEngine>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text(t('browserEngine')),
              children: [
                for (final e in SearchEngine.values)
                  SimpleDialogOption(
                    key: ValueKey('engine_${e.name}'),
                    onPressed: () => Navigator.pop(ctx, e),
                    child: Row(
                      children: [
                        Icon(
                          e == s.browserSearchEngine
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: GizliTheme.mint,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(e.label),
                      ],
                    ),
                  ),
              ],
            ),
          );
          if (picked == null) return;
          await s.setBrowserSearchEngine(picked);
          if (mounted) setState(() {});
        },
      ),
      SwitchListTile(
        key: const ValueKey('settings_browser_wipe'),
        secondary: const Icon(Icons.cleaning_services_outlined),
        title: Text(t('browserWipeOnLock')),
        subtitle: Text(t('browserWipeOnLockHint')),
        value: s.browserWipeOnLock,
        onChanged: (v) async {
          await s.setBrowserWipeOnLock(v);
          if (mounted) setState(() {});
        },
      ),
      ListTile(
        key: const ValueKey('settings_browser_wipe_now'),
        leading: const Icon(Icons.delete_sweep_outlined),
        title: Text(t('browserWipeNow')),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await app.wipeBrowserData();
          messenger.showSnackBar(SnackBar(content: Text(t('browserWiped'))));
        },
      ),
    ];
    final general = <Widget>[
      _header(t('general')),
      ListTile(
        leading: const Icon(Icons.timer_outlined),
        title: Text(t('lockTimeout')),
        subtitle: Text(t('lockTimeoutHint')),
        trailing: DropdownButton<int>(
          value: SettingsService.lockTimeoutChoices.contains(s.lockTimeoutSec)
              ? s.lockTimeoutSec
              : 0,
          underline: const SizedBox(),
          items: SettingsService.lockTimeoutChoices
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(_timeoutLabel(v, t)),
                ),
              )
              .toList(),
          onChanged: (v) async {
            await s.setLockTimeoutSec(v ?? 0);
            setState(() {});
          },
        ),
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(t('language')),
        trailing: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'tr', label: Text('TR')),
            ButtonSegment(value: 'en', label: Text('EN')),
          ],
          selected: {s.language},
          showSelectedIcon: false,
          onSelectionChanged: (v) async {
            await s.setLanguage(v.first);
            app.refresh();
          },
        ),
      ),
      ListTile(
        key: const ValueKey('settings_home_background'),
        leading: const Icon(Icons.image_outlined),
        title: Text(t('homeBackground')),
        subtitle: Text(
          _hasHomeBackground
              ? t('homeBackgroundPhoto')
              : t('homeBackgroundDefault'),
        ),
        trailing: _hasHomeBackground
            ? TextButton(
                key: const ValueKey('settings_home_background_remove'),
                onPressed: _removeHomeBackground,
                child: Text(t('homeBackgroundRemove')),
              )
            : null,
      ),
      ListTile(
        leading: const Icon(Icons.wallpaper_outlined),
        title: Text(t('wallpaper')),
        // First swatch: default picture; the others: plain colour (Düz renk).
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // Bundled default picture (owner-provided).
              GestureDetector(
                key: const ValueKey('settings_wallpaper_image'),
                onTap: () async {
                  await s.setWallpaperImage(true);
                  setState(() {});
                },
                child: Tooltip(
                  message: t('wallpaperDefaultImage'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage(GizliTheme.defaultWallpaperAsset),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: s.wallpaperImage
                            ? GizliTheme.mint
                            : Colors.white24,
                        width: s.wallpaperImage ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(GizliTheme.wallpapers.length, (i) {
                final selected = !s.wallpaperImage && s.wallpaper == i;
                return GestureDetector(
                  key: ValueKey('settings_wallpaper_$i'),
                  onTap: () async {
                    await s.setWallpaper(i);
                    setState(() {});
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: GizliTheme.wallpaper(i),
                      border: Border.all(
                        color: selected ? GizliTheme.mint : Colors.white24,
                        width: selected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      if (Flavor.hasProStub)
        ListTile(
          key: const ValueKey('settings_pro'),
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(t('proTitle')),
          subtitle: Text(t('proSettingsHint')),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProScreen())),
        ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: Text(t('privacyTitle')),
        subtitle: Text(t('dataSafetyShort')),
        onTap: _privacyInfo,
      ),
    ];

    if (_isDecoy) {
      return Scaffold(
        appBar: AppBar(title: Text(t('settings'))),
        body: ListView(children: [...browser, ...general]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        children: [
          _header(t('security')),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(t('changePin')),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SetPinScreen(mode: SetPinMode.change),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(t('biometric')),
            subtitle: Text(
              _bioAvailable ? t('biometricHint') : t('biometricUnavailable'),
            ),
            value: s.biometricEnabled && _bioAvailable,
            onChanged: _bioAvailable ? _toggleBiometric : null,
          ),
          ListTile(
            leading: const Icon(Icons.theater_comedy_outlined),
            title: Text(t('decoyPin')),
            subtitle: Text(
              _hasDecoy == true ? t('decoyPinOn') : t('decoyPinOff'),
            ),
            trailing: _hasDecoy == true
                ? IconButton(
                    tooltip: t('decoyRemove'),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: GizliTheme.danger,
                    ),
                    onPressed: _removeDecoy,
                  )
                : const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SetPinScreen(mode: SetPinMode.decoy),
                ),
              );
              await _load();
            },
          ),
          ListTile(
            leading: const Icon(Icons.screenshot_monitor_outlined),
            title: Text(t('screenSecurity')),
            subtitle: Text(t('screenSecurityHint')),
          ),
          _header(t('entry')),
          SwitchListTile(
            secondary: const Icon(Icons.calculate_outlined),
            title: Text(t('calculatorEntry')),
            subtitle: Text(
              s.calculatorEntryEnabled
                  ? t('calculatorEntryOn')
                  : t('calculatorEntryOff'),
            ),
            value: s.calculatorEntryEnabled,
            onChanged: (v) async {
              await s.setCalculatorEntryEnabled(v);
              app.refresh();
              setState(() {});
            },
          ),
          _hideCalcInfoTile(),
          // Help stays reachable even when the ⓘ button is hidden.
          ListTile(
            key: const ValueKey('settings_calc_help'),
            leading: const Icon(Icons.help_outline),
            title: Text(t('calcHelpTitle')),
            subtitle: Text(t('calcHelpHint')),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(t('calcInfoTitle')),
                content: Text(t('calcInfoBody')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t('ok')),
                  ),
                ],
              ),
            ),
          ),
          if (Flavor.hasSecondPhone) ...[
            _header(t('secondPhone')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WorkAppsHideSwitches(settings: s, keyPrefix: 'settings'),
            ),
          ],
          ...browser,
          ...general,
          _header(t('dangerZone')),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: GizliTheme.danger,
            ),
            title: Text(
              t('wipeVault'),
              style: const TextStyle(color: GizliTheme.danger),
            ),
            subtitle: Text(t('wipeHint')),
            onTap: _resetAll,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'GizliAlan $appVersion · ${Flavor.hasSecondPhone ? 'Full' : 'Play'}',
              key: const ValueKey('settings_version'),
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Attribution for the bundled default wallpaper (xAI terms).
          Center(
            child: Text(
              t('wallpaperAttribution'),
              key: const ValueKey('settings_wallpaper_attribution'),
              style: const TextStyle(
                color: GizliTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
