import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/second_phone_service.dart';
import '../services/settings_service.dart';
import '../services/vault_session.dart';
import '../services/vault_space.dart';
import '../theme.dart';
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
    if (!mounted) return;
    setState(() {
      _hasDecoy = hasDecoy;
      _bioAvailable = bio;
    });
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('privacyTitle')),
        content: SingleChildScrollView(child: Text(t('privacyBody'))),
        actions: [
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
        leading: const Icon(Icons.wallpaper_outlined),
        title: Text(t('wallpaper')),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 10,
            children: List.generate(GizliTheme.wallpapers.length, (i) {
              final selected = s.wallpaper == i;
              return GestureDetector(
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
          ),
        ),
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
        body: ListView(children: general),
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
          _header(t('secondPhone')),
          ListTile(
            leading: const Icon(Icons.phone_android_outlined),
            title: Text(t('spCloseMode')),
            subtitle: Text(
              s.secondPhoneCloseMode == SecondPhoneCloseMode.quiet
                  ? '${t('spCloseModeHint')}\n${t('spQuietNote')}'
                  : t('spCloseModeHint'),
            ),
            isThreeLine: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<SecondPhoneCloseMode>(
              key: const ValueKey('sp_close_mode'),
              segments: [
                ButtonSegment(
                  value: SecondPhoneCloseMode.off,
                  label: Text(t('spModeOff')),
                ),
                ButtonSegment(
                  value: SecondPhoneCloseMode.freeze,
                  label: Text(t('spModeFreeze')),
                ),
                ButtonSegment(
                  value: SecondPhoneCloseMode.quiet,
                  label: Text(t('spModeQuiet')),
                ),
              ],
              selected: {s.secondPhoneCloseMode},
              showSelectedIcon: false,
              onSelectionChanged: (v) async {
                await s.setSecondPhoneCloseMode(v.first);
                setState(() {});
              },
            ),
          ),
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
          const Center(
            child: Text(
              'GizliAlan 0.2.0',
              style: TextStyle(color: GizliTheme.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
