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
| Build | Latest test APK from GitHub Releases (e.g. `v0.4.0-test`: `GizliAlan-v0.4.0-play.apk` = no Second phone, `GizliAlan-v0.4.0-full.apk` = with Second phone; arm64, debug-signed; they install side by side) or a newer one built from `main` (`flutter build apk --release --flavor play|full --target-platform android-arm64`). §3 applies to the **full** APK only; on the play APK check that no Second phone tile/setting exists and GizliAlan never appears under Device admin apps. |
| Install | `adb install -r GizliAlan-test-*.apk` or open the APK on the phone (allow "install unknown apps" for the file manager/browser — that is a phone setting, not an app permission). |
| Reset between runs | Settings → Apps → Calculator (GizliAlan) → Storage → Clear data. If a work profile was created: remove it in-app (§3.9) or Settings → Accounts/Passwords → Work → Remove work profile. |
| Record | Device model, Android version, OEM skin + version (MIUI/HyperOS/One UI), build/tag, date. |
| Test PINs | Real PIN `2580`, decoy PIN `1111` (test-only values). |

## 1. Install, permissions, branding

| # | Step | Expected |
|---|------|----------|
| 1.1 | Look at the launcher after install. | One icon: original calculator icon, label "Calculator" (EN) / "Hesap Makinesi" (TR). No second icon. Themed (monochrome) icon works on Android 13+ if enabled. |
| 1.2 | Settings → Apps → Calculator → Permissions. | No permissions requested (biometric is not a runtime permission). Nothing about storage, camera, mic, location, SMS, contacts, notifications. |
| 1.3 | Optional, with adb: `adb shell dumpsys package com.offerforge.gizlialan \| grep permission` | Only `USE_BIOMETRIC` + `INTERNET` (in-vault browser, since 0.4.0) (+ AndroidX internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). No location/camera/mic. |
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
| 2.16 | Gallery → long-press a photo. | Sheet: Open / Set as home background / Export / Delete. "Set as home background" → vault home shows the photo (darkened, clock/labels readable); calculator, gallery and other screens unchanged. Settings → Home screen background → "Remove background" → plain gradient again. Decoy vault has its own (none by default). Deleting that photo → plain gradient. |
| 2.17 | Vault home → **Tarayıcı / Browser** (v0.4.0). Type `example.com`, then `gizlilik` (a search). | Page loads over https; the search opens DuckDuckGo (default). Back/forward/reload work; system Back goes back in page history, then leaves the browser. |
| 2.18 | Settings → Browser → search engine → Startpage; search again. | Search goes to Startpage. No suggestions appear while typing. |
| 2.19 | In the browser, try a screenshot and open Recents. | Blocked / black preview (FLAG_SECURE). |
| 2.20 | Log in to a test site (cookie), Lock, unlock, open the site again. | Logged out (cookies wiped because "Kilitlenince temizle" is on). With the switch off, the login survives a lock; "Şimdi temizle" wipes it. |
| 2.21 | Tap a download link (e.g. a PDF/zip), a `tel:`/`intent:` link and a page asking for location/camera. | Download does nothing (downloads disabled); non-web links show "blocked" snackbar; permission requests are denied silently, no system permission dialog. |
| 2.22 | Settings → Apps → Calculator → Data usage. | Traffic only while using the browser; none from the rest of the app. |
| 2.23 | Vault home on a 1080×2400 phone (v0.4.0). | Default sunset/sea picture fills the screen without visible pixelation; clock, tiles, labels, dock readable. Bottom signature (monospace, faint): `GizliAlan Vault · v0.4.0 (build 6) · play/full`, `AES-256-GCM · PIN: PBKDF2-SHA256 120k · FLAG_SECURE`, `● vault: unlocked · © OfferForge`; not tappable, not over tiles. Not on the calculator. Settings → Wallpaper colour swatch → plain gradient; picture swatch → back. Settings bottom shows "Varsayılan arka plan: Created with Grok". |
