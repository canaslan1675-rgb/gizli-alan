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
| App start while locked (calculator / PIN screen) | Hidden if not already hidden. |
| GizliAlan returns to the foreground while locked (incl. auto-lock on resume) | Hidden if not already hidden (at most one attempt per visit, 10 s cooldown — the cross-profile request briefly shows a translucent activity which pauses/resumes us). |
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
- No new permissions, no INTERNET, FLAG_SECURE unchanged, nothing is read from other apps.
