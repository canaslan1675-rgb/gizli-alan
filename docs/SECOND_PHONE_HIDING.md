# Second phone: hide work apps while locked / Kilitliyken iş uygulamalarını gizle

Issue #30 · `full` flavor only (the `play` flavor has no Second phone, no device-admin or
profile-owner code at all — checked by `test/flavor_sources_test.dart`).

> **TR özet:** İkinci telefondaki (iş profili) uygulamalar kasa kilitliyken telefonun ana
> ekranında, "İş" klasöründe ve uygulama listesinde görünmez. GizliAlan iş profilinin profil
> sahibi olduğu için, profilin **içinden** `DevicePolicyManager.setApplicationHidden(..., true)`
> ile bu uygulamaları gizler; hiçbir şey silinmez, veriler durur. Gerçek PIN / parmak iziyle
> kasa açılınca **yalnızca GizliAlan'ın gizlediği** uygulamalar geri açılır (liste profil
> içinde saklanır). Ayar: İkinci telefon ekranı → "Kilitliyken iş uygulamalarını gizle"
> (varsayılan açık). Gizliyken bu uygulamalar çalışmaz ve **bildirim almaz**.

## What gets hidden / Ne gizlenir

Inside the work profile, every package with a launcher entry (what a launcher shows in its
Work tab / "İş" folder):

- apps installed from the profile's Play Store (e.g. a second WhatsApp/Instagram),
- system apps enabled in the profile (Chrome, Files, Contacts, Camera… whatever the OEM enables),
- the profile's **Play Store** itself (its icon alone would reveal the work profile).

Never hidden (`HidePolicy.NEVER_HIDE` + self, `android/app/src/full/.../secondphone/HidePolicy.kt`):

| Package | Why |
|---|---|
| GizliAlan itself (profile owner) | Must stay to unhide/manage; Android refuses to hide an active admin anyway. Its launcher icon is already disabled inside the profile. |
| `com.google.android.gms`, `com.google.android.gsf` | Google Play services / framework: account sign-in, push, licence checks of every other app. |
| `com.android(.google).packageinstaller`, `com.android(.google).permissioncontroller` | Needed to (re)install apps and manage permissions; Android protects them too. |
| `com.android.managedprovisioning`, `com.android.settings`, `com.android.systemui` | Profile provisioning / system UI. |
| `com.miui.securitycenter`, `com.lbe.security.miui`, `com.miui.home`, `com.mi.android.globallauncher` | Xiaomi/MIUI/HyperOS security, permission and launcher components that some ROMs expose in the profile. |

Hiding Play Store does **not** break restore: unhiding is done by GizliAlan (profile owner) from
its own list and never needs Play Store; the unhide pass always includes Play Store as a safety
net, and "Open Play Store" unhides it first.

## Persisted list / Saklanan liste

The profile-side instance keeps the set of packages **it** hid (SharedPreferences in the work
profile, key `frozen`). Unlock unhides exactly that set (+ Play Store). Apps hidden by anyone else
are not launchable, so they are never recorded and never unhidden by us. An unhide that fails for a
still-installed package stays recorded (status `partial`) and is retried on the next unlock;
uninstalled packages are forgotten. The main-profile side only stores whether the apps are
currently hidden (`second_phone_closed_by`), and a vault reset keeps that marker so the next real
unlock still unhides.

## When / Ne zaman

| Event | Result |
|---|---|
| **Lock** button (or Back on vault home) in the real vault | Hidden immediately. |
| App start while locked (calculator / PIN screen) | Hidden — every time (since #45 also when already hidden, so apps installed since the last lock are caught). |
| GizliAlan returns to the foreground while locked (incl. auto-lock on resume) | Re-swept (at most one attempt per visit, 10 s cooldown — the cross-profile request briefly shows a translucent activity which pauses/resumes us). |
| Background auto-lock (Home button, launching a work app from the vault) | **Not immediately** — Android blocks activity starts from a backgrounded app, and the cross-profile request is an activity. Happens the next time GizliAlan is in the foreground while locked. |
| Real unlock (PIN or biometric) | Unhidden (only what we hid). If the marker was lost but the toggle is on, the profile is asked anyway (it only unhides its own list). |
| Decoy vault | Nothing is hidden or unhidden. |

Toggle off → nothing is hidden any more; apps that are still hidden are unhidden on the next real
unlock.

## Pause work profile (quiet mode) / İş profilini duraklatma

Optional second switch "Also try to pause the work profile" (default off). After hiding, GizliAlan
calls `UserManager.requestQuietModeEnabled(true, profile)`. Android (AOSP
`UserManagerService.ensureCanModifyQuietMode`) only allows this for the **foreground default
launcher** or privileged/system apps, so on almost every phone it returns "not permitted" and only
the hiding applies (toast says so). There is no public DevicePolicyManager API for a profile owner
to pause its own profile. On unlock, a paused profile is unpaused first, GizliAlan waits up to 5 s
for Android to report it running, then unhides.

A paused profile does **not** remove icons: launchers show them greyed out (Pixel "Work apps
paused", MIUI keeps them in the "İş" folder). That is why hiding is the main mechanism. The owner
can still pause manually with the system quick-settings tile "Work apps" / "İş uygulamaları"
where the ROM offers it.

## Limitations / Sınırlamalar

- **No notifications / no background work** for hidden apps (a hidden package is stopped, like
  "not installed" for that user). Messages arrive after unlock (push is delivered when the app is
  back, depending on the app).
- Hiding **stops a running work app** — e.g. returning to GizliAlan's calculator while a work app
  is open closes that app.
- **Gap after background auto-lock:** icons stay visible until GizliAlan is next opened (or Lock is
  pressed). Recommended habit: leave the vault with **Lock**.
- **Launcher shortcuts:** the launcher removes icons of hidden packages (it gets a
  package-removed/unavailable callback). After unhiding, MIUI usually puts the icons back into the
  "İş" folder, but positions/folders the owner arranged by hand may be reset and some launchers
  add them to the end of the home screen. To verify on the owner's Xiaomi (#14, §3.15–3.20).
- **Xiaomi specifics:** MIUI/HyperOS groups work apps into an automatically created "İş"/"Work"
  folder with briefcase badges and has no work tab; when all work apps are hidden the folder
  should disappear or be empty (to verify). MIUI's "Second space" and "Dual apps" are different
  features and not affected. Some HyperOS builds restrict work profiles entirely (existing
  blocked/fallback message).
- If the main app's data is cleared (profile becomes "unlinked"), GizliAlan can no longer sign
  requests to the profile, so hidden apps stay hidden until the work profile is removed in Android
  Settings (Accounts → Work → Remove) — the same recovery as before.
- Verified by unit/widget tests and JVM tests on the agent box; **not yet on a real device**.

## Code

- Kotlin (profile side): `ProfileActionActivity.freeze()/unfreeze()` + `HidePolicy` (JVM tests
  `android/app/src/testFull/.../HidePolicyTest.kt`, run with
  `cd android && ./gradlew :app:testFullDebugUnitTest`).
- Dart: `SecondPhoneService.close/open`, `SettingsService.hideWorkAppsWhenLocked` /
  `pauseWorkProfileWhenLocked`, `GizliAlanAppState.ensureWorkAppsHiddenWhileLocked`,
  `WorkAppsHideSwitches` (Second phone screen + Settings).
- #30 added no permissions (INTERNET arrived later in 0.4.0, only for the in-vault browser), FLAG_SECURE unchanged, nothing is read from other apps.

## v0.4.4 (#45): strictest possible lock — what is and isn't achievable

Owner bug (Xiaomi, v0.4.3): apps installed from Play inside the profile stayed in the Work tab while locked.
Cause: the policy already covered *all* launchable apps, but (1) packages already in our "hidden" record were skipped, so a recorded app that became visible again (Play re-install/update, unhidden elsewhere) was never re-hidden; (2) once "closed", the vault never swept again until the next unlock.

Now, on every lock / every foreground visit while locked / every 15 min inside the profile (JobScheduler, while locked):
- **Hidden:** every package with a launcher entry (incl. Play Store, Files, Chrome, apps installed at any time) + the system file browser DocumentsUI (no launcher entry, but it is what serves the personal side's "Work" tab in the file picker). Never: GizliAlan itself (its launcher entry is disabled in the profile anyway), Play services, installer/permission UIs, Settings/SystemUI, MIUI security/launcher. Unlock unhides exactly the recorded set (+ Play Store safety net). If a hide fails, the app is **suspended** instead (greyed out, not openable) and unsuspended on unlock.
- **Profile policies while locked** (cleared on unlock): no cross-profile copy/paste (`DISALLOW_CROSS_PROFILE_COPY_PASTE`), no sharing into the profile (`DISALLOW_SHARE_INTO_MANAGED_PROFILE`), work caller-ID / contacts search / Bluetooth contact sharing disabled. Profile name is now neutral ("Work" / "İş").
- **Quiet mode (pause profile)** is now the default and always requested — but Android only lets the *default launcher* or system apps pause a profile (`UserManager.requestQuietModeEnabled` → SecurityException for normal apps; there is no profile-owner/DPM equivalent on a personal device). On a normal phone it is refused and hiding is what applies; if the owner ever makes a launcher that allows it, it takes effect automatically.

**Not achievable with public APIs (no root):**
- **Removing the Work tab/folder itself.** Stock Launcher3, MIUI/HyperOS and Pixel launchers show the Work tab whenever a managed profile exists; with every app hidden it is *empty* (Launcher3 shows its "no work apps"/paused card), but the tab stays. Only deleting the profile removes it. A third-party launcher that can hide the Work tab (user-installed) is the only workaround.
- **Immediate hide when auto-locking in the background** (Home button): Android blocks the cross-profile request from a backgrounded app; the profile-side job / next foreground visit catch up (≤15 min, usually at the next GizliAlan open).
- **Instant reaction to an install while locked:** `ACTION_PACKAGE_ADDED` is not delivered to manifest receivers (API 26+) and the profile has no running process; covered by the 15-min job and the foreground sweep. Installing is practically impossible while locked anyway (Play Store is hidden).
- **Blocking the personal side from all work files without quiet mode:** Android's own default cross-profile filters (set by the system, not by us) can't be removed by a profile owner; hiding DocumentsUI in the profile removes the file picker's Work tab target, but full isolation needs quiet mode.
- MIUI/HyperOS launcher sometimes refreshes the Work tab only after it is reopened (icon cache); hidden apps disappear on the next drawer open.
