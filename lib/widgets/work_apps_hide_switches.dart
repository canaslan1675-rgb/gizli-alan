import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/settings_service.dart';
import '../theme.dart';

/// "Kilitliyken iş uygulamalarını gizle" (default on) + the optional
/// "also try to pause the work profile" switch (issue #30). Shown on the
/// Second phone screen and in Settings (real vault, `full` flavor only).
class WorkAppsHideSwitches extends StatefulWidget {
  const WorkAppsHideSwitches({
    super.key,
    required this.settings,
    this.keyPrefix = 'sp',
    this.openWorkSettings,
  });

  /// Opens the system screen for pausing the Work tab; returns the id of
  /// the screen opened or `none`. Defaults to the app's second phone.
  final Future<String> Function()? openWorkSettings;

  final SettingsService settings;
  final String keyPrefix;

  @override
  State<WorkAppsHideSwitches> createState() => _WorkAppsHideSwitchesState();
}

class _WorkAppsHideSwitchesState extends State<WorkAppsHideSwitches> {
  GizliColors get gc => GizliColors.of(context);

  Future<void> _openSettings() async {
    final open =
        widget.openWorkSettings ??
        () async =>
            await GizliAlanApp.of(
              context,
            ).secondPhoneIfUnlocked?.openWorkSettings() ??
            'none';
    String r;
    try {
      r = await open();
    } catch (_) {
      r = 'none';
    }
    if (r == 'none' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.current('spWorkGuideFailed'))),
      );
    }
  }

  /// Turned on: short guide, then the system screen (#47).
  Future<void> _guide() async {
    final t = L10n.current;
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('work_guide_dialog'),
        title: Text(t('spWorkGuideTitle')),
        content: SingleChildScrollView(child: Text(t('spWorkGuideBody'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(t('spWorkGuideLater')),
          ),
          FilledButton(
            key: const ValueKey('work_guide_open'),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(t('spWorkGuideOpen')),
          ),
        ],
      ),
    );
    if (go == true) await _openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final s = widget.settings;
    final hide = s.hideWorkAppsWhenLocked;
    final hint = TextStyle(color: gc.textSecondary, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: ValueKey('${widget.keyPrefix}_hide_when_locked'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.visibility_off_outlined),
          title: Text(t('spHideWhenLocked')),
          subtitle: Text(t('spHideWhenLockedHint'), style: hint),
          isThreeLine: true,
          value: hide,
          onChanged: (v) async {
            await s.setHideWorkAppsWhenLocked(v);
            if (mounted) setState(() {});
            if (v && mounted) await _guide();
          },
        ),
        if (hide)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Text(t('spHideWhenLockedWhen'), style: hint),
          ),
        if (hide)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: TextButton.icon(
              key: ValueKey('${widget.keyPrefix}_work_settings_again'),
              icon: const Icon(Icons.settings_outlined),
              label: Text(t('spWorkGuideReopen')),
              onPressed: _openSettings,
            ),
          ),
        SwitchListTile(
          key: ValueKey('${widget.keyPrefix}_pause_too'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.pause_circle_outline),
          title: Text(t('spPauseToo')),
          subtitle: Text(t('spPauseTooHint'), style: hint),
          isThreeLine: true,
          value: hide && s.pauseWorkProfileWhenLocked,
          onChanged: hide
              ? (v) async {
                  await s.setPauseWorkProfileWhenLocked(v);
                  if (mounted) setState(() {});
                }
              : null,
        ),
      ],
    );
  }
}
