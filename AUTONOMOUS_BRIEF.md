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
- [x] Şifreli kasa altyapısı: anahtar üretimi, secure storage'da saklama, AES-GCM şifreleme/çözme servisi
- [x] PIN oluşturma, doğrulama, değiştirme (hash + salt, deneme sınırı ve bekleme süresi)
- [x] Parmak izi / biyometrik kilit açma (`local_auth`), PIN yedeği
- [x] Arka plana geçince otomatik kilit, FLAG_SECURE (ekran görüntüsü ve son uygulamalar önizlemesi engeli)
- [x] Galeri kasası: içe aktarma, şifreli kopya, ızgara görünüm, görüntüleyici, silme, dışa aktarma
- [x] Birim testleri: kripto servisi, auth servisi
- [x] Hafta sonu PR'ı — PR #1 (`mvp-v1` → `main`, birleştirildi)

### Hafta 2: Giriş katmanı ve içerik
- [x] Çalışan hesap makinesi girişi: PIN yazılıp `=` basılınca kasa açılır. Mağaza açıklamasında ve onboarding'de açıkça belirtilir.
- [x] Sahte PIN (isteğe bağlı): boş, sahte bir kasa açar
- [x] Notlar: şifreli oluşturma, düzenleme, silme, arama
- [x] Onboarding: "Bu uygulama yalnızca kendi cihazınız içindir"
- [x] TR ve EN metinler
- [x] Testler, hafta sonu PR'ı — PR #1/#2 (birleştirildi)

### Hafta 3: Sanal telefon arayüzü ve Play hazırlığı
- [x] Kasa içi "ana ekran": ikon ızgarası (Galeri, Notlar, Dosyalar, Ayarlar), duvar kağıdı seçimi
- [x] Uygulama içi bildirim izolasyonu: yalnızca kasa içinde görünen bildirim listesi, sistem bildiriminde içerik gösterilmez — #4, PR #19 (sahibinin birleştirmesini bekliyor)
- [x] Ayarlar: PIN değiştir, biyometri aç/kapa, sahte PIN, otomatik kilit süresi
- [x] Play hazırlığı: gizlilik politikası, Data safety notları, TR+EN mağaza metni taslağı, ekran görüntüsü planı, minimum izin listesi — `PRIVACY.md`, `docs/PLAY_COMPLIANCE.md` (ekran görüntüsü *planı* dahil). Açık: ekran görüntülerinin kendisi #6, HTTPS'te barındırma + destek e-postası #12 (sahibi)
- [x] Ödeme için yalnızca stub/arayüz (gerçek entegrasyon yok, bkz. §5) — #5, PR #20 (sahibinin birleştirmesini bekliyor); gerçek ödeme #15 (sahibi, DUR)
- [x] Release derlemesi (mümkünse APK), hafta sonu PR'ı — `v0.2.0-test` ön sürümü (arm64 APK, debug imzalı). İmzalama yapılandırması #8 / PR #21; yükleme anahtarı #13 (sahibi)

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

> Bu maddeler sürekli geçerli kurallardır; işaretlenmez. Ajanlar arası iş paylaşımı: `COORDINATION.md`.

- [ ] Her gün kod yazılır. Proje sahibi yokken de iş durmaz.
- [ ] Her anlamlı adımda küçük, açıklayıcı commit atılır (`feat:`, `fix:`, `test:`, `docs:`).
- [ ] Her hafta sonunda bir PR açılır. Her PR'da değişen dosyaların bir satırlık özetleri, test/analyze sonucu ve kalan iş listesi bulunur.
- [ ] `flutter analyze` ve `flutter test` her commit öncesi temiz olmalı.
- [ ] Normal geliştirme kararları için onay beklenmez. Karar verilir, `DECISIONS.md` dosyasına not düşülür.
- [ ] **Riskli veya geri alınamaz adımlarda DUR ve not düş** (`BLOCKERS.md`): Play Store'a yükleme veya yayın, gerçek ödeme / Play Billing entegrasyonu, herhangi bir harcama, hesap açma, dış servislere kişisel veri gönderme, force push veya geçmişi yeniden yazma.
- [ ] Günlük ilerleme `PROGRESS.md` dosyasına tek paragraf olarak yazılır.

## 6. Mevcut durum (25 Eylül 2026, güncellendi)

- Repo: GitHub'da özel repo `canaslan1675-rgb/gizli-alan`. **Entegrasyon dalı `main`**: MVP v1 (PR #1), v0.2 hesap makinesi markası + "İkinci telefon" (PR #2), Cursor kuralları + koordinasyon protokolü (PR #3) birleştirildi. `mvp-v1`, `v0.2-calculator-workprofile`, `cursor-rules` artık tarihsel.
- Sürüm 0.2.0+2; test ön sürümü `v0.2.0-test` (arm64 APK, debug imzalı, mağaza için değil).
- Açık PR'lar (sahibinin birleştirmesini bekliyor): #18 (main = entegrasyon dalı), #19 kasa içi bildirimler (#4), #20 Pro arayüz stub'ı (#5), #21 release imzalama (#8) ve bu doküman senkronu (#9).
- İki ajan grubu (Joi ve Cursor ajanları) `COORDINATION.md` protokolüyle çalışır: işler `task` etiketli GitHub issue'ları, günlük `docs/AGENT_LOG.md`. Kalan işler ve sahibi kararları issue olarak açık (#6, #7, #10; sahibi: #11–#16).
- GitHub girişi tamamlandı; önceki "giriş bekleniyor" notu geçersiz.

## 7. Bitti tanımı (3. hafta sonu)

- [x] Uygulama derleniyor, analyze ve testler temiz
- [x] Hafta 1–3 kontrol listelerinin tamamı işaretli ya da `BLOCKERS.md` dosyasında gerekçeli (açık kalanlar issue'lara bağlı; PR #19/#20 birleşince tamam)
- [ ] 3 haftalık PR geçmişi ve güncel `PROGRESS.md` (PROGRESS güncel; 3 haftalık geçmiş henüz tamamlanmadı — 3. hafta sonunda yeniden kontrol edilecek)
- [x] Play hazırlık paketi (politika, Data safety, mağaza metni) repoda (`PRIVACY.md`, `docs/PLAY_COMPLIANCE.md`; barındırma #12)
