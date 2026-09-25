# Google Play submission research — GizliAlan (play + full flavors)

> **TR özet.** 26 Eylül 2026 itibarıyla resmi Google Play politika sayfaları yeniden okundu (bağlantılar aşağıda).
> Sonuç: **`play` flavor'u (kasa + gerçek hesap makinesi girişi, cihaz yöneticisi bileşeni yok) politikalara uygun ve onaylanma olasılığı yüksek**; en büyük engel politika değil **süreç**: yeni kişisel hesap için
> **en az 12 test kullanıcısıyla kesintisiz 14 günlük kapalı test**, ardından üretim erişimi başvurusu, kimlik + telefon + **fiziksel Android cihaz doğrulaması** (Play Console uygulaması, Android 10+).
> Hedef API: **31 Ağustos 2026'dan beri yeni uygulamalar API 36 (Android 16) hedeflemeli** — Flutter 3.47.5 varsayılanı zaten 36. 16 KB sayfa boyutu (Kasım 2025'ten beri) ve AAB + Play App Signing zorunlu. D-U-N-S kişisel hesap için **gerekmez**.
> Asıl politika riski **Aldatıcı Davranış / Yanlış Tanıtım**: başlatıcıda "Hesap Makinesi" adı. Açıklama + onboarding + ⓘ + mağaza başlığında "Hesap makineli kasa" ifadesi ile risk düşük-orta. Play'de 100M+ indirmeli benzer "calculator vault" uygulamaları var (emsal).
> `full` flavor'u (iş profili / profil sahibi DPC) Play'e gönderilirse risk **orta-yüksek**; emsal: Island (10M+, Play'de, açıklamasında DEVICE-ADMIN gerekçesi yazıyor; 2023'te REQUEST_INSTALL_PACKAGES yüzünden bir kez kaldırılıp geri döndü). Öneri: **Play'e yalnızca `play`**, `full` yan yükleme; ancak 2027'deki küresel "Android geliştirici doğrulaması" için `com.offerforge.gizlialan.full` paketinin de Play Console'da kaydedilmesi gerekecek.
> İki yeni bulgu: (1) Ayarlar'daki **Pro arayüz taslağı** (çalışmayan satın alma düğmeleri) "bozuk işlev" olarak algılanabilir → Play derlemesinde gizlenmeli veya gerçek faturalama gelmeli; (2) Kullanıcı Verisi politikası **uygulama içinde gizlilik politikasına erişim** istiyor → uygulama içi gizlilik metni var, barındırılan URL de metne eklenmeli.

Research date: **2026-09-26** (Europe/Istanbul). All policy pages below were fetched on this date
(English versions). Policy text changes often — re-check the linked pages on the day of submission.
Items marked **[UNCERTAIN]** could not be confirmed from an official source.

---

## 1. Scope and assumptions

| Item | Value (from repo, `main` @ 13562b8) |
|------|------|
| Play candidate | **`play` flavor**, `applicationId com.offerforge.gizlialan`, no Second phone, no `DeviceAdminReceiver`/`BIND_DEVICE_ADMIN`, no LAUNCHER `<queries>` |
| Side-load flavor | `full`, `com.offerforge.gizlialan.full`, Second phone = managed work profile, app is profile owner only |
| Permissions (both) | `USE_BIOMETRIC` only (+ AndroidX-internal signature permission); no `INTERNET` in release |
| Launcher | label "Calculator" / "Hesap Makinesi", original navy/mint calculator icon; the app **is** a working calculator; PIN + `=` opens vault; long-press `=` biometrics |
| Disclosure | onboarding step 2 (entry disclosure + toggle), ⓘ dialog, store listing, reviewer notes |
| Data | AES-256-GCM on device, PBKDF2 PIN hash, no account, no server, no ads/analytics, backups disabled |
| Version | 0.3.1+4 (Pro stub hidden in `play`, in-app policy link, feature graphic — #28), `minSdk 28`, `targetSdk = flutter.targetSdkVersion` = **36** (Flutter 3.47.5), `compileSdk 36` |
| Developer | new **personal** Play developer account, Turkey |

---

## 2. Current hard requirements (process / technical)

| Requirement | Current rule | Source | GizliAlan |
|---|---|---|---|
| Target API | **New apps and updates must target Android 16 (API 36) since 31 Aug 2026** (extension to 1 Nov 2026 possible for updates) | [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878) · [developer.android.com target-sdk](https://developer.android.com/google/play/requirements/target-sdk) | **Verified 2026-09-26:** `aapt2 dump badging app-play-release.apk` → `targetSdkVersion:'36'`, compileSdk 36 |
| 16 KB page size | New apps/updates targeting Android 15+ must support 16 KB pages on 64-bit devices (since 1 Nov 2025) | [Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes) · [Android Developers Blog, May 2025](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html) | **Verified 2026-09-26** on `app-play-release.aab`: every 64-bit `.so` has ELF LOAD alignment ≥ 16 KB (`libflutter`/`libapp` 64 KB, `libdartjni`/`libdatastore_shared_counter` 16 KB). Re-check in App bundle explorer after upload |
| 64-bit | Apps with native code must ship 64-bit libraries | [64-bit requirement](https://developer.android.com/google/play/requirements/64-bit) | Flutter AAB includes `arm64-v8a` + `x86_64` → OK |
| App format | New apps must be published as **Android App Bundle (.aab)** with **Play App Signing** (accepted when the app is created) | [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756) · [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152) | Build: `flutter build appbundle --release --flavor play`. Upload key = RSA ≥ 2048 (owner, #13) |
| Closed test (new personal accounts, created after 13 Nov 2023) | **≥ 12 testers opted in continuously for the preceding 14 days**, then *apply for production access* (questionnaire about the test, feedback, readiness). Production and pre-registration are locked until then; open testing only after production access | [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465) (verified 2026-09-26: 12 testers / 14 days) | **Owner task.** Plan ≥ 15–20 real testers so drop-outs don't reset the clock |
| Device verification | New personal accounts must verify access to a **physical, non-rooted Android 10+ device** using the Play Console mobile app | [Device verification requirements](https://support.google.com/googleplay/android-developer/answer/14316361) | Owner task |
| Identity / contact verification | Personal: developer name, **legal name + legal address** (from Google payments profile), contact e-mail + phone (OTP-verified), developer e-mail. Google **shows legal name, country and developer e-mail** on Play; **full address is shown if you monetize** | [Required information to create a Play Console developer account](https://support.google.com/googleplay/android-developer/answer/13628312) · [Verify your developer identity](https://support.google.com/googleplay/android-developer/answer/10841920) | Owner task. Privacy note for owner: once Pro/IAP is live, the address becomes public |
| D-U-N-S | Required for **organization** accounts only | same as above | **Not needed** (personal) |
| Privacy policy | Required for **all** apps (even with no data access), on an active public URL, and available **within the app** | [Prepare your app for review → Privacy policy](https://support.google.com/googleplay/android-developer/answer/9859455) · [User Data](https://support.google.com/googleplay/android-developer/answer/10144311) | `PRIVACY.md` exists; **hosting on HTTPS = owner (#12)**; in-app privacy text exists (Settings), URL should be added to it |
| Data safety form | Mandatory for all apps on closed/open/production tracks, even if nothing is collected; must match the privacy policy | [Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469) | Answers drafted in `DATA_SAFETY.md` |
| Store graphics | Icon 512×512 32-bit PNG (alpha OK) ≤ 1 MB; feature graphic 1024×500; phone screenshots 9:16 or 16:9, 320–3840 px (≥ 1080 px recommended), 2–8 | [Add preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) | Icon `docs/store_icon_512.png` ✔, screenshots `docs/store/screenshots/play/{tr,en}` ✔, **feature graphic missing** |
| Android developer verification (outside Play) | From **30 Sep 2026** installs of apps from unregistered developers are blocked on certified devices in **Brazil, Indonesia, Singapore, Thailand**; **global rollout "2027 and beyond"**. Play Console auto-registers ~99 % of Play apps; apps distributed only outside Play must be registered manually | [Android developer verification](https://developer.android.com/developer-verification) | Relevant for the **side-loaded `full` APK** (`com.offerforge.gizlialan.full`): register it in Play Console before the global deadline. Turkey is not in the first wave **[UNCERTAIN: exact date for Turkey]** |
| Fee | One-time US$25 registration fee **[not re-verified today; long-standing]** | Play Console sign-up | Owner |

---

## 3. Policy-by-policy analysis and risk ranking

Risk scale: **Very low / Low / Medium / High** = probability that *this* policy causes a rejection or a
reviewer question for the **`play`** flavor. The `full` column is for the case the owner submits `full`.

| # | Policy (official page) | What it says (relevant part) | `play` risk | `full` risk |
|---|---|---|---|---|
| 1 | **Deceptive Behavior** — [answer/9888077](https://support.google.com/googleplay/android-developer/answer/9888077) | "Apps must provide an accurate disclosure, description and images/video of their functionality in all parts of the metadata." "Ensure your app's title, icon and description accurately reflect its actual functionality." Prohibits "Apps that attempt to modify or obfuscate behavior during review" and "different core functionality based on … device parameters … not prominently advertised". Enforcement covers the **"Launch / On Device Icon"** as well as the hi-res icon ([real case, Stack Overflow 2024](https://stackoverflow.com/questions/78516018/google-play-console-app-suspended-due-to-deceptive-behavior-policy-violation-on)). | **Medium → Low with mitigations** | Medium |
| 2 | **Misrepresentation** — [answer/9888689](https://support.google.com/googleplay/android-developer/answer/9888689) | "Don't misrepresent or conceal your app's primary purpose. Ensure your app's title, icon, and description honestly represent its functionality and purpose." | Low–Medium (same root as #1) | Medium |
| 3 | **Metadata** — [answer/9898842](https://support.google.com/googleplay/android-developer/answer/9898842) | Title ≤ 30 chars; no emojis/ALL CAPS/repeated special characters in title/icon/developer name; no ranking/price/promo text; no keyword repetition; no unattributed testimonials; description "clear and well-written", excessive length/repetition can violate. | Low | Low |
| 4 | **Impersonation** — [answer/9888374](https://support.google.com/googleplay/android-developer/answer/9888374) | No icons/titles "so similar to those of existing products … that users may be misled"; no implied relationship with another company or app. | Low (original icon, generic word "Calculator", no vendor branding) | Low |
| 5 | **Functionality, Content & UX (Broken functionality)** — [answer/9898783](https://support.google.com/googleplay/android-developer/answer/9898783) | No apps that crash or "function abnormally"; third-party guides list "buttons that do nothing, placeholder screens" as a frequent rejection ([Testers Community, Aug 2026](https://www.testerscommunity.com/blog/google-play-app-rejected)). | **Medium** — Settings → "GizliAlan Pro" shows Buy/Subscribe buttons that only say "not available in this test build" | Medium |
| 6 | **User Data** — [answer/10144311](https://support.google.com/googleplay/android-developer/answer/10144311) | Privacy policy in Console **and within the app**; must match Data safety; prominent disclosure only needed for data collected/used beyond expectation. | Low (nothing collected) — becomes a blocker if URL missing | Low |
| 7 | **Data safety** — [answer/10787469](https://support.google.com/googleplay/android-developer/answer/10787469) | "On-device access/processing: User data accessed by your app that is only processed locally on the user's device and not sent off device does not need to be disclosed." Form still mandatory. | Very low | Very low (note: on-device transfer *to another app* counts as sharing — GizliAlan only launches apps, transfers no user data) |
| 8 | **Malware → Stalkerware / Spyware** — [answer/9888380](https://support.google.com/googleplay/android-developer/answer/9888380) | Monitoring another person by collecting **and transmitting** data is prohibited unless parental/enterprise with `IsMonitoringTool`, persistent notification, etc. Ransomware examples include "Leveraging device policy manager features and blocking removal by the user". | Very low (no network, no monitoring, no admin) | Low (DPC exists but empty policies, user-removable, self-deactivates as device admin) |
| 9 | **Device and Network Abuse** — [answer/9888379](https://support.google.com/googleplay/android-developer/answer/9888379) | No unauthorized interference with device/other apps; no self-update outside Play; "Respect the FLAG_SECURE setting, and on-device containers must respect REQUIRE_SECURE_ENV"; "Apps that install other apps … without the user's prior consent". | Very low | **Medium** (work profile = on-device container; installs/unhides apps inside the profile on user action; must never install silently) |
| 10 | **Permissions and APIs that access sensitive information** — [answer/9888170](https://support.google.com/googleplay/android-developer/answer/9888170) | Request only what is needed; don't "prevent the ability for users to disable or uninstall any app … unless … authorized administrators through enterprise management software"; don't "work around Android built-in platform security controls". No dedicated device-admin declaration form found **[UNCERTAIN whether Console shows one for BIND_DEVICE_ADMIN today]**. | Very low (only `USE_BIOMETRIC`) | **Medium–High** (DeviceAdminReceiver, `setApplicationHidden` in own profile) |
| 11 | **Mobile Unwanted Software** — [answer/9970222](https://support.google.com/googleplay/android-developer/answer/9970222) | Be transparent about all principal functions; "Explicitly and clearly explain to the user what system changes will be made"; uninstall must be clear. | Low | Medium (explain work-profile creation and removal; Android's own provisioning consent helps) |
| 12 | **Enabling dishonest behavior** (part of Deceptive Behavior) | Apps must not help users mislead others (fake IDs etc.). | Low — decoy PIN opens a separate empty vault; precedent: Keepsafe "Fake PIN" on Play ([Keepsafe Calculator listing](https://play.google.com/store/apps/details?id=com.getkeepsafe.morpheus)) | Low |
| 13 | **Payments** (Play billing) | Digital features must use Play Billing; listing that mentions paid features must say payment is required. | Low now (no billing, no price in listing); relevant when #15 lands | same |
| 14 | **Spam → repetitive content** | Multiple near-identical apps from one developer. **[Inference]** | N/A if only one flavor is published on Play | Do **not** publish both `play` and `full` as two Play listings |
| 15 | **Families** | Not applicable — target audience 18+, not designed for children. | — | — |
| 16 | **Enforcement / appeals** — [Enforcement process](https://support.google.com/googleplay/android-developer/answer/9899234) · [Managing violations and appeals](https://support.google.com/googleplay/android-developer/answer/9899142) · [Policy status](https://support.google.com/googleplay/android-developer/answer/9842754) | Rejection does **not** affect account standing; removals can accumulate; suspensions are strikes. "Do not attempt to resubmit a rejected app until you've fixed all the policy violations." Appeal via the enforcement e-mail link or Policy status page. | process | process |

### 3.1 Why the calculator label is allowed — and where the line is

- The policies do **not** forbid a calculator look; they forbid *misrepresenting or concealing the primary purpose* (Misrepresentation) and metadata that does not "accurately reflect its actual functionality" (Deceptive Behavior).
- GizliAlan's primary purpose is a vault; the calculator is a real, working secondary function and the entry mechanism. Therefore the **listing must lead with the vault** and must say, in plain words, that the app appears as "Calculator"/"Hesap Makinesi" on the device.
- Real-world evidence (Play Store pages fetched 2026-09-26, US store, category **Tools**):

| App | Installs | Last update | How it presents itself |
|---|---|---|---|
| [HideU: Calculator Lock](https://play.google.com/store/apps/details?id=com.calculator.hideu) | 100M+ | 31 Jul 2026 | Title contains "Calculator Lock"; description: "Disguised as a secret calculator", "Enter your password on calculator and press '=' button" |
| [Calculator - photo vault](https://play.google.com/store/apps/details?id=com.hld.anzenbokusucal) | 10M+ | 3 Aug 2026 | "Calculator" + "vault" in title |
| [Calculator Vault - App Hider](https://play.google.com/store/apps/details?id=com.app.calculator.vault.hider) | 10M+ | 14 Sep 2026 | same pattern |
| [Calculator Lock - Hide Photos](https://play.google.com/store/apps/details?id=calc.gallery.lock) | 10M+ | 22 Jul 2026 | same pattern |
| [Calculator Photo Vault (Keepsafe)](https://play.google.com/store/apps/details?id=com.getkeepsafe.morpheus) | 500K+ | 17 Sep 2026 | "Hide your photos and videos behind a calculator", "Fake PIN" decoy vault |

  Pattern that is approved today: **the store title itself says "Calculator … Vault/Lock"**, the icon is a calculator, and the description explains PIN + `=`. GizliAlan's current draft title ("GizliAlan: Private Vault") does **not** mention the calculator, so a user (or reviewer) who installs it sees an icon/label ("Calculator") that the title does not announce. **Recommendation: put "Calculator Vault" / "Hesap Makineli Kasa" in the title** (see LISTING_*.md). This is both the most honest option and the one with the most precedent.
- Differentiators that help GizliAlan (and are true): no internet permission, only one permission, no ads/accounts/analytics, no icon switching, no "hide from partner" marketing, calculator entry can be turned off, vault disclosed inside the app before first use. Competitors use words like "disguised", "secret", "no one will know" — **GizliAlan should avoid those** (they read as concealment towards third parties and invite stalkerware/deception scrutiny). Use "discreet", "private", "for your own content".
- Keep: store icon = launcher icon (same original artwork), first screenshot = calculator **with the ⓘ disclosure open**, second = onboarding disclosure step. Never add icon-hiding, alias switching, "fake crash" screens or review-time behaviour changes.

### 3.2 Work profile (full flavor) — evidence

- **Island** (`com.oasisfeng.island`) — on Play today, **10M+ installs**, category Tools, last update 24 Apr 2025 ([listing](https://play.google.com/store/apps/details?id=com.oasisfeng.island)). Its description contains an explicit permission section: *"DEVICE-ADMIN: Device administrator privilege is required to create the Island space (work profile) … It will be explicitly requested for your consent."* and uninstall instructions ("Destroy Island" / "Remove work profile").
- Island was **removed once (2023)** because Play refused its `REQUEST_INSTALL_PACKAGES` use; the developer's appeal was rejected; it returned with reduced functionality (clones Play-installed apps by opening Play Store inside the profile) — [GitHub issue #432](https://github.com/oasisfeng/island/issues/432), [Island FAQ](https://island.oasisfeng.com/faq). **Lesson:** the DPC role itself was accepted; the extra sensitive permission was not. GizliAlan `full` requests **no** `REQUEST_INSTALL_PACKAGES` and "adds apps" via `enableSystemApp`/Play Store inside the profile — consistent with the post-2023 Island model.
- **Shelter** (`net.typeblog.shelter`) — not on Play (404 on 2026-09-26), distributed via F-Droid. Insular (Island fork) is F-Droid-only. Google's own [Test DPC](https://play.google.com/store/apps/details?id=com.afwsamples.testdpc) is on Play.
- The deprecated Device Admin API guidance ([Device administration overview](https://developer.android.com/work/device-admin)) is about *device-admin policies*; GizliAlan `full` declares an **empty** `<uses-policies/>` and is only a profile owner via `ACTION_PROVISION_MANAGED_PROFILE`, where Android itself shows the consent screens.
- Conclusion: `full` on Play is **possible but not low-risk** for a brand-new personal account whose other listing signal is "calculator look". Combining "calculator label" + "device admin component" in one first submission multiplies the chance of a Deceptive/Unwanted-software flag. **Recommendation:** first release = `play`; consider `full` (or a separate honest "work profile" app with a non-calculator label) only after the account has a clean production history. If `full` ever goes to Play, it must replace `play` in the same listing only if the listing/screenshots are updated, or be a clearly different product (different title, different purpose) to avoid repetitive-content issues.

---

## 4. What makes approval likely (ranked, all legitimate)

1. **Title announces the calculator vault** (e.g. "GizliAlan: Calculator Vault" / "GizliAlan: Hesap Makineli Kasa") — matches the on-device label/icon.
2. **Full disclosure everywhere, identical behaviour for everyone**: listing, onboarding step 2, ⓘ, App access notes, screenshots 1–2. No remote config, no reviewer detection (there is no network anyway — say so).
3. **App access instructions** even though no account exists: the PIN-then-`=` entry is non-obvious; reviewers who can't find the vault may flag "broken/limited functionality" or "hidden features".
4. **Minimal footprint**: only `USE_BIOMETRIC`, no INTERNET, no Accessibility, no admin in `play`. Say it in the listing — it's a genuine differentiator.
5. **No non-functional UI in the Play build** — hide the Pro stub in `play` release builds (or ship real Play Billing first).
6. **Clean Data safety** ("No data collected / shared") that matches `PRIVACY.md` and the binary (no SDKs that collect).
7. **Serious closed test** with ≥ 12 (aim 20) real testers for ≥ 14 days, real feedback, fixes shipped during the test, and good answers to the production-access questionnaire.
8. **Store icon = launcher icon**, original artwork, no vendor look-alike.
9. **Accurate category (Tools), content rating questionnaire done honestly, target audience 18+**, "Contains ads: No", Advertising ID: "No".
10. **Stable build**: no crashes in pre-launch report; test on at least one Android 16 device (targetSdk 36 behaviour changes, e.g. edge-to-edge enforcement, predictive back).

---

## 5. Things that would hurt (avoid)

- Any wording like "disguise", "secret app no one will find", "hide from partner/parents/spouse", "spy", "track".
- Launcher alias/icon switching, "fake crash" screens, hiding the launcher icon.
- Different behaviour on first run, by locale, or "reviewer mode".
- Linking the side-loaded `full` APK from the Play listing or the Play build.
- Keyword lists ("vault, locker, hide, secret, gallery, private, …") in the description.
- Screenshots that show the Second phone in the `play` listing (not in the build).
- Claiming "unbreakable", "military-grade", "100 % secure" — unverifiable/misleading claims.

---

## 6. Uncertain / to re-check on submission day

- [UNCERTAIN] Whether Play Console presents a specific declaration for `BIND_DEVICE_ADMIN` / device-admin apps (none found in the current Permissions policy text; historically Google e-mailed developers requiring in-app and listing disclosure — [r/androiddev thread](https://www.reddit.com/r/androiddev/comments/6tuavo/ive_received_a_mail_from_google_about_bind_device/)).
- [UNCERTAIN] Exact date Android developer verification applies to Turkey (page says "2027 and beyond" globally).
- [UNCERTAIN] Registration fee amount (US$25 historically; not re-fetched).
- [UNCERTAIN] Whether the Data safety form still asks the "data deletion" and "encrypted in transit" questions when the answer to "collects or shares" is **No** (it did not in past versions; answers are prepared either way in DATA_SAFETY.md).
- [INFERENCE] The mismatch between Play title and launcher label is not explicitly regulated; the recommendation to include "Calculator" in the title is based on Deceptive Behavior wording + competitor precedent, not a written rule.
- Paid "tester communities" exist; Google's page only says to recruit testers from your networks/communities. Using real, engaged testers is safest; purchased engagement could be judged as inauthentic **[no explicit rule found]**.
