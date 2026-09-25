# GizliAlan

Personal, offline **"hidden virtual phone" vault** for the device owner:
encrypted photos, files and notes behind a PIN / biometrics, with an optional
(disclosed) calculator entry and an optional decoy PIN.

**Package:** `com.offerforge.gizlialan` · **Flutter** 3.47 (stable) · **Android** 9+ (minSdk 28)
**No spyware. No cloud. No SMS/calls. No Accessibility. No main-device admin. No INTERNET in release.**

Launcher name: **Hesap Makinesi** (TR) / **Calculator** (EN), original calculator icon (v0.2).

---

## 🇹🇷 Türkçe

### Özellikler (MVP v1)
- **Şifreli kasa:** tüm içerik AES-256-GCM ile şifreli; anahtar Android Keystore destekli `flutter_secure_storage`'da
- **Hesap makinesi girişi (isteğe bağlı, açıkça belirtilir):** gerçek hesap makinesi; PIN + `=` kasayı açar, `=` uzun basış biyometrik
- **PIN + biyometrik** (`local_auth`), yanlış denemede artan bekleme süresi, arka planda otomatik kilit
- **FLAG_SECURE:** ekran görüntüsü / kayıt / son uygulamalar önizlemesi engelli
- **Galeri kasası:** sistem Photo Picker ile içe aktarma, şifreli kopya, ızgara, görüntüleyici, dışa aktarma (SAF), silme
- **Dosyalar** (PDF vb.) ve **Notlar** (arama ile), hepsi şifreli
- **Sanal telefon ana ekranı:** saat, ikon ızgarası, dock, duvar kağıdı seçimi
- **Bildirimler (yalnızca kasa içinde):** içe/dışa aktarma, silme, İkinci telefon değişiklikleri ve son girişten beri hatalı PIN sayısı; şifreli, kasa başına ayrı; sistem bildirimi yok (izin de yok)
- **GizliAlan Pro ekranı (yalnızca arayüz):** Ayarlar → planlar ve planlanan fiyatlar (Ücretsiz 50 öğe, Pro 249 TL tek seferlik / 449 TL yıllık); satın alma yok, ödeme kodu yok
- **Sahte PIN (isteğe bağlı):** ayrı anahtarla ayrı, boş bir kasa
- **TR / EN** arayüz
- **v0.2 — Nötr başlatıcı adı/simgesi:** uygulama listesinde "Hesap Makinesi" / "Calculator" adı ve özgün hesap makinesi simgesi (adaptive + monochrome). Kasa; onboarding, ⓘ ve mağaza metninde açıkça belirtilir.
- **v0.2 — İkinci telefon (iş profili):** Android iş profili (Shelter/Island yöntemi) kurulur; kendi Play Store'u ve ayrı Google hesabıyla izole uygulamalar. Kasa içinden: kur, durum, kilitleyince uygulamaları gizle / profili kapat (seçenek), ana telefondan uygulama ekle, Play Store'u aç, uygulamaları listele/başlat, profili kaldır. Xiaomi MIUI/HyperOS'ta engellenebilir → İkinci alan / Özel alan önerisi.

### Ne yapmaz
SMS/arama okuma, konum, rehber, mikrofon/kamera, Erişilebilirlik Hizmeti,
ana cihaz yöneticisi, bildirim dinleyici, sunucuya yükleme, ikon gizleme — **yok**.
(İkinci telefon: yalnızca kullanıcının kendi oluşturduğu iş profilinin profil sahibi.)

---

## 🇬🇧 English

### Build & run

```bash
# Flutter SDK (this box: /workspace/tools/flutter, stable channel)
export PATH=/workspace/tools/flutter/bin:$PATH
flutter pub get
flutter analyze
flutter test
flutter run                 # device/emulator
flutter build apk --release # needs Android SDK + JDK 17
```

On this box the Android toolchain lives in `/workspace/tools/android-sdk` and
`/workspace/tools/jdk17` (see `flutter config`). The `android/` project is
committed; `bootstrap.sh` only re-creates it if missing.

### Architecture

```
lib/
  main.dart, app.dart          root, session ownership, auto-lock, navigation
  theme.dart                   dark mint theme + wallpapers
  l10n/                        tr.dart, en.dart, l10n.dart (L10nScope rebuilds on language change)
  models/note.dart
  services/
    crypto_service.dart        AES-256-GCM seal/open, PBKDF2-HMAC-SHA256
    secure_kv.dart             secure storage abstraction (Keystore / in-memory for tests)
    auth_service.dart          PIN, decoy PIN, lockout, per-space data keys
    biometric_service.dart     local_auth wrapper
    vault_space.dart           real | decoy
    vault_session.dart         unlocked space: encrypted files + repositories
    vault_storage.dart         encrypted collections (gallery, files) + encrypted index
    notes_repository.dart      encrypted notes document
    vault_events.dart          encrypted vault-only notification list (events.gae)
    calculator_engine.dart     pure calculator logic + PIN candidate
    legacy_migration.dart      scaffold plaintext → encrypted vault
    settings_service.dart      non-secret prefs
    second_phone_service.dart  work-profile "second phone" channel client + availability logic
  screens/                     decoy_calculator, pin_lock, onboarding, vault_home,
                               gallery, photo_viewer, files, notes_list, note_edit,
                               settings, set_pin, second_phone
  widgets/vault_actions.dart   export/delete helpers, progress dialog
android/app/src/main/kotlin/…/secondphone/
                               ProfileAdminReceiver (profile owner only), ProfileSetup,
                               ProvisioningDoneActivity, ProfileActionActivity (signed
                               in-profile trampoline), SecondPhoneChannel (main profile)
tool/gen_launcher_icon.py      generates the original launcher icon (vector + PNGs)
test/                          crypto, auth, calculator, storage, second-phone, branding
                               unit tests + app-flow / second-phone widget tests
docs/PLAY_COMPLIANCE.md        permissions, Data safety answers, listing TR/EN, reviewer notes
```

**On-disk layout** (app-private support dir):
`spaces/<real|decoy>/notes.gae`, `…/events.gae`, `…/gallery/index.gae`, `…/gallery/<uuid>.gae`,
`…/files/…`. Sealed format: `"GAE1"` ‖ nonce(12) ‖ ciphertext ‖ tag(16).

### Security model (honest)
- Data keys are random 256-bit per space, stored in Keystore-backed secure
  storage (not PIN-wrapped, so biometrics can unlock). Protects against other
  apps, casual access and file copies; not against a rooted device with the
  phone unlocked, or someone who knows the PIN.
- The app stays visible in the launcher, labelled "Calculator" / "Hesap
  Makinesi" (a real calculator; vault disclosed). It is not Android Private Space.
- Second phone isolation is Android's work profile; GizliAlan is its profile
  owner only. Work-profile apps show a briefcase badge and appear in the
  launcher's Work tab — it is separation, not invisibility.
- No PIN recovery.

See `PRIVACY.md`, `docs/PLAY_COMPLIANCE.md`, `DECISIONS.md`.

## License
Private / personal project. Not for use as monitoring or spyware tooling.
