# Reviewer notes — Play Console → App content → App access

> **TR özet.** Uygulamada hesap yok, ama kasa kullanıcının ilk açılışta belirlediği PIN'in arkasında ve giriş (PIN + "=") ilk bakışta belli değil. Bu yüzden App access'te
> **"Tüm veya bazı işlevler kısıtlı"** seçilip aşağıdaki talimat verilmeli (en dürüst ve en güvenli yol: inceleyici kasayı bulamazsa "gizli işlev" ya da "bozuk işlev" sanabilir).
> `<DEMO_PIN>` yer tutucusunu **sahibi** belirler (4–8 hane, örn. kolay ama gerçek PIN'inle aynı olmayan bir sayı); PIN inceleyicinin kendi cihazında ilk kurulumda oluşturulur, sunucu yok.
> Kısa sürüm (≤ 500 karakter, Console alanı için) + uzun sürüm (özellik açıklamaları) + `full` için iş profili açıklaması + isteğe bağlı demo video bağlantısı.

Replace `<DEMO_PIN>` (e.g. a 4–6 digit number chosen by the owner, **not** the owner's personal PIN) and
`<DEMO_VIDEO_URL>` (optional unlisted YouTube link, see `DECLARATIONS.md` §3) before pasting.

Console form: **"All or some functionality in my app is restricted"** → *Add instructions*:
- Name: `Vault (PIN set on first launch)`
- Username: `(none – no account)`
- Password: `<DEMO_PIN>` (to be created by the reviewer during onboarding)
- "Any other instructions": the short version below.

> **[UNCERTAIN]** The "Any other instructions" field has historically had a ~500-character limit. The
> short version fits; paste the long version only if the field allows it, or host it next to the privacy policy
> and link it.

## 1. Short version (≤ 500 characters)

```
No account. First launch: tick "own device", keep "Open as calculator" on, set PIN <DEMO_PIN>. The app then opens as a real working calculator (launcher label "Calculator"). Type <DEMO_PIN> and press "=" to open the vault. The ⓘ button explains this. Long-press "=" = biometrics (enable in vault Settings). Turn the calculator entry off in Settings > Entry. No server, no analytics, same behaviour for everyone; INTERNET is used only by the in-vault browser (vault home → Tarayıcı/Browser) for pages the user opens.
```

## 2. Long version (feature by feature)

```
GizliAlan is an on-device personal vault. There is no account and no server; the app contacts no developer server, so there is no remote configuration and no reviewer-specific behaviour. The INTERNET permission exists only for the in-vault private browser (Android System WebView), which loads only pages the user opens; cookies/cache are wiped when the vault locks (setting "Kilitlenince temizle", on by default). Downloads are disabled. Everything described here is in the build you received.

OPEN THE VAULT
1. First launch – onboarding:
   Step 1: what the app is + "This is my own device" checkbox.
   Step 2: "Calculator entry" disclosure: the app opens as a working calculator; PIN then "=" opens the vault; the launcher shows "Calculator"/"Hesap Makinesi" with a calculator icon and that icon is GizliAlan. Toggle "Open as calculator" (on by default).
   Step 3: set PIN <DEMO_PIN> (4-8 digits) and confirm. Note: no PIN recovery by design.
2. The app now shows a real calculator (try 12×3=). Type <DEMO_PIN> then "=" -> the vault home opens.
3. The ⓘ button on the calculator explains the vault entry at any time.
4. Vault -> Settings -> Entry: turn the calculator entry off -> the app opens directly at a PIN screen.

FEATURES INSIDE THE VAULT
- Gallery: "+" opens the Android system photo picker (no storage permission). Items are encrypted (AES-256-GCM) into app-private storage; view, export (system "save as"), delete.
- Files: same, via the system file picker.
- Notes: create/edit/delete/search encrypted notes.
- Notifications tile: the app's own events only (imports, exports, deletions, wrong PIN attempts). The app posts no system notifications and reads no other app's notifications.
- Settings: change PIN, biometric unlock (Android BiometricPrompt; then long-press "=" on the calculator), auto-lock delay, decoy PIN, wallpaper, language, "Reset everything", privacy & permissions text.
- Decoy PIN (optional): Settings -> Decoy PIN. It opens a separate vault that starts empty. Biometrics always open the real vault.
- Auto-lock when the app goes to background. FLAG_SECURE blocks screenshots/recents previews (pre-launch report screenshots will appear black – intended).

WHAT THE APP DOES NOT DO
No Accessibility service, no device admin, no SMS/call log/contacts/location/camera/microphone access, no monitoring of other apps or people, no data collection, no ads, no analytics. Permissions: USE_BIOMETRIC (optional) and INTERNET, used only by the in-vault browser for pages the user opens (no analytics, no ads, no developer server).

Demo video (optional): <DEMO_VIDEO_URL>
```

## 3. `full` flavor only — work profile explanation (append to §2)

```
SECOND PHONE (optional, Android managed work profile)
Purpose: lets the phone's owner keep a separate set of apps and accounts (e.g. a second Google account) apart from the main profile, like Shelter/Island. Requires a device that supports work profiles (Pixel / Android emulator with Google Play works).
1. Unlock the vault (real PIN, not decoy) -> tile "Second phone" -> "Set up second phone". GizliAlan explains what will happen, then starts Android's own ACTION_PROVISION_MANAGED_PROFILE flow; Android shows its own consent and notices.
2. GizliAlan becomes profile owner of THAT work profile only. Its DeviceAdminReceiver declares no policies (<uses-policies/> empty). It is never device owner. If a user activates it as a device admin of the main profile, it immediately deactivates itself.
3. What it does with the role, all on explicit user action: open the profile's Play Store (add a second account), make an app from the main profile available in the profile, list and launch the profile's apps from the vault home grid, hide/unhide profile apps when the vault locks/unlocks (Settings -> "Second phone on lock"), remove the profile.
4. It does not read data, messages, notifications or usage of apps inside the profile, requests no extra permissions (no REQUEST_INSTALL_PACKAGES, no QUERY_ALL_PACKAGES – a MAIN/LAUNCHER <queries> intent is used for the app grid), and uploads nothing.
5. Remove: vault -> Second phone -> "Remove second phone", or Android Settings -> Accounts -> Work profile -> Remove. Uninstalling the main app does not leave hidden admin rights on the main profile.
The decoy vault has no Second phone tile and cannot reveal the profile.
```

## 4. Where the disclosure is (for reviewer questions)

| Place | Content |
|---|---|
| Store listing, 2nd paragraph | "CALCULATOR ENTRY – DISCLOSED" |
| Screenshot 1 | calculator with the ⓘ dialog open |
| Screenshot 2 | onboarding step 2 (entry disclosure + toggle) |
| Onboarding step 2 | `entryTitle` / `entryBody` / `entryDisclosure` strings |
| Calculator ⓘ | `calcInfoBody` |
| Settings → Privacy & permissions | full privacy summary + (after #12) policy URL |
| Privacy policy (hosted `PRIVACY.md`) | "Calculator entry and decoy PIN (disclosed features)" section |

## 5. Tester guide (closed test) — reuse

Send testers §1 plus: "Please use the app at least a few times a week for 14 days: add a few non-sensitive
test photos, a note, lock/unlock, try the calculator. Report anything confusing via Play's private feedback or
<SUPPORT_EMAIL>. Don't store real sensitive content during the test (no PIN recovery)."
