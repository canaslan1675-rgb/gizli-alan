# AUTONOMOUS_BRIEF — GizliAlan (Gizli Sanal Telefon) MVP

> Bu dosya, proje sahibi (Demirhan Çelik) ile konuşulmadan 3 hafta boyunca kesintisiz geliştirme yapılabilmesi için tek kaynaktır.
> Belirsizlikte: bu brief > `docs` / araştırma dosyaları > kendi mühendislik kararın. Karar ver, not düş, devam et.

---

## 1. Proje

**Ne:** Kullanıcının *kendi* telefonunun içinde ayrı görünen ikinci bir "telefon alanı". Kendi uygulama ızgarası, notları, medyası ve bildirimleri ana telefondan ayrı durur. Metafor: "telefonun içinde yeni telefon".

**Kimin için:** Yalnızca cihaz sahibi. Kişisel mahremiyet kasası.

**Teknoloji:** Flutter (Android öncelikli), `flutter_secure_storage`, AES-GCM veya SQLCipher ile şifreli yerel depolama, `local_auth`, `image_picker`, FLAG_SECURE.

**Kaynaklar:**
- `/workspace/gizli-arastirma/gizli-sanal-telefon-app-20260920.md`: konsept, rakipler (Keepsafe, Calculator Vault, Shelter/Island, Private Space), teknik seçenekler A–F, mimari matris, MVP planı, gelir modeli
- `/workspace/gizli-arastirma/gizlialan/01–05`: teknik gizleme, Play Billing, UI wireframe, rekabet, Play uyumluluk, `PRIVACY_POLICY.md`

**Mimari karar:** MVP = seçenek C + E (Flutter uygulama içi kasa + çift mod arayüz). Launcher rolü ve bulut senkron kapsam dışı.

**v0.2 güncellemesi (25 Eylül 2026, proje sahibinin talebi):** seçenek A eklendi — isteğe bağlı "İkinci telefon" = Android yönetilen iş profili (Shelter/Island modeli), uygulama yalnızca bu profilin *profil sahibi*. Başlatıcı adı/simgesi nötr hesap makinesi ("Hesap Makinesi" / "Calculator"), kasa açıkça belirtilerek. Ayrıntı: `DECISIONS.md`.

---

## 2. MVP kapsamı (3 hafta)

### Hafta 1: Güvenlik çekirdeği
- [ ] Şifreli kasa altyapısı: anahtar üretimi, secure storage'da saklama, AES-GCM şifreleme/çözme servisi
- [ ] PIN oluşturma, doğrulama, değiştirme (hash + salt, deneme sınırı ve bekleme süresi)
- [ ] Parmak izi / biyometrik kilit açma (`local_auth`), PIN yedeği
- [ ] Arka plana geçince otomatik kilit, FLAG_SECURE (ekran görüntüsü ve son uygulamalar önizlemesi engeli)
- [ ] Galeri kasası: içe aktarma, şifreli kopya, ızgara görünüm, görüntüleyici, silme, dışa aktarma
- [ ] Birim testleri: kripto servisi, auth servisi
- [ ] Hafta sonu PR'ı

### Hafta 2: Giriş katmanı ve içerik
- [ ] Çalışan hesap makinesi girişi: PIN yazılıp `=` basılınca kasa açılır. Mağaza açıklamasında ve onboarding'de açıkça belirtilir.
- [ ] Sahte PIN (isteğe bağlı): boş, sahte bir kasa açar
- [ ] Notlar: şifreli oluşturma, düzenleme, silme, arama
- [ ] Onboarding: "Bu uygulama yalnızca kendi cihazınız içindir"
- [ ] TR ve EN metinler
- [ ] Testler, hafta sonu PR'ı

### Hafta 3: Sanal telefon arayüzü ve Play hazırlığı
- [ ] Kasa içi "ana ekran": ikon ızgarası (Galeri, Notlar, Dosyalar, Ayarlar), duvar kağıdı seçimi
- [ ] Uygulama içi bildirim izolasyonu: yalnızca kasa içinde görünen bildirim listesi, sistem bildiriminde içerik gösterilmez
- [ ] Ayarlar: PIN değiştir, biyometri aç/kapa, sahte PIN, otomatik kilit süresi
- [ ] Play hazırlığı: gizlilik politikası, Data safety notları, TR+EN mağaza metni taslağı, ekran görüntüsü planı, minimum izin listesi
- [ ] Ödeme için yalnızca stub/arayüz (gerçek entegrasyon yok, bkz. §5)
- [ ] Release derlemesi (mümkünse APK), hafta sonu PR'ı

---

## 3. Kesin yasaklar

- Casus veya izleme yazılımı yok. Başkasını izleme, konum takibi, SMS/arama dinleme yok.
- Keylogging yok. Accessibility Service kullanılmaz.
- **Device Admin yasağı = ana cihaz / ana profil yöneticiliği yasağı.** Uygulama cihaz sahibi (device owner) olmaz, ana profilde cihaz yöneticisi (şifre, kilit, silme, kaldırma engeli vb. politikalar) olarak etkinleştirilmez; böyle etkinleştirilirse kendini hemen devre dışı bırakır.
- **İzin verilen istisna:** yalnızca "İkinci telefon" özelliği için, kullanıcının kendi açık onayıyla oluşturduğu iş profilinin *profil sahibi* (profile owner) olmak (`ACTION_PROVISION_MANAGED_PROFILE`, politika listesi boş `DeviceAdminReceiver`). Bu yetki yalnızca sahibinin kendi izolasyonu için kullanılır: profil uygulamalarını gizle/göster, uygulama ekle, profil Play Store'unu aç, profil uygulamalarını listele/başlat, profili sil. Profil içindeki uygulamaların verisi, bildirimleri veya kullanımı okunmaz/izlenmez.
- Gizli izleme, sunucuya veri yükleme, uzaktan panel yok.
- Cloaking yok: mağaza incelemesinde gösterilen davranış ile gerçek davranış aynı olmalı. Hesap makinesi girişi açıkça belgelenir.
- Uygulama ikonunu sistemden gizleme veya başka bir uygulama gibi davranma yok. Nötr "Hesap Makinesi" adı/simgesi serbesttir çünkü uygulama gerçekten çalışan bir hesap makinesidir ve kasa onboarding, ⓘ ve mağaza metninde açıklanır; Google/Samsung/Xiaomi vb. marka simgeleri veya adları kopyalanmaz.
- Yalnızca gerekli izinler istenir. Play politikalarına ve Türk hukukuna (KVKK) uyulur.

## 4. Fiyat ve gelir (uygulama içinde yalnızca arayüz olarak)

- Ücretsiz: temel kasa, 30–50 öğe sınırı, reklam yok
- Pro tek seferlik: yaklaşık **249 TL / 7,99 USD**
- Pro yıllık: **449 TL**
- Gumroad'da uygulama satılmaz. Orada yalnızca yardımcı bir kurulum ve mahremiyet rehberi olur.

---

## 5. Çalışma kuralları

- [ ] Her gün kod yazılır. Proje sahibi yokken de iş durmaz.
- [ ] Her anlamlı adımda küçük, açıklayıcı commit atılır (`feat:`, `fix:`, `test:`, `docs:`).
- [ ] Her hafta sonunda bir PR açılır. Her PR'da değişen dosyaların bir satırlık özetleri, test/analyze sonucu ve kalan iş listesi bulunur.
- [ ] `flutter analyze` ve `flutter test` her commit öncesi temiz olmalı.
- [ ] Normal geliştirme kararları için onay beklenmez. Karar verilir, `DECISIONS.md` dosyasına not düşülür.
- [ ] **Riskli veya geri alınamaz adımlarda DUR ve not düş** (`BLOCKERS.md`): Play Store'a yükleme veya yayın, gerçek ödeme / Play Billing entegrasyonu, herhangi bir harcama, hesap açma, dış servislere kişisel veri gönderme, force push veya geçmişi yeniden yazma.
- [ ] Günlük ilerleme `PROGRESS.md` dosyasına tek paragraf olarak yazılır.

## 6. Mevcut durum (25 Eylül 2026)

- `/workspace/gizli-alan/` klasöründe iskelet var: onboarding, PIN kilidi, hesap makinesi girişi, notlar, dosyalar, kasa ana ekranı, TR/EN, PRIVACY.md.
- Kod yazımı `mvp-v1` dalında sürüyor. PR açıklaması taslağı `PR_DESCRIPTION.md` dosyasında.
- GitHub CLI girişi, proje sahibinin cihaz onayını bekliyor. Giriş tamamlanana kadar push/PR yok, commit'ler yerelde birikir. Giriş sonrası ilk iş: özel (private) repo oluştur, push et, PR aç.

## 7. Bitti tanımı (3. hafta sonu)

- [ ] Uygulama derleniyor, analyze ve testler temiz
- [ ] Hafta 1–3 kontrol listelerinin tamamı işaretli ya da `BLOCKERS.md` dosyasında gerekçeli
- [ ] 3 haftalık PR geçmişi ve güncel `PROGRESS.md`
- [ ] Play hazırlık paketi (politika, Data safety, mağaza metni) repoda
