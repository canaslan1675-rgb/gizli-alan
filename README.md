# GizliAlan

Personal, offline **"hidden virtual phone" vault** for the device owner:
encrypted photos, files and notes behind a PIN / biometrics, with an optional
(disclosed) calculator entry and an optional decoy PIN.

**Package:** `com.offerforge.gizlialan` · **Flutter** 3.47 (stable) · **Android** 9+ (minSdk 28)
**No spyware. No cloud. No SMS/calls. No Accessibility. No Device Admin. No INTERNET in release.**

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
- **Sahte PIN (isteğe bağlı):** ayrı anahtarla ayrı, boş bir kasa
- **TR / EN** arayüz

### Ne yapmaz
SMS/arama okuma, konum, rehber, mikrofon/kamera, Erişilebilirlik Hizmeti,
Cihaz Yöneticisi, bildirim dinleyici, sunucuya yükleme, ikon gizleme — **yok**.

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
    calculator_engine.dart     pure calculator logic + PIN candidate
    legacy_migration.dart      scaffold plaintext → encrypted vault
    settings_service.dart      non-secret prefs
  screens/                     decoy_calculator, pin_lock, onboarding, vault_home,
                               gallery, photo_viewer, files, notes_list, note_edit,
                               settings, set_pin
  widgets/vault_actions.dart   export/delete helpers, progress dialog
test/                          crypto, auth, calculator, storage unit tests + app flow widget test
docs/PLAY_COMPLIANCE.md        permissions, Data safety answers, listing TR/EN, reviewer notes
```

**On-disk layout** (app-private support dir):
`spaces/<real|decoy>/notes.gae`, `…/gallery/index.gae`, `…/gallery/<uuid>.gae`,
`…/files/…`. Sealed format: `"GAE1"` ‖ nonce(12) ‖ ciphertext ‖ tag(16).

### Security model (honest)
- Data keys are random 256-bit per space, stored in Keystore-backed secure
  storage (not PIN-wrapped, so biometrics can unlock). Protects against other
  apps, casual access and file copies; not against a rooted device with the
  phone unlocked, or someone who knows the PIN.
- The app stays visible in the launcher as "GizliAlan". It is not Android
  Private Space.
- No PIN recovery.

See `PRIVACY.md`, `docs/PLAY_COMPLIANCE.md`, `DECISIONS.md`.

## License
Private / personal project. Not for use as monitoring or spyware tooling.
