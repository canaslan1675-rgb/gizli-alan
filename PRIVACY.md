# Privacy Policy — GizliAlan

**Last updated:** 2026-09-25
**App:** GizliAlan (package `com.offerforge.gizlialan`)
**Audience:** The owner of the device, for their own content only.

> TR özet aşağıda. / Turkish summary below.

## Summary

GizliAlan is an **offline** personal vault. Photos, files and notes you add are
**encrypted and stored only on your device**. There is no account, no server,
no analytics, no advertising and no crash-reporting SDK. The release build does
not even request the Internet permission, so the app cannot send your data
anywhere.

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

- No collection, sale or sharing of personal data. Nothing is uploaded.
- No SMS, call log, contacts, location, microphone or camera access.
- No Accessibility Service, Notification Listener or overlays. GizliAlan is
  never a device administrator of your phone or main profile (see "Second
  phone" below for the optional work profile).
- No monitoring of other apps or other people. GizliAlan is not a tracking or
  "spy" tool and must not be installed on someone else's device.
- No advertising ID, no analytics, no third-party SDKs that collect data.
- No cloud backup: Android auto-backup and device-transfer are disabled for
  this app.

## Permissions

| Permission | Why |
|-----------|-----|
| `USE_BIOMETRIC` | Optional fingerprint/face unlock of your vault |

Photos and files are imported only when **you** pick them in the system Photo
Picker / file picker (no storage or media permission). Export uses the system
"save as" dialog. Debug builds additionally contain `INTERNET` for Flutter
developer tooling; release builds do not. If a build shows a link to this
policy (Settings → Privacy & permissions) and you tap "Open in browser", your
browser app opens the page — GizliAlan itself sends nothing.

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

Developer: Demirhan (personal project). Replace with a real support e-mail and
host this page on HTTPS before publishing on Google Play.

---

## TR — Özet

GizliAlan **çevrimdışı** kişisel bir kasadır. Eklediğin fotoğraf, dosya ve
notlar **yalnızca cihazında, AES-256-GCM ile şifreli** saklanır. Hesap, sunucu,
analitik, reklam veya hata raporlama SDK'sı yoktur; yayın sürümü internet izni
bile istemez. PIN yalnızca tuzlanmış PBKDF2 özeti olarak, anahtarlar Android
Keystore destekli güvenli depoda tutulur. Tek izin: isteğe bağlı biyometrik
kilit (`USE_BIOMETRIC`). Fotoğraf/dosyaları sistem seçicileriyle sen seçersin.
SMS, arama, rehber, konum, mikrofon, kamera, Erişilebilirlik Hizmeti veya Cihaz
Yöneticisi kullanılmaz; başkalarını izleme aracı değildir. Kasa içi bildirim listesi (içe/dışa aktarma, silme, İkinci telefon
değişiklikleri, hatalı PIN sayısı) de şifreli saklanır ve yalnızca kasa içinde görünür;
sistem bildirimi gönderilmez. Uygulama yedeği
kapalıdır. PIN kurtarma yoktur. Hesap makinesi girişi ve sahte PIN özellikleri
kurulumda, uygulama içinde ve mağaza açıklamasında açıkça belirtilir.

*This document is provided for transparency and Play policy readiness. It is not legal advice.*
