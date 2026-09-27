/// "Hide work profile" guide (full flavor): which system screens to try, in
/// order, so the user can pause / hide the launcher's Work tab themselves.
/// The native side tries each with a guarded startActivity and reports the
/// id of the first one that opened (or `none`).
class WorkSettingsIntent {
  const WorkSettingsIntent(
    this.id, {
    this.action,
    this.package,
    this.component,
  });

  final String id;
  final String? action;

  /// Package to target; `@home` = the current default launcher.
  final String? package;

  /// Explicit `package/class` component.
  final String? component;

  Map<String, String?> toMap() => {
    'id': id,
    'action': action,
    'package': package,
    'component': component,
  };
}

class WorkSettingsIntents {
  WorkSettingsIntents._();

  static const managedProfile = 'android.settings.MANAGED_PROFILE_SETTINGS';
  static const appPreferences = 'android.intent.action.APPLICATION_PREFERENCES';
  static const syncSettings = 'android.settings.SYNC_SETTINGS';
  static const settings = 'android.settings.SETTINGS';
  static const miuiHome = 'com.miui.home';
  static const miuiHomeSettings =
      'com.miui.home/com.miui.home.settings.MiuiHomeSettingsActivity';

  /// Work-profile settings → launcher settings (Xiaomi/POCO/Redmi launcher
  /// first on those phones, then whatever launcher is default) → Accounts /
  /// sync → Settings home.
  static List<WorkSettingsIntent> candidates({required bool xiaomi}) => [
    const WorkSettingsIntent('managed_profile', action: managedProfile),
    if (xiaomi) ...const [
      WorkSettingsIntent('launcher_miui', component: miuiHomeSettings),
      WorkSettingsIntent(
        'launcher_miui_prefs',
        action: appPreferences,
        package: miuiHome,
      ),
    ],
    const WorkSettingsIntent(
      'launcher_default',
      action: appPreferences,
      package: '@home',
    ),
    const WorkSettingsIntent('sync', action: syncSettings),
    const WorkSettingsIntent('settings', action: settings),
  ];
}
