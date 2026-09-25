# Mağaza metni — Türkçe (tr-TR)

> **TR özet.** `play` flavor'u için dürüst, anahtar kelimeye duyarlı ama anahtar kelime doldurması olmayan mağaza metni. Başlık hesap makinesi görünümünü açıkça söyler
> ("Hesap Makineli Kasa"), çünkü cihazda uygulama "Hesap Makinesi" adıyla görünür; Play'deki onaylı emsaller de böyle (bkz. RESEARCH.md §3.1). Açıklama önce kasayı, sonra hesap makinesi girişini
> ve "ne değildir" bölümünü anlatır. En altta `full` (İkinci telefon) varyantı var. Eski taslak (`docs/PLAY_COMPLIANCE.md` §3) yerine bunu kullanın.

## Kurallar (Metadata politikası)
- Başlık ≤ 30, kısa açıklama ≤ 80, tam açıklama ≤ 4000 karakter; başlıkta emoji / BÜYÜK HARF / "#1", "ücretsiz", "en iyi" yok.
- Anahtar kelimeler doğal cümlelerde: *kasa, şifreli, fotoğraf, not, dosya, hesap makinesi, gizlilik*. Liste halinde kelime yığını yok, rakip/marka adı yok.
- Kaçınılacak kelimeler: "kılık değiştirmiş", "kimse bulamaz", "eşinden/ailenden gizle", "casus", "takip".
- Yalnızca derlemede olan özellikler. Pro/fiyat anılmaz (faturalama yok, #15).

## `play` flavor

**Başlık (30/30):**
```
GizliAlan: Hesap Makineli Kasa
```
Alternatif: `Hesap Makineli Kasa: GizliAlan` (30).

**Kısa açıklama (78/80):**
```
Çalışan bir hesap makinesinin arkasında şifreli fotoğraf, dosya ve not kasası.
```

**Tam açıklama (1981/4000):**
```
GizliAlan, telefonunun sahibi için çevrimdışı çalışan kişisel bir kasadır. Fotoğrafların, belgelerin ve notların PIN (isteğe bağlı parmak izi/yüz) ile korunur ve yalnızca cihazında AES-256-GCM ile şifrelenir.

HESAP MAKİNESİ GİRİŞİ – AÇIKÇA
Uygulama telefonunda "Hesap Makinesi" adıyla ve özgün bir hesap makinesi simgesiyle görünür. Bu simge GizliAlan'dır. Açıldığında gerçekten çalışan bir hesap makinesi karşılar. Kasa PIN'ini yazıp "=" tuşuna basınca kasa açılır; biyometriyi açtıysan "=" tuşuna uzun bas. Bu davranış ilk kurulumda, hesap makinesindeki ⓘ düğmesinde ve bu açıklamada anlatılır. İstersen Ayarlar'dan kapatıp uygulamanın doğrudan PIN ekranıyla açılmasını seçebilirsin.

ÖZELLİKLER
• Şifreli galeri: fotoğrafları sistem seçicisiyle ekle, ızgarada gör, dışa aktar veya sil
• Şifreli notlar (arama ile) ve şifreli dosyalar (PDF vb.)
• Kasa içinde kendi ana ekranı ve duvar kağıdı seçimi
• PIN + isteğe bağlı parmak izi/yüz, arka plana geçince otomatik kilit
• Hatalı deneme sınırı ve bekleme süresi; son kilit açmadan beri kaç hatalı deneme olduğunu kasa içinde görürsün
• Ekran görüntüsü ve son uygulamalar önizlemesi engellenir
• İsteğe bağlı sahte PIN: ayrı, başlangıçta boş ikinci bir kasa açar (biyometri her zaman gerçek kasayı açar)
• Türkçe ve İngilizce

GİZLİLİK
• Hesap yok, sunucu yok, reklam yok, analitik yok
• İnternet izni yok: uygulama verini hiçbir yere gönderemez
• Tek izin: isteğe bağlı biyometrik kilit. Fotoğraf ve dosyaları sen seçersin; depolama izni istenmez
• Bulut yedeklemesi kapalıdır; uygulamayı kaldırmak kasayı siler
• PIN kurtarma yoktur. PIN'ini unutursan içerik çözülemez; bunu bilerek kullan

NE DEĞİLDİR
• Başkasını izleme, takip etme veya dinleme aracı değildir
• SMS, arama, rehber veya konum okumaz; Erişilebilirlik Hizmeti kullanmaz; telefonunun yöneticisi olmaz
• Başka uygulamaları kilitlemez veya gizlemez
• Yalnızca kendi cihazında, kendi içeriğin için kullan

Gizlilik politikası ve destek e-postası bu sayfada yer alır.
```

**Kategori:** Araçlar (Tools) · **Etiketler:** Console'un önerdiği listeden yalnızca gerçekten uyanlar (gizlilik / güvenlik ile ilgili olanlar).

**Ekran görüntüsü sırası ve alt yazılar** (`docs/store/screenshots/play/tr/`):
1. `01_calculator_info.png` — "Gerçek bir hesap makinesi. ⓘ kasayı açıklar."
2. `02_onboarding_disclosure.png` — "Kurulumda açıkça anlatılır; istersen kapat."
3. `03_vault_home.png` — "Kasanın kendi ana ekranı."
4. `04_gallery.png` — "Şifreli galeri."
5. `05_notes.png` — "Şifreli notlar, arama ile."
6. `06_settings.png` — "PIN, biyometri, otomatik kilit, sahte PIN."

**Sürüm notları (ilk sürüm):**
```
İlk sürüm: şifreli galeri, notlar ve dosyalar; hesap makinesi girişi (PIN + "="); biyometrik kilit; internet izni yok.
```

---

## `full` flavor varyantı (yalnızca sahibi `full`'u Play'e göndermeye karar verirse)

**Başlık (29/30):**
```
GizliAlan: Kasa ve İş Profili
```
(İkinci telefon ürünün ana farkıysa başlıkta "İş Profili" geçmesi dürüstlüğü artırır. Hesap makinesi girişi açıklamada ilk paragraflarda kalır.)

**Kısa açıklama (73/80):**
```
Hesap makinesi girişli şifreli kasa + iş profiliyle ayrı bir ikinci alan.
```

**Tam açıklama (3174/4000):**
```
GizliAlan, telefonunun sahibi için çevrimdışı çalışan kişisel bir kasadır. Fotoğrafların, belgelerin ve notların PIN (isteğe bağlı parmak izi/yüz) ile korunur ve yalnızca cihazında AES-256-GCM ile şifrelenir.

HESAP MAKİNESİ GİRİŞİ – AÇIKÇA
Uygulama telefonunda "Hesap Makinesi" adıyla ve özgün bir hesap makinesi simgesiyle görünür. Bu simge GizliAlan'dır. Açıldığında gerçekten çalışan bir hesap makinesi karşılar. Kasa PIN'ini yazıp "=" tuşuna basınca kasa açılır; biyometriyi açtıysan "=" tuşuna uzun bas. Bu davranış ilk kurulumda, hesap makinesindeki ⓘ düğmesinde ve bu açıklamada anlatılır. İstersen Ayarlar'dan kapatıp uygulamanın doğrudan PIN ekranıyla açılmasını seçebilirsin.

ÖZELLİKLER
• Şifreli galeri: fotoğrafları sistem seçicisiyle ekle, ızgarada gör, dışa aktar veya sil
• Şifreli notlar (arama ile) ve şifreli dosyalar (PDF vb.)
• Kasa içinde kendi ana ekranı ve duvar kağıdı seçimi
• PIN + isteğe bağlı parmak izi/yüz, arka plana geçince otomatik kilit
• Hatalı deneme sınırı ve bekleme süresi; son kilit açmadan beri kaç hatalı deneme olduğunu kasa içinde görürsün
• Ekran görüntüsü ve son uygulamalar önizlemesi engellenir
• İsteğe bağlı sahte PIN: ayrı, başlangıçta boş ikinci bir kasa açar (biyometri her zaman gerçek kasayı açar)
• Türkçe ve İngilizce

İKİNCİ TELEFON (İSTEĞE BAĞLI, ANDROID İŞ PROFİLİ)
• "İkinci telefon" Android'in kendi iş profili özelliğiyle ayrı bir alan kurar (Shelter/Island yöntemi). Kurulumu Android'in kendi onay ekranları yürütür
• Bu alanın kendi Play Store'una ikinci bir Google hesabı ekleyip uygulama kurabilir, ana telefondaki bir uygulamayı buraya ekleyebilirsin. Uygulamalar, hesaplar ve dosyalar Android tarafından ana telefondan ayrı tutulur
• Kasayı kilitleyince bu alanın uygulamalarını gizleyebilir (isteğe bağlı), kasadan başlatabilirsin
• CİHAZ YÖNETİCİSİ AYRICALIĞI: GizliAlan yalnızca senin oluşturduğun bu iş profilinin profil sahibidir; bunun için Android'in cihaz yöneticisi bileşeni kullanılır, hiçbir yönetici politikası (şifre, kilit, silme vb.) istenmez. Telefonunun cihaz yöneticisi olmaz; öyle etkinleştirilirse kendini kapatır
• İş profilindeki uygulamaların verisini, mesajlarını veya bildirimlerini okumaz
• Kaldırma: uygulamada "İkinci telefonu kaldır" veya Android Ayarlar > Hesaplar > İş profili
• Bazı cihazlarda (ör. Xiaomi MIUI/HyperOS) iş profili desteklenmeyebilir

GİZLİLİK
• Hesap yok, sunucu yok, reklam yok, analitik yok
• İnternet izni yok: uygulama verini hiçbir yere gönderemez
• Tek izin: isteğe bağlı biyometrik kilit (iş profili ek izin gerektirmez). Fotoğraf ve dosyaları sen seçersin; depolama izni istenmez
• Bulut yedeklemesi kapalıdır; uygulamayı kaldırmak kasayı siler
• PIN kurtarma yoktur. PIN'ini unutursan içerik çözülemez; bunu bilerek kullan

NE DEĞİLDİR
• Başkasını izleme, takip etme veya dinleme aracı değildir
• SMS, arama, rehber veya konum okumaz; Erişilebilirlik Hizmeti kullanmaz; telefonunun cihaz yöneticisi olmaz
• Ana telefondaki uygulamaları kilitlemez veya gizlemez; yalnızca kendi iş profilindeki uygulamaları senin isteğinle gizler
• Yalnızca kendi cihazında, kendi içeriğin için kullan

Gizlilik politikası ve destek e-postası bu sayfada yer alır.
```

**Ek ekran görüntüleri:** İkinci telefon kurulum ekranı (Android'in kendi onayı öncesi GizliAlan açıklaması), profil uygulama ızgarası, "İkinci telefonu kaldır". (`docs/store/screenshots/full/` içinde henüz yok.)
