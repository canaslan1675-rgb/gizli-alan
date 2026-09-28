# Privacy Policy — GizliAlan

**Last updated:** 2026-09-27 (v0.4.6)
**Data controller:** Demirhan Çelik (OfferForge), Türkiye — delibaltabaris5@gmail.com
**App:** GizliAlan (package `com.offerforge.gizlialan`)
**Audience:** The owner of the device, for their own content only.

> Türkçe tam metin aşağıdadır (KVKK aydınlatma metni). / Full Turkish version below.

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
removed from the manifest. The app links to this policy (setup
screen and Settings → Privacy & permissions); if you tap "Open in browser",
your own browser app opens the page — GizliAlan itself sends nothing.

## Private browser (since 0.4.0)

The vault home screen has an optional **Browser** ("Tarayıcı"). It uses
Android System WebView. GizliAlan adds no tracking to it and sends nothing to
the developer. What happens when you use it:

- Only the pages **you** type or open are loaded. Searches go to the search
  engine you choose (default DuckDuckGo; Startpage, Brave, Google or Bing
  selectable). No search-suggestion requests are made while you type. The
  search engine you pick is a third-party service you choose; its own privacy
  policy applies.
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
  location, camera, microphone and file uploads are disabled.
- **Downloads** (since 0.4.4): when you start a download or long-press an image
  → "Save image to vault", GizliAlan's own code fetches the file directly from
  that website (sending the site's own cookies, the browser's user agent and
  the page address as Referer, exactly like the browser would), keeps it in
  memory and saves it **only into the encrypted vault** (images → Photos,
  other files → Files). Nothing is written to shared storage or the Downloads
  folder, and nothing is sent to the developer.
- Screenshots and recent-apps previews stay blocked (FLAG_SECURE).

## Calculator entry and decoy PIN (disclosed features)

- The app can open as a working calculator; entering your PIN followed by `=`
  opens the vault. This is explained during setup, in the calculator's ⓘ
  button and in the store listing. In the launcher the app is labelled
  "Calculator" / "Hesap Makinesi" with a simple calculator icon, and it really
  is a working calculator; the vault behind it is disclosed as above.
- An optional decoy PIN opens a separate, initially empty vault with its own key.

## "Delete original after import" (optional, off by default)

If you turn on **"Delete original after import"** ("Kasaya aktarınca orijinali
sil"), GizliAlan deletes the original photo/file on your phone only **after**
its encrypted copy has been written to the vault and read back successfully.
For gallery media Android shows its **own system confirmation dialog** and
nothing is deleted unless you confirm; files picked in the system file picker
are deleted using the access you granted in that picker. No storage permission
is used. If anything fails, the original is kept.

## Second phone (optional Android work profile)

> Applies **only to the sideloaded "full" APK** distributed outside Google
> Play. The Google Play version has no Second phone, no work-profile code and
> no device-admin component.

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

## Age

GizliAlan is intended for adults (18+) and is not directed at children.

## Changes

If features that touch data (e.g. optional backup, purchases) are added, this
policy and the Play Data safety form will be updated **before** release.

## Contact

Data controller / developer: Demirhan Çelik (OfferForge), Türkiye.
Support e-mail: **delibaltabaris5@gmail.com**
This policy: https://canaslan1675-rgb.github.io/gizli-alan/privacy/

---

## TR — Gizlilik Politikası ve KVKK Aydınlatma Metni

**Son güncelleme:** 2026-09-27 (v0.4.6)

### 1. Veri sorumlusu (KVKK md.10/a)

Demirhan Çelik (OfferForge), Türkiye. İletişim ve başvuru:
**delibaltabaris5@gmail.com**

### 2. Özet

GizliAlan **cihazda çalışan** kişisel bir kasadır. Eklediğin fotoğraf, dosya ve
notlar **yalnızca cihazında, AES-256-GCM ile şifreli** saklanır. Hesap, sunucu,
analitik, telemetri, reklam veya hata raporlama SDK'sı yoktur; uygulama kasa
içeriğini veya kullanım verisini geliştiriciye ya da üçüncü kişilere
göndermez. Geliştirici senin kasa verilerine **hiçbir şekilde erişemez**.

### 3. Cihazında işlenen veriler ve amaçları (md.10/b, md.10/d)

Aşağıdaki veriler yalnızca senin cihazında, senin kullanımın için işlenir;
geliştiriciye aktarılmaz:

| Veri | Nerede / nasıl | Amaç |
|------|----------------|------|
| Kasa fotoğrafları, dosyaları, notları | Uygulamaya özel depolama, AES-256-GCM | Kasan |
| Kasa anahtarları | Android Keystore destekli güvenli depo | Kasayı açmak |
| PIN ve isteğe bağlı sahte PIN | Yalnızca tuzlanmış PBKDF2-HMAC-SHA256 özeti | Kilit açma |
| Kasa içi bildirim listesi (içe/dışa aktarma, silme, hatalı PIN sayısı) | Şifreli, yalnızca kasa içinde görünür | Kasada ne olduğunu göstermek |
| Hatalı deneme sayaçları | Güvenli depo | Kaba kuvvet denemelerini yavaşlatmak |
| Tercihler (dil, otomatik kilit, hesap makinesi girişi, biyometri, duvar kağıdı) | Uygulamaya özel ayarlar | Uygulama ayarları |

Biyometrik kilit Android BiometricPrompt kullanır; parmak izi/yüz verisi
uygulamaya **hiç gelmez**, Android yalnızca "başarılı/başarısız" bildirir.
Toplama yöntemi: verileri sen uygulamaya kendin eklersin (sistem fotoğraf/dosya
seçicisi, not yazma); depolama izni kullanılmaz. Hukuki sebep: bu işlemler
senin cihazında, senin talebinle gerçekleşir; geliştirici bu verileri işlemez.

### 4. Kasa içi gizli tarayıcı ve indirilenler

- `INTERNET` izni **yalnızca** kasa içi tarayıcı içindir; tek ağ trafiği
  **senin** açtığın sayfalaradır (Android System WebView). Bu siteler, her
  tarayıcıda olduğu gibi IP adresini ve onlara gönderdiklerini görür; kendi
  gizlilik politikaları geçerlidir.
- Arama motoru (varsayılan DuckDuckGo; Startpage, Brave, Google, Bing) **senin
  seçtiğin** üçüncü taraf bir hizmettir. WebView'in **Güvenli Tarama (Safe
  Browsing)** özelliği Android/WebView platform bileşenidir, GizliAlan'ın
  içindeki bir SDK değildir; Android/Google Play hizmetleri ziyaret edilen
  adresleri Google'ın tehlikeli siteler listesiyle karşılaştırabilir. WebView
  kullanım ölçümleri kapalıdır.
- Çerez, önbellek ve site verileri uygulamanın özel alanında tutulur ve kasa
  kilitlenince **silinir** ("Kilitlenince temizle", varsayılan açık). Geçmiş
  yalnızca bellekte tutulur. Üçüncü taraf çerezler engellidir; konum, kamera,
  mikrofon ve dosya yükleme kapalıdır.
- **İndirilenler:** bir indirme başlattığında veya bir resme uzun basıp
  "Resmi kasaya kaydet" dediğinde, dosyayı GizliAlan'ın kendi kodu doğrudan o
  siteden çeker (sitenin kendi çerezleri, tarayıcı kimliği ve sayfa adresi ile,
  tarayıcının yapacağı gibi), bellekte tutar ve **yalnızca şifreli kasaya**
  kaydeder (resimler → Fotoğraflar, diğerleri → Dosyalar). Telefon depolamasına
  veya İndirilenler klasörüne hiçbir şey yazılmaz, geliştiriciye hiçbir şey
  gönderilmez.

### 5. "Kasaya aktarınca orijinali sil" (isteğe bağlı, varsayılan kapalı)

Bu seçeneği açarsan, telefondaki orijinal fotoğraf/dosya **ancak** şifreli
kopyası kasaya yazılıp başarıyla geri okunduktan **sonra** silinir. Galeri
öğelerinde Android **kendi sistem onay penceresini** gösterir; onaylamazsan
hiçbir şey silinmez. Dosya seçiciyle seçilen dosyalar, o seçicide verdiğin
erişimle silinir. Depolama izni kullanılmaz; bir hata olursa orijinal korunur.

### 6. Hesap makinesi girişi ve sahte PIN (açıkça belirtilen özellikler)

Uygulama çalışan bir hesap makinesi olarak açılabilir; PIN'ini yazıp `=`
tuşuna basınca kasa açılır. Bu, kurulumda, hesap makinesindeki ⓘ düğmesinde ve
mağaza açıklamasında anlatılır. Başlatıcıda "Hesap Makinesi" adıyla görünür.
İsteğe bağlı sahte PIN, kendi anahtarı olan ayrı ve başlangıçta boş bir kasa
açar.

### 7. İkinci telefon (iş profili)

> Bu bölüm **yalnızca Google Play dışında dağıtılan "full" APK** için
> geçerlidir. **Google Play sürümünde** İkinci telefon, iş profili kodu veya
> cihaz yöneticisi bileşeni **yoktur**.

"İkinci telefon → Kur" dersen Android cihazında bir iş profili oluşturur ve
GizliAlan **yalnızca o profilin** sahibi olur (Shelter/Island ile aynı yöntem).
GizliAlan bu rolü yalnızca şunlar için kullanır: kasa kilitliyken profil
uygulamalarını gizlemek ve kilidi açınca geri göstermek, ana profildeki bir
uygulamayı profilde kullanılabilir yapmak, profilin Play Store'unu açmak,
profil uygulamalarını listelemek/başlatmak ve profili silmek. Profil içindeki
uygulamaların verilerini, mesajlarını veya bildirimlerini okumaz; uygulama
listesi (başlatılabilir uygulamaların adı ve simgesi) cihazda kalır.

### 8. Aktarım (md.10/c)

Uygulama verileri geliştiriciye veya üçüncü kişilere **aktarılmaz**, yurt
dışına aktarılmaz. Yalnızca sen destek için e-posta yazarsan, e-posta adresin
ve mesajın geliştirici tarafından sorunu çözmek amacıyla işlenir (KVKK
md.5/2-c ve f); bu e-posta Google'ın e-posta hizmeti (Gmail) üzerinden alındığı
için yurt dışındaki sunucularda saklanabilir (md.9). Bu işlem yalnızca sen
yazmayı seçersen gerçekleşir ve talebin sonuçlandıktan sonra e-posta silinir.

### 9. Haklarınız (KVKK md.11) ve başvuru

KVKK md.11 uyarınca; kişisel verilerinin işlenip işlenmediğini öğrenme,
işlenmişse bilgi talep etme, işlenme amacını ve amacına uygun kullanılıp
kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü
kişileri bilme, eksik veya yanlış işlenmişse düzeltilmesini, md.7 şartları
çerçevesinde silinmesini veya yok edilmesini isteme, bu işlemlerin aktarılan
üçüncü kişilere bildirilmesini isteme, münhasıran otomatik sistemlerle analiz
edilmesi sonucu aleyhine bir sonuç çıkmasına itiraz etme ve kanuna aykırı
işleme nedeniyle zarara uğrarsan zararın giderilmesini talep etme haklarına
sahipsin.

Başvurunu **delibaltabaris5@gmail.com** adresine yazılı olarak iletebilirsin;
talebin en geç **30 gün** içinde ücretsiz sonuçlandırılır (md.13). Kasa
verilerin yalnızca cihazındadır; onları uygulama içinden (öğe silme veya
Ayarlar → Her şeyi sıfırla) ya da uygulamayı kaldırarak kendin silebilirsin.
**PIN kurtarma yoktur**; verin bizde olmadığı için kurtaramayız.

### 10. Güvenlik sınırları

Şifreleme kasanı diğer uygulamalara, gelişigüzel erişime ve uygulama
dosyalarının kopyalanmasına karşı korur; root'lu/ele geçirilmiş bir cihaza veya
PIN'ini bilen birine karşı tam koruma sağlayamaz. Ekran görüntüsü ve son
uygulamalar önizlemesi her zaman engellidir (FLAG_SECURE). Uygulama yedeği
kapalıdır.

### 11. Yaş

GizliAlan yetişkinler (18+) içindir; çocuklara yönelik değildir.

### 12. Değişiklikler

Veriye dokunan yeni özellikler (ör. yedekleme, satın alma) eklenirse bu metin
ve Play Veri güvenliği formu yayından **önce** güncellenir.

**İletişim / destek:** delibaltabaris5@gmail.com — Politika: https://canaslan1675-rgb.github.io/gizli-alan/privacy/

*This document is provided for transparency and Play policy readiness. It is not legal advice.*
