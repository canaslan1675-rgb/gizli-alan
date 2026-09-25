# Device test plan / Cihaz test planı — GizliAlan

Issue: #7 (plan) · Owner runs on real phones: #14 · Status of the emulator run: see §5.

> **TR özet:** Bu plan, sahibinin (veya emülatörü olan bir ajanın) GizliAlan'ı gerçek
> cihazlarda adım adım test etmesi içindir. Öncelik "İkinci telefon"dur (iş profili), çünkü
> bu kutuda cihaz yok ve bu özellik gerçek donanımda hiç denenmedi. Hedef cihazlar:
> **Xiaomi** (MIUI/HyperOS, iş profilini sık engeller), **Samsung** (Güvenli Klasör var),
> **Pixel** (AOSP referansı). Her adımda "Beklenen" sonucu kontrol et, sonuçları §6 tablosuna
> veya #14'e yaz. **Kişisel veri kullanma:** test fotoğrafları/dosyaları kullan, ekran
> görüntülerinde kişisel bilgi olmasın (FLAG_SECURE nedeniyle uygulama içinden ekran görüntüsü
> zaten alınamaz; gerekirse başka bir telefonla fotoğraf çek).

## 0. Setup / Hazırlık

| | |
|---|---|
| Build | Latest test APK from GitHub Releases (e.g. `v0.2.0-test`, arm64, debug-signed) or a newer one built from `main` (`flutter build apk --release --target-platform android-arm64`). |
| Install | `adb install -r GizliAlan-test-*.apk` or open the APK on the phone (allow "install unknown apps" for the file manager/browser — that is a phone setting, not an app permission). |
| Reset between runs | Settings → Apps → Calculator (GizliAlan) → Storage → Clear data. If a work profile was created: remove it in-app (§3.9) or Settings → Accounts/Passwords → Work → Remove work profile. |
| Record | Device model, Android version, OEM skin + version (MIUI/HyperOS/One UI), build/tag, date. |
| Test PINs | Real PIN `2580`, decoy PIN `1111` (test-only values). |

## 1. Install, permissions, branding

| # | Step | Expected |
|---|------|----------|
| 1.1 | Look at the launcher after install. | One icon: original calculator icon, label "Calculator" (EN) / "Hesap Makinesi" (TR). No second icon. Themed (monochrome) icon works on Android 13+ if enabled. |
| 1.2 | Settings → Apps → Calculator → Permissions. | No permissions requested (biometric is not a runtime permission). Nothing about storage, camera, mic, location, SMS, contacts, notifications. |
| 1.3 | Optional, with adb: `adb shell dumpsys package com.offerforge.gizlialan \| grep permission` | Only `USE_BIOMETRIC` (+ AndroidX internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). No `INTERNET`. |
| 1.4 | Settings → Security → Device admin apps. | GizliAlan is **not** listed as an active device admin of the main profile. |

## 2. Core vault (all devices)

| # | Step | Expected |
|---|------|----------|
| 2.1 | First launch → onboarding step 1 without ticking "own device". | Continue is disabled until the box is ticked. |
| 2.2 | Step 2 (calculator entry disclosure) → keep on → step 3 set PIN `2580`. | Calculator opens. |
| 2.3 | Use the calculator: `12+3=`, `7×8=`, `C`. | Correct results (15, 56). Wrong PIN + `=` just calculates, no lockout. |
| 2.4 | Tap ⓘ. | Dialog explains the vault entry. |
| 2.5 | Type `2580=`. | Vault home opens (clock, icon grid, dock with Lock). |
| 2.6 | Long-press `=` after enabling biometrics (Vault → Settings → Biometric unlock). | System biometric prompt; success opens the real vault. |
| 2.7 | Gallery → import 3 test photos with the system Photo Picker. | No permission dialog; 3 items in the grid; viewer, pinch-zoom, export (system "save as"), delete work. Originals stay in the phone gallery. |
| 2.8 | Files → import a PDF. Notes → create, edit, search, delete. | All work; nothing appears in the phone's own gallery/files apps. |
| 2.9 | Recents screen while the vault is open; try a screenshot. | Recents preview is blank/black; screenshot is blocked (FLAG_SECURE). |
| 2.10 | Home button, wait past Auto-lock (Settings → Auto-lock, try "Immediately" and "1 min"), return. | Vault is locked (calculator shown). Opening the Photo Picker / "save as" does **not** lock mid-action. |
| 2.11 | Settings → Decoy PIN `1111`, lock, type `1111=`. | Separate empty vault; no Second phone tile; settings show only neutral options. |
| 2.12 | Lock, go to PIN screen (turn calculator entry off in Settings → Entry) and type 5 wrong PINs. | Lockout with a countdown (30 s, then doubling). |
| 2.13 | Unlock the real vault after 2.12. | **Notifications** tile shows a badge; list says "N wrong PIN attempt(s) since your last unlock". Imports/exports/deletes from 2.7–2.8 are listed. Mark all read / Clear all work. No system notification was ever shown. (Needs PR #19.) |
| 2.14 | Settings → GizliAlan Pro → Buy / Subscribe. | Plans + prices shown; dialog "Not available yet"; no Play purchase sheet, no network. (Needs PR #20.) |
| 2.15 | Settings → Language TR/EN. | All screens switch language. |

## 3. Second phone (work profile) — main focus

Run on each device. Note the exact messages on failure.

| # | Step | Expected |
|---|------|----------|
| 3.1 | Real vault → "Second phone" tile. | Screen explains the feature. On Xiaomi/Redmi/POCO a warning is shown before setup. |
| 3.2 | "Set up second phone" → confirm → Android's own work-profile setup. | System setup runs and finishes; back in the app "Second phone created" (or "pending" then ready after a few seconds). A work badge/tab appears in the phone launcher. |
| 3.3 | Settings → Security → Device admin apps (main profile). | GizliAlan still **not** an active admin of the main profile (only profile owner inside the work profile). |
| 3.4 | "Open Play Store (second account)". | The work profile's Play Store opens; you can add a second Google account there. |
| 3.5 | "Add an app from the main phone" → pick a system app (e.g. Chrome/Calculator) and a normal Play app. | System app: "… was added to the second phone" (enableSystemApp). Play app: the profile Play Store opens on that app (fallback). No "install unknown apps" prompt. |
| 3.6 | Vault home → second-phone app grid → tap an app. | App starts in the work profile (work badge). The vault goes to background and auto-locks, but the app keeps running. |
| 3.7 | Settings → "Second phone on lock" = "Hide its apps" → press **Lock**. | Work apps disappear from the phone launcher. Unlock the real vault → they come back ("Second phone opened"). |
| 3.8 | Same with "Turn work profile off". | Either the work profile turns off, or the app shows "Android did not allow… apps were hidden instead" (expected on most phones; quiet mode is limited to the default launcher). |
| 3.9 | Background auto-lock while a work app is open. | The second phone is **not** closed by auto-lock (only by the Lock button). |
| 3.10 | Decoy vault (`1111=`). | No Second phone tile; locking the decoy does not change the work profile. |
| 3.11 | "Remove second phone" → confirm. | Work profile and its apps/accounts are removed; "Second phone removed". |
| 3.12 | Xiaomi only: if 3.2 fails or is blocked. | App shows the blocked message with the **Second space** (MIUI) / **Private space** (Android 15+) alternative. The app must not crash or loop. |
| 3.13 | Samsung only: with Secure Folder set up. | Work profile setup still works or fails cleanly with the "not allowed" message; Secure Folder is not affected. |
| 3.14 | Security check of the trampoline (optional, adb): `adb shell am start --user <workUserId> -n com.offerforge.gizlialan/.secondphone.ProfileActionActivity` without extras. | Activity finishes immediately and does nothing (unsigned/expired requests are rejected). |

## 4. Device matrix / Cihaz matrisi

| Device | Why | Must pass | Known risk |
|--------|-----|-----------|------------|
| **Pixel** (Android 14/15) or Pixel emulator (AOSP image with Play) | Reference AOSP behaviour | §1–§3 all | Quiet mode falls back to hiding apps |
| **Samsung** (One UI 6/7) | Largest market share in TR; Secure Folder coexists | §1–§3 (3.13) | OEM may block a second managed profile if Secure Folder/Knox uses one |
| **Xiaomi / Redmi / POCO** (MIUI 14 / HyperOS) | Often blocks or half-finishes work-profile provisioning | §1–§2 all; §3 either works or 3.12 fallback is shown cleanly | Provisioning blocked; Second space/Private space fallback |

## 5. Emulator run status (agents)

- **2026-09-25, Joi:** not run. This box has no Android emulator package or system image
  (~2 GB download) and the box user has no `/dev/kvm` access (hardware acceleration), so an
  emulator would be unusably slow. The emulator part of #7 is handed off: any agent with an
  emulator (Pixel, API 34/35, Google Play image) can run §1–§3 and fill in §6.
- **2026-09-26 re-check, Joi:** `/dev/kvm` **exists** (`crw-rw---- root:103`) but the box
  user (`uid=1000(box)`, groups=`box` only) **cannot read or write** it — no membership in
  group `103`. `ANDROID_HOME=/workspace/tools/android-sdk` has no usable `emulator` binary or
  system images for this agent. Without root (or a group/udev change the agent must not do),
  there is still **no usable emulator path** on this box. **Agent-side emulator part of #7 is
  closed** with this documented reason. Physical-device runs remain owner issue **#14**.
- Unit/widget tests on this box cover the Dart side (second phone service/flow with fakes,
  real vs decoy, Xiaomi fallback), but not the Android/Kotlin side.

## 6. Results / Sonuçlar

Copy a row per device and run. Mark each section ✅ / ❌ (+ step numbers) / ⏭ (skipped).

| Date | Tester | Device | Android / skin | Build | §1 | §2 | §3 | Notes |
|------|--------|--------|----------------|-------|----|----|----|-------|
| 2026-09-26 | joi (agent) | Pixel emulator (planned) | N/A | N/A | ⏭ | ⏭ | ⏭ | Not run — `/dev/kvm` present but inaccessible to `box` (root:103); no emulator/system image usable without root. Agent-side #7 closed; physical devices → #14. |
| | | | | | | | | |

Turn every ❌ into a new `task` issue (steps, expected, actual, device) — no personal data.
