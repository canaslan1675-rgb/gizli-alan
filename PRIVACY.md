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
| Failed-attempt counter | `flutter_secure_storage` | — | Brute-force throttling |
| Preferences (language, auto-lock, calculator entry, biometrics on/off, wallpaper) | SharedPreferences (app-private) | Not secret | App settings |

Biometric unlock uses Android's BiometricPrompt. The app **never receives or
stores** fingerprint/face data; Android only tells it "success" or "failure".

## What the app does NOT do

- No collection, sale or sharing of personal data. Nothing is uploaded.
- No SMS, call log, contacts, location, microphone or camera access.
- No Accessibility Service, Device Admin, Notification Listener or overlays.
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
developer tooling; release builds do not.

## Calculator entry and decoy PIN (disclosed features)

- The app can open as a working calculator; entering your PIN followed by `=`
  opens the vault. This is explained during setup, in the calculator's ⓘ
  button and in the store listing. The launcher name/icon remain "GizliAlan".
- An optional decoy PIN opens a separate, initially empty vault with its own key.

## Your control / deletion

- Delete individual items inside the app, or use **Settings → Reset everything**.
- "Clear data" in Android settings or uninstalling removes all vault data and
  keys permanently.
- **There is no PIN recovery.** We cannot recover your data because we never
  have it.

## Security limits (honest)

Encryption protects your vault against other apps, casual access and copies of
the app's files. It cannot fully protect against a rooted/compromised device or
someone who knows your PIN. GizliAlan does not hide itself from the launcher and
is not a replacement for Android Private Space.

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
Yöneticisi kullanılmaz; başkalarını izleme aracı değildir. Uygulama yedeği
kapalıdır. PIN kurtarma yoktur. Hesap makinesi girişi ve sahte PIN özellikleri
kurulumda, uygulama içinde ve mağaza açıklamasında açıkça belirtilir.

*This document is provided for transparency and Play policy readiness. It is not legal advice.*
