import 'package:flutter/material.dart';

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
  });

  final SettingsService settings;
  final String keyPrefix;

  @override
  State<WorkAppsHideSwitches> createState() => _WorkAppsHideSwitchesState();
}

class _WorkAppsHideSwitchesState extends State<WorkAppsHideSwitches> {
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final s = widget.settings;
    final hide = s.hideWorkAppsWhenLocked;
    const hint = TextStyle(color: GizliTheme.textSecondary, fontSize: 12);
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
          },
        ),
        if (hide)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Text(t('spHideWhenLockedWhen'), style: hint),
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
