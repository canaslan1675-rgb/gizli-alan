# Policy declarations, justification texts and reviewer demo video

> **TR özet.** `play` flavor'u için **hiçbir hassas izin beyan formu gerekmiyor** (yalnızca `USE_BIOMETRIC` + normal izin `INTERNET`); doldurulacaklar standart App content formları (reklam yok, reklam kimliği yok,
> hedef kitle 18+, içerik derecelendirmesi, veri güvenliği). Bu dosya: (1) standart formlar için hazır cevaplar, (2) `full` flavor'u için cihaz yöneticisi / iş profili gerekçe metni
> (Play Console'da ayrı bir form çıkmazsa App access notlarına ve olası politika e-postası cevabına kullanılır), (3) inceleyiciler için demo video çekim listesi
> (FLAG_SECURE nedeniyle ekran kaydı siyah çıkar; FLAG_SECURE'u kapatan özel bir derleme yapmak yerine **aynı release derlemesini** ikinci bir telefon/kamera ile çekin).

## 1. Standard App content declarations (`play`)

| Declaration | Answer | Text to use where a free-text field exists |
|---|---|---|
| Ads | No | — |
| Advertising ID (apps targeting API 33+) | **No, my app does not use advertising ID** | — |
| Target audience and content | **18 and over** only; "Appeals to children?" **No** | "A private vault for adults' own photos, files and notes. Not designed for children." |
| Content rating (IARC) | Category: Utility / Productivity / Communication-other → "Utility". Violence/sex/language/drugs/gambling: No. User-generated content shared with others: No. Shares location: No. Digital purchases: No (until #15) | — |
| Data safety | see `DATA_SAFETY.md` | — |
| Government app | No | — |
| Financial features | "My app doesn't provide any financial features" | — |
| Health | No health features | — |
| News | No | — |
| Photo & video permissions declaration | Not required (no `READ_MEDIA_*`; system Photo Picker) | If Console ever asks: "The app uses the Android Photo Picker / Storage Access Framework; it requests no media permissions." |
| Foreground service / exact alarm / full-screen intent / VPN / Accessibility / SMS / Call log / All files access / Package visibility (QUERY_ALL_PACKAGES) | Not used → no forms | — |
| `IsMonitoringTool` | **Not set** — GizliAlan is not a monitoring app | — |

## 2. `full` flavor — device admin / managed profile justification

No dedicated Play Console form for `BIND_DEVICE_ADMIN` was found in the current policy pages
**[UNCERTAIN — check App content → "Needs attention" after uploading the `full` AAB]**. Use this text (a) in the
App access "Any other instructions", (b) if a declaration form appears, (c) in replies to policy e-mails.

### 2.1 Short justification (≈ 500 chars)

```
GizliAlan uses a DeviceAdminReceiver ONLY to become profile owner of an Android work profile that the user creates in-app ("Second phone", same model as Shelter/Island), via Android's own ACTION_PROVISION_MANAGED_PROFILE consent flow. The receiver declares no device-admin policies, is never device owner, and deactivates itself if enabled as a main-profile device admin. No data from the profile is read or sent. (The app's only network use is the optional in-vault browser loading pages the user opens; the app itself sends nothing.)
```

### 2.2 Full justification

```
Core feature: "Second phone" gives the device owner a separate, Android-isolated space for a second set of apps and accounts (e.g. a second Google account and its own Play Store), next to the encrypted vault. Android implements this isolation as a managed work profile, which requires a profile-owner app (DPC). GizliAlan is that DPC for the one profile the user creates.

How consent works: the user unlocks the vault, opens "Second phone", reads GizliAlan's explanation and taps "Set up second phone". Android's own provisioning UI then asks for consent and shows its own notices. Nothing happens without these steps.

What the role is used for (all on user action): open the profile's Play Store, make an existing app available inside the profile, list/launch profile apps from the vault, hide/unhide profile apps when the vault locks/unlocks (user setting), and remove the profile.

What it is NOT used for: no policies on the main profile or device (the device_admin XML declares an empty <uses-policies/>), never device owner, no password/lock/wipe/camera/keyguard policies, no blocking of uninstall, no reading of data, messages, notifications or usage of apps inside the profile, no installation of apps from outside Google Play (no REQUEST_INSTALL_PACKAGES), no QUERY_ALL_PACKAGES, no network access at all.

Removal: in-app "Remove second phone" or Android Settings > Accounts > Work profile > Remove. If the receiver is ever activated as a device admin of the main profile (e.g. via Settings > Device admin apps), it immediately calls removeActiveAdmin on itself.

Disclosure: store listing section "SECOND PHONE" with a "DEVICE ADMIN PRIVILEGE" bullet, in-app explanation before setup, privacy policy section "Second phone", reviewer notes and demo video.
```

### 2.3 In-app disclosure checklist for `full` (verify in build before submitting)

- [ ] Explanation screen before `ACTION_PROVISION_MANAGED_PROFILE` states: work profile, profile owner, what the app will/won't do, how to remove.
- [ ] Wording "device admin" appears in that explanation (Google historically asked for in-app disclosure at the point the admin feature is requested — [r/androiddev 2017](https://www.reddit.com/r/androiddev/comments/6tuavo/ive_received_a_mail_from_google_about_bind_device/)).
- [ ] `profile_admin_description` string (shown by Android) is accurate.

## 3. Demo video script (shot list) for reviewers

Recording note: FLAG_SECURE makes screen recordings black **by design**. Film the **same release build** on a
real phone with a second camera/phone (steady, well lit, no personal data on screen), or record on an emulator
with a camera pointed at the monitor. Do **not** make a special build without FLAG_SECURE for the video (it would
be a different binary; keep it identical). Length 2–3 min (`play`) / 4–5 min (`full`). Upload as **unlisted**
YouTube video; put the link in App access. Use demo content only (pattern images, "Shopping list" note).

### 3.1 `play` (≈ 2.5 min)

| # | Shot | What to show / say (caption) |
|---|---|---|
| 1 | App drawer | "The app appears as 'Calculator' with this original icon. That icon is GizliAlan." |
| 2 | Tap icon, first launch, onboarding step 1 | "What GizliAlan is"; tick "This is my own device". |
| 3 | Onboarding step 2 | Read the calculator-entry disclosure; show the toggle. |
| 4 | Step 3 | Set PIN `<DEMO_PIN>`, confirm; show the "no PIN recovery" warning. |
| 5 | Calculator | Compute `12 × 3 = 36` — it's a real calculator. |
| 6 | ⓘ button | Open the ⓘ dialog, pause 3 s on the text. |
| 7 | Enter vault | Type `<DEMO_PIN>` then `=` → vault home. |
| 8 | Gallery | "+" → Android photo picker → pick 2 demo images → grid → open → export dialog → delete one. |
| 9 | Notes / Files | Create a note, search it; add a PDF via the file picker. |
| 10 | Settings | Biometric unlock on → back to calculator → long-press `=` → fingerprint prompt. |
| 11 | Decoy PIN | Set decoy `<DECOY_PIN>` → lock → enter decoy PIN → empty separate vault. |
| 12 | Settings → Entry | Turn calculator entry off → relaunch → PIN screen directly. |
| 13 | Privacy & permissions | Scroll the in-app privacy text. |
| 14 | Android Settings → Apps → Calculator → Permissions | "No permissions requested" (biometric is an install-time permission, no runtime prompts); Android shows "Have full network access" (INTERNET, install-time, used only by the in-vault browser). |
| 15 | Home button | App auto-locks; recents shows a blank preview (FLAG_SECURE). |

### 3.2 `full` additions (≈ +2 min)

| # | Shot | Caption |
|---|---|---|
| 16 | Vault → Second phone | GizliAlan's explanation screen (work profile, profile owner, removal). |
| 17 | Set up | Android's own work-profile consent screens → progress → done. |
| 18 | Open Play Store (second account) | Play Store badge with work icon; (don't sign in with a real account on camera). |
| 19 | Add an app | Pick an app from the main phone → appears in the profile grid. |
| 20 | Lock vault | Profile apps hidden (launcher Work tab) → unlock → visible again. |
| 21 | Android Settings → Security → Device admin apps | Personal section: GizliAlan is **not** active; it appears only as the Work profile's admin. |
| 22 | Remove | "Remove second phone" → profile gone (Settings → Accounts shows no work profile). |
