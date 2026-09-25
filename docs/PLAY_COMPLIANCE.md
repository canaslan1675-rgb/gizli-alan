# Play Store readiness — GizliAlan v0.2 (MVP v1 + calculator launcher + second phone)

Status: **draft, not submitted.** Publishing, Console setup and any purchase
integration are out of scope for this branch (owner decision required).

## 1. Permissions (merged manifest, release)

| Permission | Source | Needed for |
|-----------|--------|-----------|
| `android.permission.USE_BIOMETRIC` | app + `local_auth` | Optional biometric unlock |

Explicitly removed with `tools:node="remove"`: `READ_EXTERNAL_STORAGE`,
`WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`,
`READ_MEDIA_VISUAL_USER_SELECTED`, `MANAGE_EXTERNAL_STORAGE`, `CAMERA`,
`RECORD_AUDIO`, `USE_FINGERPRINT`. No `INTERNET` in release (Flutter adds it to
debug/profile manifests only). **Verify with**
`aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk`
before every upload.

Verified 2026-09-25 on the MVP v1 release APK:
```
uses-permission: android.permission.USE_BIOMETRIC
uses-permission: com.offerforge.gizlialan.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION  (AndroidX-internal, signature-level, not user-visible)
```
No INTERNET, no storage/media/camera/mic permissions.

Re-verified 2026-09-25 on the v0.2 arm64 release APK (`aapt2 dump permissions`):
same list — v0.2 adds **no permissions**.

Not used anywhere: Accessibility Service, Notification Listener, SMS/Call log,
Contacts, Location, `QUERY_ALL_PACKAGES`, `REQUEST_INSTALL_PACKAGES`, overlays,
device-owner / main-profile device-admin policies.

### v0.2 components that need declaring / explaining

| Component | Purpose |
|-----------|---------|
| `secondphone.ProfileAdminReceiver` (`BIND_DEVICE_ADMIN`, `<uses-policies/>` empty) | Profile owner of the work profile the user creates in "Second phone". Never device owner; if activated as a main-profile device admin it deactivates itself. |
| `secondphone.ProvisioningDoneActivity` (`PROVISIONING_SUCCESSFUL`, `BIND_DEVICE_ADMIN`) | Finishes setup inside the new profile. |
| `secondphone.ProfileActionActivity` (disabled except inside the profile) | HMAC-signed requests from the vault: hide/unhide profile apps, add app, open profile Play Store, remove profile. |
| `<queries>` MAIN/LAUNCHER intent | Lists launchable apps for the second-phone grid and the "add app" picker (names + icons only, on device). |
| `uses-feature managed_users / device_admin` (`required=false`) | Feature is optional; app installs everywhere. |
| Launcher label `@string/app_name` = "Calculator" / "Hesap Makinesi", original icon | Discreet name; app is a real calculator; vault disclosed (§3, §4). |

## 2. Data safety form (proposed answers)

| Question | Answer |
|---------|--------|
| Does your app collect or share any of the required user data types? | **No** |
| Is all user data encrypted in transit? | Not applicable (no data transmitted) |
| Do you provide a way for users to request that their data is deleted? | Yes — in-app delete / "Reset everything"; uninstall or Clear data |
| Photos and videos / Files and docs | Processed **on device only**, never transmitted → not "collected" per Play definition |
| Contains ads | **No** |
| Target audience | 18+ (general), not designed for children |

Re-check if any SDK (billing, crash reporting, backup) is added later.

## 3. Store listing drafts

### TR
- **Başlık (≤30):** `GizliAlan: Özel Kasa & Notlar`
- **Kısa açıklama (≤80):** `Fotoğraf, dosya ve notların için şifreli kişisel kasa. Casusluk yok.`
- **Tam açıklama:**
```
GizliAlan, telefonunun sahibine özel, çevrimdışı bir kişisel kasadır.
Fotoğrafların, belgelerin ve notların PIN veya biyometrik ile korunur ve
cihazında AES-256 ile şifrelenir.

ÖZELLİKLER
• Şifreli galeri: fotoğrafları sistem seçicisiyle ekle, ızgarada gör, dışa aktar veya sil
• Şifreli notlar (arama ile) ve belgeler (PDF vb.)
• Kasa içinde "sanal telefon" ana ekranı ve duvar kağıdı
• PIN + isteğe bağlı parmak izi/yüz ile kilit, arka planda otomatik kilit
• Ekran görüntüsü ve son uygulamalar önizlemesi engeli (FLAG_SECURE)
• Hesap makinesi görünümü: telefonunda "Hesap Makinesi" adı ve hesap makinesi
  simgesiyle görünür ve gerçekten çalışan bir hesap makinesidir. Kasa PIN'ini
  yazıp "=" tuşuna basınca GizliAlan kasası açılır (ⓘ düğmesinde de yazar).
  İstersen Ayarlar'dan doğrudan PIN ekranıyla açılmasını seçebilirsin.
• İsteğe bağlı sahte PIN: ayrı, boş bir kasa açar
• İsteğe bağlı "İkinci telefon": Android'in iş profili özelliğiyle ayrı bir alan
  kurar (Shelter/Island yöntemi). Kendi Play Store'una ikinci bir Google hesabı
  ekleyip uygulama kurabilirsin; uygulamalar, hesaplar ve dosyalar ana
  telefondan ayrı kalır. Kasayı kilitleyince ikinci telefonun uygulamalarını
  gizleyebilir, kasadan bu uygulamaları başlatabilirsin. GizliAlan yalnızca bu
  iş profilinin profil sahibidir; telefonunun yöneticisi olmaz. Bazı cihazlarda
  (ör. Xiaomi MIUI/HyperOS) iş profili desteklenmeyebilir.

GİZLİLİK
• Hesap yok, sunucu yok, reklam yok, analitik yok; internet izni yok
• Tek izin: isteğe bağlı biyometrik kilit
• PIN kurtarma yoktur — PIN'ini unutma

NE DEĞİLDİR
• Başkasını izleme, takip etme veya dinleme aracı değildir
• SMS, arama, konum, rehber okumaz; Erişilebilirlik Hizmeti kullanmaz, telefonun
  cihaz yöneticisi olmaz; ikinci telefondaki uygulamaların verisini okumaz
• Yalnızca kendi cihazında, kendi içeriğin için kullan
```

### EN
- **Title (≤30):** `GizliAlan: Private Vault`
- **Short (≤80):** `Encrypted personal vault for your photos, files and notes. No spyware.`
- **Full:**
```
GizliAlan is an offline personal vault for the owner of the phone. Your photos,
documents and notes are protected by a PIN or biometrics and encrypted on your
device with AES-256.

FEATURES
• Encrypted gallery: add photos via the system picker, grid view, export or delete
• Encrypted notes (with search) and documents (PDF etc.)
• "Virtual phone" home screen inside the vault, with wallpapers
• PIN + optional fingerprint/face unlock, auto-lock in background
• Screenshots and recent-apps previews blocked (FLAG_SECURE)
• Calculator look: on your phone the app is named "Calculator" with a calculator
  icon, and it is a fully working calculator. Type your vault PIN and press "="
  to open the GizliAlan vault (also explained behind the ⓘ button). You can
  switch to opening straight at the PIN screen in Settings.
• Optional decoy PIN: opens a separate, empty vault
• Optional "Second phone": creates a separate space with Android's work profile
  feature (the Shelter/Island method). Add a second Google account in its own
  Play Store and install apps; apps, accounts and files stay separate from your
  main phone. Hide the second phone's apps when you lock the vault, and launch
  them from inside the vault. GizliAlan is only the profile owner of that work
  profile — never an admin of your phone. Some devices (e.g. Xiaomi
  MIUI/HyperOS) may not support work profiles.

PRIVACY
• No account, no server, no ads, no analytics, no internet permission
• Only permission: optional biometric unlock
• There is no PIN recovery — don't forget your PIN

WHAT IT IS NOT
• Not a tool to monitor, track or listen to anyone
• Does not read SMS, calls, location or contacts; no Accessibility Service, never a
  device admin of your phone; does not read data of apps in the second phone
• Use it only on your own device, for your own content
```

## 4. App access / reviewer instructions (App content → App access)

```
The app is fully functional without an account.
1. First launch: confirm "own device", choose calculator entry (on by default), set PIN, e.g. 2580.
2. Calculator entry: the app opens as a working calculator. Type 2580 then "=" to open the vault.
   The ⓘ button in the calculator explains this. Turn it off in Vault → Settings → Entry.
3. Optional decoy PIN: Vault → Settings → Decoy PIN (e.g. 1111) opens a separate empty vault.
4. Biometrics: Vault → Settings → Biometric unlock; then long-press "=" (calculator) or use the
   fingerprint button on the PIN screen.
5. Launcher: the app is labelled "Calculator" (EN) / "Hesap Makinesi" (TR) with an original
   calculator icon. It is a working calculator; the vault entry is disclosed in onboarding step 2,
   in the ⓘ dialog and in this listing.
6. Second phone (optional, needs a device that supports work profiles, e.g. Pixel emulator):
   Vault → "Second phone" → "Set up second phone" → Android's own work-profile setup runs.
   The app becomes profile owner of that work profile ONLY (DeviceAdminReceiver with no
   policies). Afterwards: Open Play Store (add a second account), Add an app from the main
   phone, launch profile apps from the vault home grid, Lock → profile apps are hidden,
   unlock → shown again (Settings → "Second phone on lock"), Remove second phone.
No Accessibility, no device-owner or main-profile admin, no network, no tracking of other people,
no reading of other apps' data. Reviewers see exactly the same behaviour as users (no remote
config, no geo/reviewer detection).
```

## 5. Policy checklist

- [x] Listing and in-app behaviour tell the same story (vault; calculator entry disclosed)
- [x] Launcher name "Calculator"/"Hesap Makinesi" + original icon; app is a real calculator, vault disclosed; no icon hiding, no alias switching, no copied vendor branding
- [x] Device admin used only as profile owner of a user-created work profile (empty policies, self-removes as main-profile admin); disclosed in app, listing, reviewer notes
- [x] No stalkerware/monitoring features or wording ("spy", "track", "hide from partner")
- [x] Minimal permissions; no broad storage
- [x] Privacy policy (PRIVACY.md) — **host on HTTPS before submission**
- [x] Data safety answers drafted
- [x] Onboarding: "own device only" confirmation
- [ ] Real support e-mail + hosted policy URL
- [x] Screenshots: `docs/store/screenshots/{tr,en}/01_calculator_info.png … 06_settings.png` (1080×1920 RGB PNG; calculator with ⓘ dialog, onboarding step 2, vault home, gallery grid, notes, settings). Widget-rendered with demo content by `tool/gen_store_screenshots.sh`; no Second phone frame until #11 is decided
- [x] Release signing config (`android/key.properties`, README "Release signing") — [ ] owner still has to create the upload keystore (#13); until then release builds use debug keys
- [ ] Subscriptions/IAP: not in this build (see DECISIONS.md). Settings → "GizliAlan Pro" is a **UI stub only** (planned prices, buttons say "not available in this test build"; no billing library, no network). Real Play Billing = owner decision (#15).

## 6. Play policy risk — v0.2 (calculator label + work-profile DPC)

**Risk: medium–high review friction.** Not a policy violation by design, but:

1. **Device Admin / managed profile.** Apps containing a `DeviceAdminReceiver`
   get closer review; Play's Device & Network Abuse, Unwanted Software and the
   Permissions/APIs-that-access-sensitive-information policies expect a clear,
   user-facing reason. Consumer DPCs (Shelter, Island/Insular) mostly live on
   F-Droid / GitHub, partly because of this. Island has been on Play before, so
   it is possible, not guaranteed.
2. **Calculator appearance.** A vault named "Calculator" is allowed when
   disclosed (Deceptive Behavior → Behavior Transparency), but the combination
   "calculator label + admin component" can look like concealment to an
   automated or human reviewer.

**Mitigations in the app:** real calculator; vault disclosed in onboarding,
ⓘ, listing, reviewer notes; empty admin policies; self-deactivation as a
main-profile admin; second phone gated behind the vault and fully described;
no new permissions; no reading of other apps' data; no network.

**If Play objects (fallback):**
- Build a Play flavor without the `secondphone` components (vault + calculator
  only) and distribute the second-phone build as a signed APK (GitHub releases
  / F-Droid-style), like Shelter. Owner decision — see BLOCKERS.md.
- Optionally make the Play listing title more explicit, e.g.
  "GizliAlan: Calculator Vault".
- Store icon: use `docs/store_icon_512.png` (same original icon as the launcher)
  and make the first screenshot show the calculator with the ⓘ dialog open.
