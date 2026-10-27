import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/backup_actions.dart';
import '../widgets/pin_hint_dialog.dart';
import '../app.dart';
import '../app_version.dart';
import '../flavor.dart';
import '../l10n/l10n.dart';
import '../services/analytics.dart';
import '../services/app_actions.dart';
import '../services/browser_logic.dart';
import '../services/privacy_link.dart';
import '../util/text_case.dart';
import '../services/pro_entitlement.dart';
import '../services/settings_service.dart';
import '../services/vault_session.dart';
import '../services/vault_space.dart';
import '../theme.dart';
import '../widgets/work_apps_hide_switches.dart';
import '../widgets/pro_gate.dart';
import 'help_screen.dart';
import 'trash_screen.dart';
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
    final c = GizliColors.of(context);
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
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
    return r == true;
  }

  void _privacyInfo() {
    final t = L10n.current;
    final c = GizliColors.of(context);
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
                  style: TextStyle(color: c.accent),
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
                final ok = await GizliAlanApp.of(context).withExternalUi(
                  () => PrivacyLink.open(url),
                  untilResume: true,
                );
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

  /// Copies [text] and tells the user why (no app could take the intent).
  Future<void> _copyFallback(String text, String msgKey) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = L10n.current;
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(t(msgKey))));
  }

  /// Share app: edit a neutral intro, then share intro + Play link only.
  Future<void> _shareApp() async {
    final t = L10n.current;
    final c = GizliColors.of(context);
    final controller = TextEditingController(text: t('shareAppText'));
    final intro = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('share_intro_dialog'),
        title: Text(t('shareIntroTitle')),
        content: TextField(
          key: const ValueKey('share_intro_field'),
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: t('shareAppText'),
            helperText: t('shareIntroHint'),
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          TextButton(
            key: const ValueKey('share_intro_confirm'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: c.accent),
            child: Text(t('shareApp')),
          ),
        ],
      ),
    );
    // Drop after the route finishes unmounting the TextField.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (intro == null || !mounted) return;
    final line = intro.isEmpty ? t('shareAppText') : intro;
    final text = AppActions.shareText(line);
    final app = GizliAlanApp.of(context);
    if (await app.withExternalUi(
      () => AppActions.share(text, title: t('shareApp')),
      untilResume: true,
    )) {
      return;
    }
    await _copyFallback(AppActions.storeUrl, 'shareAppFailed');
  }

  Future<void> _rateApp() async {
    final app = GizliAlanApp.of(context);
    if (await app.withExternalUi(
      () => AppActions.openStore(),
      untilResume: true,
    )) {
      return;
    }
    await _copyFallback(AppActions.storeUrl, 'rateAppFailed');
  }

  /// Feedback: pick Bug / Suggestion / Other, optional body draft, then mailto.
  /// Category goes in the subject only. Body is user-typed; never auto-fill
  /// device IDs, logs or vault data.
  Future<void> _sendFeedback() async {
    final t = L10n.current;
    final c = GizliColors.of(context);
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          key: const ValueKey('feedback_category_sheet'),
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t('feedbackCategoryTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            for (final (key, labelKey) in const [
              ('bug', 'feedbackCatBug'),
              ('suggestion', 'feedbackCatSuggestion'),
              ('other', 'feedbackCatOther'),
            ])
              ListTile(
                key: ValueKey('feedback_cat_$key'),
                leading: Icon(
                  key == 'bug'
                      ? Icons.bug_report_outlined
                      : key == 'suggestion'
                      ? Icons.lightbulb_outline
                      : Icons.chat_bubble_outline,
                  color: c.accent,
                ),
                title: Text(t(labelKey)),
                onTap: () => Navigator.pop(ctx, t(labelKey)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;

    final whatCtrl = TextEditingController();
    final expectCtrl = TextEditingController();
    final draft = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('feedback_body_dialog'),
        title: Text(t('feedbackBodyTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('feedback_body_what'),
                controller: whatCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: t('feedbackBodyWhat'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('feedback_body_expected'),
                controller: expectCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: t('feedbackBodyExpected'),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          TextButton(
            key: const ValueKey('feedback_body_skip'),
            onPressed: () => Navigator.pop(ctx, ('', '')),
            child: Text(t('feedbackBodySkip')),
          ),
          TextButton(
            key: const ValueKey('feedback_body_send'),
            onPressed: () => Navigator.pop(ctx, (
              whatCtrl.text.trim(),
              expectCtrl.text.trim(),
            )),
            style: TextButton.styleFrom(foregroundColor: c.accent),
            child: Text(t('feedback')),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      whatCtrl.dispose();
      expectCtrl.dispose();
    });
    if (draft == null || !mounted) return;

    final info = await AppInfo.load();
    final subject = AppActions.feedbackSubject(
      t('feedbackSubject'),
      info.version,
      info.build,
      category: category,
    );
    final parts = <String>[];
    if (draft.$1.isNotEmpty) {
      parts.add('${t('feedbackBodyWhat')}:\n${draft.$1}');
    }
    if (draft.$2.isNotEmpty) {
      parts.add('${t('feedbackBodyExpected')}:\n${draft.$2}');
    }
    final body = parts.isEmpty ? null : parts.join('\n\n');
    if (!mounted) return;
    final app = GizliAlanApp.of(context);
    if (await app.withExternalUi(
      () => AppActions.sendFeedback(subject, body: body),
      untilResume: true,
    )) {
      return;
    }
    if (!mounted) return;
    await _copyFallback(AppActions.feedbackEmail, 'feedbackFailed');
  }

  String _timeoutLabel(int s, L10n t) {
    if (s <= 0) return t('lockImmediately');
    if (s <= 30) return t('lockAfter30');
    return t('lockAfter60');
  }

  /// "Hide info icon on calculator": Pro-only opt-in (default off).
  /// Pro active → switch. Pro obtainable but inactive → locked with a Pro
  /// badge, tap opens the Pro screen. No Pro in this build (`play`) →
  /// locked, "Pro yakında", not tappable.
  Widget _hideCalcInfoTile() {
    final t = L10n.of(context);
    final app = GizliAlanApp.of(context);
    final s = app.settings;
    final c = GizliColors.of(context);
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
    if (!canGetPro) return const SizedBox.shrink();
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
              color: c.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.warning.withValues(alpha: 0.6)),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.warning,
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
              ).push(MaterialPageRoute(builder: (_) => proScreen()));
              if (mounted) setState(() {});
            }
          : null,
    );
  }

  /// "Delete original after import" (#37): free in every flavor, opt-in.
  Widget _deleteOriginalTile() {
    final t = L10n.of(context);
    final s = GizliAlanApp.of(context).settings;
    return SwitchListTile(
      key: const ValueKey('settings_delete_original'),
      secondary: const Icon(Icons.auto_delete_outlined),
      title: Text(t('deleteOriginal')),
      subtitle: Text(t('deleteOriginalHint')),
      value: ProEntitlement.deleteOriginalAfterImport(s),
      onChanged: (v) async {
        await s.setDeleteOriginalAfterImport(v);
        await s.setDeleteOriginalAsked();
        if (mounted) setState(() {});
      },
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(
      upperFor(text, L10n.lang),
      style: TextStyle(
        color: GizliColors.of(context).accent,
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
    final c = GizliColors.of(context);

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
                          color: c.accent,
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
        key: const ValueKey('settings_lock_timeout'),
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
      SwitchListTile(
        key: const ValueKey('settings_resume'),
        secondary: const Icon(Icons.restore_page_outlined),
        title: Text(t('resumeTitle')),
        subtitle: Text(t('resumeHint')),
        value: s.resumeWhereLeft,
        onChanged: (v) async {
          if (v) {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                key: const ValueKey('resume_warning'),
                title: Text(t('resumeWarnTitle')),
                content: Text(t('resumeWarnBody')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(t('cancel')),
                  ),
                  FilledButton(
                    key: const ValueKey('resume_warning_ok'),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(t('resumeWarnOk')),
                  ),
                ],
              ),
            );
            if (ok != true) return;
          }
          await s.setResumeWhereLeft(v);
          setState(() {});
        },
      ),
      if (s.resumeWhereLeft)
        ListTile(
          key: const ValueKey('settings_resume_max'),
          leading: const SizedBox(width: 24),
          title: Text(t('resumeMax')),
          trailing: DropdownButton<int>(
            value: s.resumeMaxMin,
            underline: const SizedBox(),
            items: SettingsService.resumeMaxChoices
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(t('resumeMinutes').replaceAll('{n}', '$v')),
                  ),
                )
                .toList(),
            onChanged: (v) async {
              await s.setResumeMaxMin(v ?? 5);
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
            ButtonSegment(value: 'ru', label: Text('RU')),
          ],
          selected: {s.language},
          showSelectedIcon: false,
          onSelectionChanged: (v) async {
            await s.setLanguage(v.first);
            app.refresh();
          },
        ),
      ),
      SwitchListTile(
        key: const ValueKey('settings_analytics'),
        secondary: const Icon(Icons.insights_outlined),
        title: Text(t('analyticsToggle')),
        subtitle: Text(t('analyticsToggleHint')),
        value: s.analyticsEnabled,
        onChanged: (v) async {
          await s.setAnalyticsEnabled(v);
          await Analytics.setEnabled(v);
          setState(() {});
        },
      ),
      Padding(
        key: const ValueKey('settings_analytics_notice'),
        padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
        child: Text(
          t('analyticsPrivacyNotice'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      SwitchListTile(
        key: const ValueKey('settings_joi_speak'),
        secondary: const Icon(Icons.record_voice_over_outlined),
        title: Text(t('joiSpeakSetting')),
        subtitle: Text(t('joiSpeakSettingHint')),
        value: s.joiSpeak,
        onChanged: (v) async {
          await s.setJoiSpeak(v);
          setState(() {});
        },
      ),
      SwitchListTile(
        key: const ValueKey('settings_joi_online'),
        secondary: const Icon(Icons.cloud_outlined),
        title: Text(t('joiOnlineToggle')),
        subtitle: Text(t('joiOnlineToggleHint')),
        value: s.joiOnlineConsent,
        onChanged: (v) async {
          await s.setJoiOnlineConsent(v);
          setState(() {});
        },
      ),
      ListTile(
        key: const ValueKey('settings_theme'),
        leading: const Icon(Icons.brightness_6_outlined),
        title: Text(t('appearance')),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(
                  t('themeSystem'),
                  key: const ValueKey('theme_system'),
                ),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(
                  t('themeLight'),
                  key: const ValueKey('theme_light'),
                ),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t('themeDark'), key: const ValueKey('theme_dark')),
              ),
            ],
            selected: {s.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (v) async {
              await s.setThemeMode(v.first);
              app.refresh();
            },
          ),
        ),
      ),
      ListTile(
        key: const ValueKey('settings_accent'),
        leading: const Icon(Icons.palette_outlined),
        title: Text(t('accentColor')),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final p in AccentPreset.values)
                _AccentSwatch(
                  key: ValueKey('accent_${p.name}'),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? p.darkAccent
                      : p.lightAccent,
                  label: t('accent_${p.name}'),
                  selected: s.accent == p,
                  onTap: () async {
                    await s.setAccent(p);
                    app.refresh();
                  },
                ),
            ],
          ),
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
                        color: s.wallpaperImage ? c.accent : c.swatchBorder,
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
                        color: selected ? c.accent : c.swatchBorder,
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
      if (ProEntitlement.available)
        ListTile(
          key: const ValueKey('settings_pro'),
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(t('proTitle')),
          subtitle: Text(
            t(Flavor.hasProStub ? 'proSettingsHintStub' : 'proSettingsHint'),
          ),
          onTap: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => proScreen()));
            if (mounted) setState(() {});
          },
        ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: Text(t('privacyTitle')),
        subtitle: Text(t('dataSafetyShort')),
        onTap: _privacyInfo,
      ),
      ListTile(
        key: const ValueKey('settings_support'),
        leading: const Icon(Icons.support_agent_outlined),
        title: Text(t('supportEmail')),
        subtitle: const Text(PrivacyLink.supportEmail),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          if (await GizliAlanApp.of(
            context,
          ).withExternalUi(PrivacyLink.openMail, untilResume: true)) {
            return;
          }
          await Clipboard.setData(
            const ClipboardData(text: PrivacyLink.supportEmail),
          );
          messenger.showSnackBar(SnackBar(content: Text(t('emailCopied'))));
        },
        trailing: IconButton(
          key: const ValueKey('settings_support_copy'),
          tooltip: t('copyEmail'),
          icon: const Icon(Icons.copy_outlined),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(
              const ClipboardData(text: PrivacyLink.supportEmail),
            );
            messenger.showSnackBar(SnackBar(content: Text(t('emailCopied'))));
          },
        ),
      ),
    ];
    // Help & feedback (v0.5.1). Neutral, so also shown in the decoy vault.
    final about = <Widget>[
      _header(t('helpFeedback')),
      ListTile(
        key: const ValueKey('settings_help'),
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(t('helpTitle')),
        subtitle: Text(t('helpHint')),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
      ),
      ListTile(
        key: const ValueKey('settings_share'),
        leading: const Icon(Icons.share_outlined),
        title: Text(t('shareApp')),
        subtitle: Text(t('shareAppHint')),
        onTap: _shareApp,
      ),
      ListTile(
        key: const ValueKey('settings_rate'),
        leading: const Icon(Icons.star_outline),
        title: Text(t('rateApp')),
        subtitle: Text(t('rateAppHint')),
        onTap: _rateApp,
      ),
      ListTile(
        key: const ValueKey('settings_feedback'),
        leading: const Icon(Icons.feedback_outlined),
        title: Text(t('feedback')),
        subtitle: Text(t('feedbackHint')),
        onTap: _sendFeedback,
      ),
    ];

    if (_isDecoy) {
      return Scaffold(
        appBar: AppBar(title: Text(t('settings'))),
        body: ListView(children: [...browser, ...general, ...about]),
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
          if (!(GizliAlanApp.of(context).session?.isDecoy ?? true))
            ListTile(
              key: const ValueKey('settings_pin_hint'),
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(t('pinHint')),
              subtitle: Text(t('pinHintSub')),
              onTap: () => editPinHint(context),
            ),
          ListTile(
            key: const ValueKey('settings_backup_create'),
            leading: const Icon(Icons.backup_outlined),
            title: Text(t('backupCreate')),
            subtitle: Text(t('backupCreateSub')),
            trailing: ProEntitlement.isActive(GizliAlanApp.of(context).settings)
                ? null
                : const Icon(Icons.workspace_premium_outlined),
            onTap: () => BackupActions.create(context),
          ),
          ListTile(
            key: const ValueKey('settings_backup_restore'),
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(t('backupRestore')),
            subtitle: Text(t('backupRestoreSub')),
            onTap: () => BackupActions.restore(context),
          ),
          ListTile(
            key: const ValueKey('settings_trash'),
            leading: const Icon(Icons.delete_outline),
            title: Text(t('trash')),
            subtitle: Text(t('trashSub')),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TrashScreen())),
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
                    icon: Icon(Icons.delete_outline, color: c.danger),
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
          _deleteOriginalTile(),
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
          ...about,
          _header(t('dangerZone')),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: c.danger),
            title: Text(t('wipeVault'), style: TextStyle(color: c.danger)),
            subtitle: Text(t('wipeHint')),
            onTap: _resetAll,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'GizliAlan $appVersion · ${Flavor.hasSecondPhone ? 'Full' : 'Play'}',
              key: const ValueKey('settings_version'),
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Round accent-colour choice in Settings → Appearance (v0.5.2).
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gc = GizliColors.of(context);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? gc.textPrimary : gc.swatchBorder,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check, size: 20, color: gc.onAccent)
                : null,
          ),
        ),
      ),
    );
  }
}
