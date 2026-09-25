# Pre-submission checklist — GizliAlan `play` flavor

> **TR özet.** Bu liste Play'e göndermeden önce yapılacak her şeyi repo durumuna göre işaretler (`main` @ 13562b8, 26 Eylül 2026).
> ✅ = repoda hazır/doğrulandı · ⚠️ = kısmen / ajan takip işi · ❌ = eksik · 👤 = **sahibinin işi** (hesap, para, anahtar, Play Console).
> Teknik taraf büyük ölçüde hazır: `play` AAB bu kutuda derlendi, **targetSdk 36**, 64-bit + **16 KB hizalı** kütüphaneler, yalnızca `USE_BIOMETRIC` + `INTERNET` (0.4.0'dan beri, yalnızca kasa içi tarayıcı), cihaz yöneticisi bileşeni yok.
> Açık kalanlar: yükleme anahtarı (#13), gizlilik politikasını HTTPS'te barındırma + destek e-postası (#12), öne çıkan görsel 1024×500, Pro taslağının Play derlemesinde gizlenmesi (öneri), uygulama içine politika URL'si, 12+ test kullanıcısıyla 14 günlük kapalı test ve tüm Play Console formları.

Legend: ✅ done/verified · ⚠️ partial / agent follow-up (code change, not in this docs PR) · ❌ missing · 👤 owner task

## A. Account (👤 owner)

| # | Item | Status | Notes / source |
|---|---|---|---|
| A1 | Create **personal** Play Console account, pay registration fee | 👤 | [Get started](https://support.google.com/googleplay/android-developer/answer/6112435) |
| A2 | Identity verification (legal name + address from Google payments profile, government ID if asked) | 👤 | [Verify your developer identity](https://support.google.com/googleplay/android-developer/answer/10841920). Legal name, country, developer e-mail become public; full address becomes public once you monetize |
| A3 | Verify contact e-mail + phone (OTP) and developer e-mail | 👤 | Use a dedicated support mailbox (also needed for #12) |
| A4 | **Device verification** with the Play Console app on a physical non-rooted Android 10+ phone | 👤 | [Device verification requirements](https://support.google.com/googleplay/android-developer/answer/14316361) |
| A5 | D-U-N-S number | ✅ not required | personal account |
| A6 | Developer name: honest, no "Google/Official/Calculator Inc." style impersonation | 👤 | [Impersonation](https://support.google.com/googleplay/android-developer/answer/9888374) |

## B. Build / technical

| # | Item | Status | Notes |
|---|---|---|---|
| B1 | Flavor `play`, applicationId `com.offerforge.gizlialan` | ✅ | PR #26 |
| B2 | **targetSdk ≥ 36** (required for new apps since 31 Aug 2026) | ✅ verified 2026-09-26 | `aapt2 dump badging app-play-release.apk` → `targetSdkVersion:'36'`, compileSdk 36 |
| B3 | minSdk 28 | ✅ | fine |
| B4 | **AAB** builds | ✅ verified | `flutter build appbundle --release --flavor play` → `app-play-release.aab` (53.7 MB, debug-signed on the box) |
| B5 | **64-bit** native libs | ✅ verified | AAB contains `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| B6 | **16 KB page size** | ✅ verified | all 64-bit `.so` have LOAD alignment ≥ 16384 (`libflutter/libapp` 65536; `libdartjni`, `libdatastore_shared_counter` 16384). Re-check in Play Console → App bundle explorer after upload |
| B7 | Permissions = `USE_BIOMETRIC` + `INTERNET` (browser only, since 0.4.0), no admin, no location | ✅ verified v0.4.0 | + AndroidX-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; xmltree has 0 `admin`/`secondphone` matches |
| B8 | No Advertising ID (`AD_ID`) permission | ✅ | declare "No" in Console |
| B9 | Release signing with **upload key** (RSA ≥ 2048), `android/key.properties` local only | 👤 #13 | [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756). Config ready (PR #21). Back up the keystore + passwords offline |
| B10 | Enrol in **Play App Signing** (accept ToS when creating the app) | 👤 | mandatory for new apps with AAB |
| B11 | versionCode increments for every upload | ✅ | pubspec `0.4.0+6`; bump `+N` per upload |
| B12 | Crash-free on Android 16 device (targetSdk 36 behaviour: edge-to-edge, predictive back) + Android 9 (minSdk) | ⚠️ 👤 #14 | `docs/DEVICE_TEST_PLAN.md`; pre-launch report will also run |
| B13 | FLAG_SECURE unconditional | ✅ | pre-launch report screenshots will be black — expected, mention in reviewer notes |
| B14 | No code that changes behaviour by locale/date/reviewer | ✅ | no developer server, no remote config (network only for user-opened pages in the in-vault browser) |

## C. Policy-relevant app behaviour

| # | Item | Status | Notes |
|---|---|---|---|
| C1 | Real working calculator | ✅ | |
| C2 | Vault disclosed in onboarding step 2 + toggle | ✅ | `entryTitle/entryBody/entryDisclosure` |
| C3 | ⓘ dialog on calculator | ✅ | `calcInfoBody` |
| C4 | "Own device only" confirmation in onboarding | ✅ | `ownDeviceConfirm` |
| C5 | Calculator entry can be switched off | ✅ | Settings → Entry |
| C6 | Original launcher + store icon, no vendor look-alike | ✅ | `tool/gen_launcher_icon.py`, `docs/store_icon_512.png` |
| C7 | No icon hiding / alias switching | ✅ | |
| C8 | **Pro UI stub** hidden in `play` | ✅ #28 (v0.3.1) | `Flavor.hasProStub` = `full` only (`--dart-define=PRO_STUB=true` to review); tests in `test/pro_screen_test.dart` |
| C9 | Privacy policy reachable **inside the app** | ✅ #28 (needs URL) | In-app privacy text + link when built with `--dart-define=PRIVACY_URL=https://…` (ACTION_VIEW intent to the user's browser app). 👤 set the URL after #12 |
| C10 | Decoy PIN described honestly | ✅ | "separate, empty vault" |
| C11 | "Delete everything" / uninstall removes all data | ✅ | backups disabled |

## D. Store listing (Main store listing)

| # | Item | Status | Notes |
|---|---|---|---|
| D1 | Default language + tr-TR and en-US translations | ⚠️ drafts | `LISTING_TR.md`, `LISTING_EN.md` |
| D2 | Title ≤ 30 **including "Calculator Vault" / "Hesap Makineli Kasa"** | ✅ draft | recommendation in RESEARCH §3.1 |
| D3 | Short description ≤ 80 | ✅ draft | |
| D4 | Full description ≤ 4000, no keyword lists, no emoji in title | ✅ draft | |
| D5 | App icon 512×512 PNG ≤ 1 MB | ✅ | `docs/store_icon_512.png` |
| D6 | **Feature graphic 1024×500** | ✅ #28 | `docs/store/feature_graphic/feature_graphic_{tr,en}.png`, RGB, `tool/gen_feature_graphic.py` |
| D7 | Phone screenshots (2–8, 9:16) | ✅ | `docs/store/screenshots/play/{tr,en}/01…06` (1080×1920). 01 = calculator + ⓘ, 02 = onboarding disclosure |
| D8 | Category **Tools** | 👤 | competitors (HideU, Island, Calculator Vault) are Tools |
| D9 | Contact e-mail (public), website optional | 👤 #12 | |
| D10 | Privacy policy URL (HTTPS, public, not PDF, no login) | 👤 #12 | GitHub Pages works |
| D11 | "External marketing" opt-out optional | 👤 | Store settings |

## E. App content (Policy → App content)

| # | Form | Suggested answer | Status |
|---|---|---|---|
| E1 | Privacy policy | hosted URL | 👤 #12 |
| E2 | App access | "All or some functionality is restricted" + instructions from `REVIEWER_NOTES.md` | ✅ draft |
| E3 | Ads | **No** | ✅ |
| E4 | Content rating (IARC questionnaire) | Utility/Productivity; no violence, no UGC sharing, no gambling, no location sharing, no purchases of digital goods (until #15) → expected **Everyone/PEGI 3** style rating **[depends on answers]** | 👤 |
| E5 | Target audience | **18+** only (not designed for children) | ✅ draft |
| E6 | Data safety | "No data collected, no data shared" (`DATA_SAFETY.md`) | ✅ draft |
| E7 | Advertising ID | **No** | ✅ |
| E8 | Government app / Financial features / Health / News / COVID | **No** / not applicable | ✅ |
| E9 | Sensitive permission declarations (SMS, Call log, All files, Photos/Videos, Accessibility, FGS, Exact alarm, Full-screen intent, VPN) | **None needed** for `play` | ✅ |

## F. Testing & release (👤)

| # | Item | Status | Notes |
|---|---|---|---|
| F1 | Internal testing track (optional first smoke test) | 👤 | no review wait |
| F2 | **Closed testing with ≥ 12 testers opted in for 14 continuous days** | 👤 | [requirements](https://support.google.com/googleplay/android-developer/answer/14151465). Recruit 15–20 real people; send them `REVIEWER_NOTES` §1 as a test guide; keep a feedback log |
| F3 | Ship at least one improvement during the test | 👤/agent | good material for the production-access questionnaire |
| F4 | Apply for production access (Dashboard) | 👤 | answer honestly: who tested, how feedback was collected, what changed |
| F5 | Production release, staged rollout (e.g. 20 %) | 👤 | |
| F6 | Monitor Policy status + inbox for 7 days | 👤 | `APPEAL_PLAYBOOK.md` |

## G. `full` flavor (only if the owner decides to put it on Play — not recommended for the first release)

| # | Item | Status |
|---|---|---|
| G1 | Device-tested on Pixel, Samsung (+ Xiaomi warning path) | ❌ #14 |
| G2 | Listing variant with DEVICE-ADMIN / work-profile section | ✅ draft (`LISTING_*.md` §Full) |
| G3 | Reviewer notes + demo video (work profile) | ✅ draft (`REVIEWER_NOTES.md` §3, `DECLARATIONS.md` §3) |
| G4 | Screenshots `docs/store/screenshots/full/…` incl. Second phone frame | ⚠️ current full set has no Second phone frame |
| G5 | Do not publish `play` and `full` as two near-identical Play listings | policy (repetitive content) |
| G6 | If `full` stays side-load only: register `com.offerforge.gizlialan.full` in Play Console for Android developer verification before the 2027 global rollout; sign with a key you control | 👤 [developer verification](https://developer.android.com/developer-verification) |
| G7 | Don't link the side-load APK from the Play listing or Play build | policy (Malware/Device abuse "link to non-compliant APKs"; avoid any appearance) |
