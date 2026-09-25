# Play Store readiness — GizliAlan MVP v1

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

Not used anywhere: Accessibility Service, Device Admin, Notification Listener,
SMS/Call log, Contacts, Location, `QUERY_ALL_PACKAGES`, overlays.

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
• İsteğe bağlı hesap makinesi girişi: uygulama gerçek bir hesap makinesi olarak
  açılır; PIN'ini yazıp "=" tuşuna basınca kasa açılır. Uygulama adı ve simgesi
  "GizliAlan" olarak kalır.
• İsteğe bağlı sahte PIN: ayrı, boş bir kasa açar

GİZLİLİK
• Hesap yok, sunucu yok, reklam yok, analitik yok; internet izni yok
• Tek izin: isteğe bağlı biyometrik kilit
• PIN kurtarma yoktur — PIN'ini unutma

NE DEĞİLDİR
• Başkasını izleme, takip etme veya dinleme aracı değildir
• SMS, arama, konum, rehber okumaz; Erişilebilirlik Hizmeti veya Cihaz Yöneticisi kullanmaz
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
• Optional calculator entry: the app opens as a real calculator; type your PIN
  and press "=" to open the vault. The app name and icon stay "GizliAlan".
• Optional decoy PIN: opens a separate, empty vault

PRIVACY
• No account, no server, no ads, no analytics, no internet permission
• Only permission: optional biometric unlock
• There is no PIN recovery — don't forget your PIN

WHAT IT IS NOT
• Not a tool to monitor, track or listen to anyone
• Does not read SMS, calls, location or contacts; no Accessibility Service or Device Admin
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
No Accessibility, no Device Admin, no network, no tracking of other people.
Reviewers see exactly the same behaviour as users (no remote config, no geo/reviewer detection).
```

## 5. Policy checklist

- [x] Listing and in-app behaviour tell the same story (vault; calculator entry disclosed)
- [x] Launcher name/icon honest ("GizliAlan"); no icon hiding or impersonation
- [x] No stalkerware/monitoring features or wording ("spy", "track", "hide from partner")
- [x] Minimal permissions; no broad storage
- [x] Privacy policy (PRIVACY.md) — **host on HTTPS before submission**
- [x] Data safety answers drafted
- [x] Onboarding: "own device only" confirmation
- [ ] Real support e-mail + hosted policy URL
- [ ] Screenshots (plan: calculator with ⓘ dialog, onboarding step 2, vault home, gallery grid, notes, settings)
- [ ] Release signing config (currently debug keys)
- [ ] Subscriptions/IAP: not in this build (see DECISIONS.md)
