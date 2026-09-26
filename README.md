# GizliAlan

Personal, on-device **"hidden virtual phone" vault** for the device owner:
encrypted photos, files and notes behind a PIN / biometrics, with an optional
(disclosed) calculator entry and an optional decoy PIN.

**Package:** `com.offerforge.gizlialan` · **Flutter** 3.47 (stable) · **Android** 9+ (minSdk 28)
**No spyware. No cloud. No SMS/calls. No Accessibility. No main-device admin. No tracking, no ads, no analytics; INTERNET only for the in-vault private browser.**

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
- **GizliAlan Pro ekranı (yalnızca arayüz):** Ayarlar → planlar ve planlanan fiyatlar (Ücretsiz 7 gün · 50 öğe, Pro 149 TL / yıl veya 399 TL tek seferlik — en avantajlı); satın alma yok, ödeme kodu yok
- **v0.3.2 — Ana ekran arka planı:** Galeri → fotoğrafa uzun bas → "Ana ekran arka planı yap" (menüde ayrıca Aç / Dışa aktar / Sil). Yalnızca kasa ana ekranında, okunabilirlik için karartma katmanıyla; fotoğraf kasada şifreli kalır, yalnızca bellekte çözülür. Ayarlar → "Ana ekran arka planı" durumu gösterir ve "Arka planı kaldır" sunar. Varsayılan: düz renk geçişi (paketli görsel yok; `assets/wallpapers/` ileride varsayılan görsel için ayrılmış). Her kasanın (gerçek/sahte) kendi arka planı.
- **v0.4.0 — Gizli tarayıcı (Tarayıcı):** kasa ana ekranında, Android System WebView (`webview_flutter`). Adres/arama çubuğu (varsayılan DuckDuckGo; Ayarlar'dan Startpage/Brave/Google/Bing; öneri API'si yok), geri/ileri/yenile, tek sekme. Çerez/önbellek/site verisi uygulamaya özel depoda, **kasa kilitlenince silinir** (Ayarlar → "Kilitlenince temizle", varsayılan açık; "Şimdi temizle"). Geçmiş yalnızca bellekte. Üçüncü taraf çerezler engelli; dosya/içerik erişimi, JS köprüsü, konum/kamera/mikrofon izni, indirme ve dosya yükleme **kapalı**. FLAG_SECURE tarayıcıyı da kapsar. Uygulama hiçbir yere veri göndermez; tek trafik açtığın sayfalaradır. Bkz. `docs/PRIVATE_BROWSER.md`.
- **v0.4.0 — Varsayılan arka plan görseli:** `assets/wallpapers/default.jpg` (sahibi tarafından Grok/xAI ile üretildi; Ayarlar'ın altında "Varsayılan arka plan: Created with Grok"). Kasa fotoğrafı seçilirse onun yerine o gösterilir; "Arka planı kaldır" bu görsele döner; Ayarlar → Duvar kağıdı'nda ilk yuvarlak = görsel, diğerleri = düz renk. Açık renkli görsel için üst/alt koyu geçiş, koyu yarı saydam kutucuk/dock ve metin gölgesi.
- **v0.4.0 — Ana ekran imzası:** kasa ana ekranında, dock'un üstünde düşük opaklıkta, tek aralıklı (terminal tarzı) 3 satır: `GizliAlan Vault · v0.4.0 (build 6) · play|full` / `AES-256-GCM · PIN: PBKDF2-SHA256 120k · FLAG_SECURE` / `● vault: unlocked · © OfferForge`. Sürüm/derleme çalışma anında APK'dan (PackageManager), çeşit derleme anında, şifre/KDF değerleri `CryptoService` sabitlerinden gelir; dokunulamaz, erişilebilirlikte gizli; hesap makinesinde asla yok.
- **Sahte PIN (isteğe bağlı):** ayrı anahtarla ayrı, boş bir kasa
- **TR / EN** arayüz
- **v0.2 — Nötr başlatıcı adı/simgesi:** uygulama listesinde "Hesap Makinesi" / "Calculator" adı ve özgün hesap makinesi simgesi (adaptive + monochrome). Kasa; onboarding, ⓘ ve mağaza metninde açıkça belirtilir.
- **v0.2 — İkinci telefon (iş profili):** Android iş profili (Shelter/Island yöntemi) kurulur; kendi Play Store'u ve ayrı Google hesabıyla izole uygulamalar. Kasa içinden: kur, durum, **kilitliyken iş uygulamalarını gizle** (varsayılan açık; #30 — ana ekrandaki "İş" klasöründen de kalkar, gerçek PIN/parmak iziyle açınca geri gelir, bkz. `docs/SECOND_PHONE_HIDING.md`), isteğe bağlı iş profilini duraklatmayı dene, ana telefondan uygulama ekle, Play Store'u aç, uygulamaları listele/başlat, profili kaldır. Xiaomi MIUI/HyperOS'ta engellenebilir → İkinci alan / Özel alan önerisi.

### Ne yapmaz
SMS/arama okuma, konum, rehber, mikrofon/kamera, Erişilebilirlik Hizmeti,
ana cihaz yöneticisi, bildirim dinleyici, sunucuya yükleme, analitik/telemetri/reklam, kendi simgesini gizleme — **yok**.
(INTERNET izni yalnızca kasa içi tarayıcı içindir; uygulamanın kendi sunucusu yoktur.)
(İkinci telefon: yalnızca kullanıcının kendi oluşturduğu iş profilinin profil sahibi; kilitliyken
yalnızca **o profilin içindeki** uygulamaları gizler, ana profildeki hiçbir uygulamaya dokunmaz.)

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
# release builds need a flavor (Android SDK + JDK 17):
flutter build apk --release --flavor play --target-platform android-arm64
flutter build apk --release --flavor full --target-platform android-arm64
```

### Build flavors / Yapı çeşitleri (#11)

| Flavor | applicationId | Second phone | APK output |
|--------|---------------|--------------|-----------|
| `play` | `com.offerforge.gizlialan` | **no** — no device-admin receiver / work-profile code in the APK, UI hidden | `build/app/outputs/flutter-apk/app-play-release.apk` |
| `full` | `com.offerforge.gizlialan.full` | yes (side-load / test) | `build/app/outputs/flutter-apk/app-full-release.apk` |

Both keep the launcher label "Calculator"/"Hesap Makinesi", FLAG_SECURE and only the
`USE_BIOMETRIC` + `INTERNET` (in-vault browser only, since 0.4.0) permissions, and install side by side. Android: `productFlavors` in
`android/app/build.gradle.kts`; the Second phone manifest entries, Kotlin code, strings and
`profile_admin.xml` live only in `android/app/src/full/`. Dart: `lib/flavor.dart` reads
Flutter's `appFlavor` (set by `--flavor`), then `--dart-define=FLAVOR=play|full`; unknown or
missing → `play` (safe default). Settings → footer shows "GizliAlan 0.4.0 · Play/Full".
On Android always pass a flavor, e.g.
`flutter run --flavor full` (or `play`).

Build-time options (#28):
- `--dart-define=PRIVACY_URL=https://…` — Settings → Privacy & permissions then also shows the
  hosted privacy policy with "Open in browser" (plain `ACTION_VIEW` intent via the
  `gizlialan/system` channel, no url_launcher dependency) and "Copy link".
  Without it (or with a non-https value) only the built-in privacy text is shown.
- The "GizliAlan Pro" UI stub is shown only in `full`; `--dart-define=PRO_STUB=true` shows it in
  `play` too (review only). No billing either way; the 50-item free limit is displayed, not enforced.
- Store feature graphic: `python3 tool/gen_feature_graphic.py` (Pillow) →
  `docs/store/feature_graphic/feature_graphic_{tr,en}.png` (1024×500 RGB).
- Play upload example: `flutter build appbundle --release --flavor play --dart-define=PRIVACY_URL=https://canaslan1675-rgb.github.io/gizli-alan/privacy/`.

TR: `play` = Google Play adayı, İkinci telefon yok (APK'da cihaz yöneticisi bileşeni bile yok);
`full` = İkinci telefonlu test/yan yükleme sürümü. İkisi aynı telefona birlikte kurulabilir.
Play'e hangisinin gönderileceği sahibin kararı (#11).

On this box the Android toolchain lives in `/workspace/tools/android-sdk` and
`/workspace/tools/jdk17` (see `flutter config`). The `android/` project is
committed; `bootstrap.sh` only re-creates it if missing.

### Store screenshots / Mağaza ekran görüntüleri

`tool/gen_store_screenshots.sh` regenerates `docs/store/screenshots/{play,full}/{tr,en}/01…06_*.png`
(1080×1920, RGB, no alpha; 24 files). **The Play listing uses `play/`** (no Second phone
anywhere); `full/` is the side-load build (vault home shows the Second phone tile). It runs `test/store_screenshots_test.dart` with
`--dart-define=STORE_SCREENSHOTS=true`: the real screens are pumped in a widget test with
fabricated demo content (generated pattern images, neutral fake notes) and captured through a
`RepaintBoundary`. No emulator is needed and FLAG_SECURE is not touched. Plain `flutter test`
skips the generator. Font fixtures: `test/fixtures/fonts/README.md`.

TR: Mağaza görüntüleri gerçek ekranların sahte demo içerikle widget testinde çizilmesiyle
üretilir (emülatör yok, FLAG_SECURE değişmez); yeniden üretmek için betiği çalıştır.

### Device testing / Cihaz testi

Step-by-step checklist for real phones (Xiaomi / Samsung / Pixel) and emulators, with a
results table: [`docs/DEVICE_TEST_PLAN.md`](docs/DEVICE_TEST_PLAN.md) (#7, owner run #14).

### Release signing / Release imzalama (owner only / yalnızca sahibi)

Release builds are signed with the **upload key** from `android/key.properties`.
If that file is missing, the build prints a warning and signs with the **debug
key** — fine for test APKs (GitHub pre-releases), **not** for Google Play.

1. On your own machine, create the upload keystore **outside the repo** and back
   it up somewhere safe (password manager + offline copy). Losing it means you
   can't update the app without Play support.
   ```bash
   keytool -genkeypair -v -keystore ~/keys/gizlialan-upload.jks \
     -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
2. `cp android/key.properties.example android/key.properties` and fill in
   `storeFile` (absolute path, or relative to `android/`), `storePassword`,
   `keyAlias`, `keyPassword`. Missing values fail the build with a clear message.
3. `flutter build appbundle --release --flavor play` (Play) or `flutter build apk --release --flavor play|full`.
   The same `key.properties` signs both flavors.
   Check the signer: `apksigner verify --print-certs build/app/outputs/flutter-apk/app-play-release.apk`
   (must **not** say `CN=Android Debug`).
4. Recommended: enable **Play App Signing** when creating the app in Play Console
   (Google keeps the app signing key, your keystore is only the upload key).

`android/key.properties`, `*.jks` and `*.keystore` are git-ignored. **Never**
commit them or paste passwords/paths into issues, PRs, logs or chat. Agents never
create or handle the real keystore (issue #13).

TR: Yayın derlemesi `android/key.properties` içindeki yükleme anahtarıyla imzalanır;
dosya yoksa uyarı verilir ve debug anahtarı kullanılır (yalnızca test APK'ları için,
Play için değil). Anahtar deposunu repo dışında oluştur ve yedekle, şablonu kopyalayıp
doldur, imzayı `apksigner` ile doğrula. Anahtar/parola asla repoya, issue'ya veya
sohbete konmaz.

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
    second_phone_service.dart  work-profile "second phone" channel client + availability logic (full flavor)
  flavor.dart                  AppFlavor play|full (#11), Flavor.hasSecondPhone
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
  launcher's Work tab / "İş" folder while unlocked. **Since v0.3.2 (#30, full
  flavor):** while the vault is locked GizliAlan hides the profile's launchable
  apps from inside the profile (`setApplicationHidden`) and unhides exactly
  those on a real unlock — see `docs/SECOND_PHONE_HIDING.md` for what is kept,
  timing (background auto-lock hides on next open) and limitations (hidden apps
  get no notifications). The main profile's apps are never touched.
- No PIN recovery.

See `PRIVACY.md`, `docs/PLAY_COMPLIANCE.md`, `DECISIONS.md`.

## License
Private / personal project. Not for use as monitoring or spyware tooling.
