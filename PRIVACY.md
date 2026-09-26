# Privacy Policy — GizliAlan

**Last updated:** 2026-09-26
**App:** GizliAlan (package `com.offerforge.gizlialan`)
**Audience:** The owner of the device, for their own content only.

> TR özet aşağıda. / Turkish summary below.

## Summary

GizliAlan is an **on-device** personal vault. Photos, files and notes you add are
**encrypted and stored only on your device**. There is no account, no server,
no analytics, no telemetry, no advertising and no crash-reporting SDK. The app
never sends your vault content or any usage data anywhere. Since version 0.4.0
the app requests the Internet permission **only** for the optional in-vault
private browser: the only network traffic is to web pages that **you** open
there (see "Private browser" below).

## What the app stores (on your device only)

| Data | Where | Protection | Purpose |
|------|-------|-----------|---------|
| Vault photos, files, notes | App-private storage (`files/spaces/…`) | AES-256-GCM, random nonce per item; file names/types are inside an encrypted index | Your vault |
| Vault data keys (one per vault) | `flutter_secure_storage` (Android Keystore-backed) | Hardware/OS-protected key storage | Decrypt your vault |
| PIN and optional decoy PIN | `flutter_secure_storage` | Only a salted PBKDF2-HMAC-SHA256 hash is kept, never the PIN | Unlock |
| In-vault notification list (the app's own events: imports, exports, deletions, Second phone changes, number of wrong PIN attempts) | App-private storage (`files/spaces/<vault>/events.gae`) | AES-256-GCM, separate per vault; shown only inside the unlocked vault, never as a system notification | Tell you what happened in your vault |
| Failed-attempt counters | `flutter_secure_storage` | — | Brute-force throttling; count of wrong PIN attempts since your last unlock (shown in the real vault's notification list) |
| Preferences (language, auto-lock, calculator entry, biometrics on/off, wallpaper) | SharedPreferences (app-private) | Not secret | App settings |

Biometric unlock uses Android's BiometricPrompt. The app **never receives or
stores** fingerprint/face data; Android only tells it "success" or "failure".

## What the app does NOT do

- No collection, sale or sharing of personal data. The app uploads nothing and
  has no server. (Pages you open in the private browser receive what any
  website receives from a browser — see below.)
- No SMS, call log, contacts, location, microphone or camera access.
- No Accessibility Service, Notification Listener or overlays. GizliAlan is
  never a device administrator of your phone or main profile (see "Second
  phone" below for the optional work profile).
- No monitoring of other apps or other people. GizliAlan is not a tracking or
  "spy" tool and must not be installed on someone else's device.
- No advertising ID, no analytics, no telemetry, no crash reporting, no ads,
  no third-party SDKs that collect data.
- No cloud backup: Android auto-backup and device-transfer are disabled for
  this app.

## Permissions

| Permission | Why |
|-----------|-----|
| `USE_BIOMETRIC` | Optional fingerprint/face unlock of your vault |
| `INTERNET` | Only for the in-vault private browser, to load pages **you** open (since 0.4.0) |

Photos and files are imported only when **you** pick them in the system Photo
Picker / file picker (no storage or media permission). Export uses the system
"save as" dialog. Location permissions that the WebView plugin would add are
removed from the manifest. If a build shows a link to this
policy (Settings → Privacy & permissions) and you tap "Open in browser", your
browser app opens the page — GizliAlan itself sends nothing.

## Private browser (since 0.4.0)

The vault home screen has an optional **Browser** ("Tarayıcı"). It uses
Android System WebView. GizliAlan adds no tracking to it and sends nothing to
the developer. What happens when you use it:

- Only the pages **you** type or open are loaded. Searches go to the search
  engine you choose (default DuckDuckGo; Startpage, Brave, Google or Bing
  selectable). No search-suggestion requests are made while you type.
- Those websites see your IP address and whatever you send them, as with any
  browser. Their own privacy policies apply.
- Android System WebView's **Safe Browsing** is left at the platform default:
  Android/Google Play services may check visited URLs against Google's list of
  dangerous sites. This is a system component, not an SDK in GizliAlan. WebView
  usage-metrics upload is opted out.
- Cookies, cache and site storage live in the app's private storage and are
  **deleted when the vault locks** (setting "Kilitlenince temizle / Clear on
  lock", on by default; also "Clear now"). History exists only in memory.
- Third-party cookies are blocked. File access, JavaScript bridges to the app,
  location, camera, microphone, downloads and file uploads are disabled.
- Screenshots and recent-apps previews stay blocked (FLAG_SECURE).

## Calculator entry and decoy PIN (disclosed features)

- The app can open as a working calculator; entering your PIN followed by `=`
  opens the vault. This is explained during setup, in the calculator's ⓘ
  button and in the store listing. In the launcher the app is labelled
  "Calculator" / "Hesap Makinesi" with a simple calculator icon, and it really
  is a working calculator; the vault behind it is disclosed as above.
- An optional decoy PIN opens a separate, initially empty vault with its own key.

## Second phone (optional Android work profile)

- If you choose **Second phone → Set up**, Android creates a *work profile* on
  your device and GizliAlan becomes the **profile owner of that profile only**
  (the same mechanism as Shelter / Island). Android shows its own notice first.
- Inside it you can add a separate Google account in its Play Store and install
  apps. Those apps, accounts and files are kept apart from your main profile by
  Android; GizliAlan does **not** read their data, messages or notifications.
- (Both flavors) A vault photo you choose as the vault home background stays encrypted in the vault; only its id is stored (also encrypted), and it is decrypted into memory only while the vault is open.
- GizliAlan only uses the profile-owner role to: hide the profile's apps while
  the vault is locked and unhide them when you unlock it ("Hide work apps while
  locked", on by default, can be turned off; it only remembers which of the
  profile's apps it hid, on the device), make an app from your
  main profile available in the profile, open the profile's Play Store, list and
  launch the profile's apps from the vault home, and delete the profile.
- To show the app grid and the "add app" picker, GizliAlan reads the names and
  icons of **launchable apps** on the device (a launcher-intent query, not
  `QUERY_ALL_PACKAGES`). This stays on the device.
- No extra permissions are requested and nothing is uploaded. Remove the
  profile any time in the app or in Android Settings → Accounts → Work.
  "Reset everything" in GizliAlan does not delete the work profile; remove it
  separately.

## Your control / deletion

- Delete individual items inside the app, or use **Settings → Reset everything**.
- "Clear data" in Android settings or uninstalling removes all vault data and
  keys permanently.
- **There is no PIN recovery.** We cannot recover your data because we never
  have it.

## Security limits (honest)

Encryption protects your vault against other apps, casual access and copies of
the app's files. It cannot fully protect against a rooted/compromised device or
someone who knows your PIN. GizliAlan does not hide itself from the launcher (it is
listed as "Calculator") and is not a replacement for Android Private Space.

## Children

Not directed at children under 13.

## Changes

If features that touch data (e.g. optional backup, purchases) are added, this
policy and the Play Data safety form will be updated **before** release.

## Contact

Developer: OfferForge (Demirhan, personal project).
Support e-mail: **delibaltabaris5@gmail.com**
This policy: https://canaslan1675-rgb.github.io/gizli-alan/privacy/

---

## TR — Özet

GizliAlan **cihazda çalışan** kişisel bir kasadır. Eklediğin fotoğraf, dosya ve
notlar **yalnızca cihazında, AES-256-GCM ile şifreli** saklanır. Hesap, sunucu,
analitik, telemetri, reklam veya hata raporlama SDK'sı yoktur; uygulama kasa
içeriğini veya kullanım verisini hiçbir yere göndermez. 0.4.0'dan itibaren
internet izni **yalnızca** isteğe bağlı kasa içi gizli tarayıcı içindir: tek ağ
trafiği, tarayıcıda **senin** açtığın sayfalaradır (Android System WebView;
çerez/önbellek kasa kilitlenince silinir, üçüncü taraf çerezler engelli,
indirme kapalı). PIN yalnızca tuzlanmış PBKDF2 özeti olarak, anahtarlar Android
Keystore destekli güvenli depoda tutulur. İzinler: isteğe bağlı biyometrik
kilit (`USE_BIOMETRIC`) ve yalnızca kasa içi tarayıcı için `INTERNET`. Fotoğraf/dosyaları sistem seçicileriyle sen seçersin.
SMS, arama, rehber, konum, mikrofon, kamera, Erişilebilirlik Hizmeti veya Cihaz
Yöneticisi kullanılmaz; başkalarını izleme aracı değildir. Kasa içi bildirim listesi (içe/dışa aktarma, silme, İkinci telefon
değişiklikleri, hatalı PIN sayısı) de şifreli saklanır ve yalnızca kasa içinde görünür;
sistem bildirimi gönderilmez. Uygulama yedeği
kapalıdır. PIN kurtarma yoktur. Hesap makinesi girişi ve sahte PIN özellikleri
kurulumda, uygulama içinde ve mağaza açıklamasında açıkça belirtilir.

**İletişim / destek:** delibaltabaris5@gmail.com — Politika: https://canaslan1675-rgb.github.io/gizli-alan/privacy/

*This document is provided for transparency and Play policy readiness. It is not legal advice.*
