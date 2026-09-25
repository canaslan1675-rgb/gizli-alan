# Data safety form — suggested answers

> **TR özet.** Önerilen cevap: **"Uygulama zorunlu kullanıcı veri türlerinden hiçbirini toplamıyor veya paylaşmıyor."** Gerekçe: Google'ın tanımına göre yalnızca cihazda işlenen ve
> cihazdan çıkmayan veri "toplanmış" sayılmaz; GizliAlan geliştiriciye/üçüncü tarafa hiçbir veri göndermez, veri toplayan SDK yok. 0.4.0'dan itibaren INTERNET izni var ama yalnızca kasa içi tarayıcı içindir: kullanıcının kendi açtığı sitelere giden trafik, geliştiricinin veri toplaması değildir (tarayıcı uygulamalarındaki gibi). Form yine de **zorunlu** ve gizlilik politikası URL'si
> ile birlikte doldurulmalı. `full` flavor'u için de cevap aynı (iş profili uygulamalarının verisi okunmaz, başka uygulamaya kullanıcı verisi aktarılmaz).
> Faturalama (Play Billing), çökme raporlama veya yedekleme SDK'sı eklenirse form **yeniden** doldurulmalı.

Source: [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469) (fetched 2026-09-26).

## Key definitions (quoted from Google)

- *"On-device access/processing: User data accessed by your app that is only processed locally on the user's device and not sent off device does not need to be disclosed."*
- *"Even developers with apps that do not collect any user data must complete this form and provide a link to their privacy policy. In this case, the completed form and privacy policy can indicate that no user data is collected or shared."*
- Sharing includes *"On-device transfer to another app … even if your app does not transmit the data off the user's device."*
- Apps only on the **internal** testing track are exempt; **closed** testing already requires the form.

## Evidence from the build

| Check | Result |
|---|---|
| Release permissions | `USE_BIOMETRIC` + `INTERNET` (+ AndroidX signature-level internal permission) — verified 2026-09-26 with `aapt2 dump permissions` on the v0.4.0 APKs of both flavors |
| INTERNET permission | present since 0.4.0, used **only** by the in-vault private browser (Android System WebView via `webview_flutter`). The app has no server, no analytics/telemetry/crash reporting, no ads; no app code opens network connections. Traffic goes only to sites the user types/opens. WebView metrics opt-out is set (`android.webkit.WebView.MetricsOptOut=true`); Safe Browsing is left at the WebView default (Google Play services may check visited URLs against Google's list — a platform component, not our SDK). |
| User-initiated browsing | **[Judgement]** Web pages the user chooses to visit receive the user's IP and whatever the user types into them, exactly like any browser. Google's definition of *collection* is data transmitted off device *by your app* to you or a third party; browsing sites the user deliberately opens is user-initiated and not collected by the developer. Browsers on Play (e.g. DuckDuckGo) declare data they themselves collect, not the content of sites visited. Answer stays **no data collected/shared**; describe the browser in the privacy policy. If a reviewer disagrees, the conservative fallback is "Web browsing history — collected — ephemeral, not shared" — but we store none off device. |
| SDKs | `webview_flutter(_android)` (system WebView wrapper, no telemetry), `flutter_secure_storage`, `local_auth`, `image_picker`, `file_picker`, `path_provider`, `shared_preferences`, `cryptography(_flutter)`, `crypto`, `intl`, `path`, `uuid` — none collect or transmit data |
| Backup | `allowBackup=false`, data-extraction rules exclude everything → no Google cloud backup of vault data |
| Sharing to other apps | Only when the **user** exports a file via the system "save as" dialog (user-initiated, user chooses the destination). **[Judgement]** This is the user moving their own file, not the app sharing data with a third party; Google's examples of sharing are app-initiated transfers. If a reviewer disagrees, declare "Files and docs / Photos — shared — user-initiated" (optional disclosure is allowed to be conservative). |

## Form answers

### Data collection and security

| Question | Answer | Reason |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | All vault content, PIN hash, keys, events and preferences stay on the device; no network |

When the answer is **No**, Play shows "No data collected" and "No data shared with third parties".
**[UNCERTAIN]** If the current form still asks the follow-up questions, use:

| Question | Answer |
|---|---|
| Is all of the user data collected by your app encrypted in transit? | Not applicable — no user data is collected or transmitted. Normally this question is skipped when the first answer is **No**; never tick a claim just to fill the form |
| Do you provide a way for users to request that their data is deleted? | Users can delete everything in-app (Settings → "Reset everything"), per item, or by uninstalling / Clear data. No account → no server-side data |
| Independent security review (MASA) | **No** (don't claim a badge you don't have) |
| Committed to Play Families Policy | Not applicable (18+) |

### Data types (for reference — all "not collected")

| Category | Accessed on device? | Collected? | Shared? |
|---|---|---|---|
| Photos and videos | Yes — only photos the user picks, stored encrypted locally | No | No |
| Files and docs | Yes — only files the user picks | No | No |
| Personal info (name, e-mail…) | No | No | No |
| Financial info | No | No | No |
| Messages / Contacts / Calendar / Location | No | No | No |
| App activity (in-app events list) | Yes — the app's own events, encrypted locally | No | No |
| App info & performance (crash logs, diagnostics) | No crash SDK | No | No |
| Device or other IDs | No (no Advertising ID permission) | No | No |
| Biometric data | Never received — Android BiometricPrompt returns success/failure only | No | No |
| Installed apps (`full` only) | Names/icons of **launchable** apps via a MAIN/LAUNCHER query, to draw the app grid on device | No | No |

## Consistency checks before submitting

- [ ] `PRIVACY.md` (hosted) says the same: nothing collected, nothing shared, on-device only.
- [ ] Listing says "No account, no server, no ads, no analytics, no tracking" and mentions the browser only talks to sites you open (no "no internet permission" claim any more).
- [ ] App content → Ads = **No**; Advertising ID = **No**.
- [ ] Re-do this form **before** adding Play Billing (#15) — Play Billing itself: purchase history is handled by Google Play; the app would still not collect data unless it sends purchase info to a server. Re-check Google's guidance then.
