/// Turkish strings (default locale).
const Map<String, String> tr = {
  'appName': 'GizliAlan',
  // Launcher / recents label (Android string resource says the same).
  'launcherName': 'Hesap Makinesi',
  'appNameVault': 'GizliAlan Kasa',
  'decoyTitle': 'Hesap Makinesi',
  // Onboarding
  'onboardingTitle': 'GizliAlan\'a Hoş Geldin',
  'onboardingBody':
      'GizliAlan, bu telefonun sahibine ait kişisel bir kasadır: özel '
      'fotoğraflar, notlar ve dosyalar PIN (ve isteğe bağlı parmak izi/yüz) '
      'ile korunur ve bu cihazda şifrelenir.',
  'onboardingPrivacy':
      "İzleme aracı değildir. GizliAlan SMS, arama, rehber veya konum okumaz; Erişilebilirlik Hizmeti kullanmaz, telefonunun cihaz yöneticisi olmaz ve kendi sunucusu yoktur. Kasa içeriğin, dosya adların ve PIN'in asla cihazdan çıkmaz. Yalnızca anonim uygulama açılışı, kurulum ve Pro satın alma olayları reklam ölçümü için AppMetrica (Yandex) ve TikTok'a gider; Ayarlar → \"Anonim istatistik ve reklam ölçümü\" ile kapatabilirsin. (İsteğe bağlı \"İkinci telefon\" yalnızca senin oluşturduğun ayrı iş profilini yönetir.) Yalnızca kendi cihazında, kendi içeriğin için kullan.",
  'ownDeviceConfirm':
      'Bu benim kendi cihazım ve yalnızca kendi içeriğimi saklayacağım.',
  'entryTitle': 'Hesap makinesi girişi',
  'entryBody':
      'GizliAlan normal, tam çalışan bir hesap makinesi olarak açılabilir. '
      'Kasaya girmek için PIN\'ini yazıp "=" tuşuna bas. Biyometrik için "=" '
      'tuşuna uzun bas (açıksa).',
  'entryDisclosure':
      'Bu gizlenmiş bir özellik değildir; mağaza açıklamasında ve hesap '
      'makinesindeki ⓘ düğmesinde anlatılır. Telefonunun uygulama listesinde '
      'bu uygulama sade bir hesap makinesi simgesiyle "Hesap Makinesi" adıyla '
      'görünür — o simge GizliAlan\'dır. Hesap makinesi girişini Ayarlar\'dan '
      'istediğin zaman kapatabilirsin.',
  'calculatorEntry': 'Hesap makinesi olarak aç',
  'calculatorEntryOn':
      'Uygulama hesap makinesiyle açılır — PIN ve "=" kasayı açar',
  'calculatorEntryOff': 'Uygulama PIN ekranıyla açılır',
  'setPin': 'PIN Belirle',
  'confirmPin': "PIN'i tekrar gir",
  'pinFormat': 'PIN 4–8 haneli rakam olmalı',
  'pinMismatch': 'PIN\'ler eşleşmiyor',
  'pinNoRecovery':
      'Önemli: PIN kurtarma yoktur. PIN\'ini unutursan kasa içeriği '
      'çözülemez; yalnızca tamamen sıfırlama mümkündür.',
  'finishSetup': 'Kasayı oluştur',
  'continue': 'Devam',
  'back': 'Geri',
  'dataSafetyShort':
      "Veriler bu cihazda, şifreli kalır. Hesap yok, bulut yok, reklam gösterilmez. Kasa içeriği asla gönderilmez; yalnızca anonim açılış/kurulum/satın alma istatistikleri (Ayarlar'dan kapatılabilir).",
  // Calculator
  'calcInfoProHint': "Pro üyeler bu simgeyi Ayarlar'dan gizleyebilir.",
  'hideCalcInfo': 'Hesap makinesinde bilgi simgesini gizle',
  'hideCalcInfoHint':
      'ⓘ düğmesi hesap makinesinden kalkar. Yardım: Ayarlar → Hesap makinesi girişi hakkında.',
  'hideCalcInfoLocked': 'Pro özelliği. Pro ekranını açmak için dokun.',
  'proSoon': 'Pro yakında',
  'calcHelpTitle': 'Hesap makinesi girişi hakkında',
  'calcHelpHint': 'Kasanın nasıl açıldığı (ⓘ ile aynı açıklama)',
  'proStubToggle': "Pro'yu simüle et (test sürümü)",
  'proStubToggleHint':
      'Satın alma yok; yalnızca Pro özelliklerini denemek için yerel bir anahtar.',
  'deleteOriginal': 'Kasaya aktarınca orijinali sil',
  'deleteOriginalHint':
      'Kasaya kaydedildikten sonra telefondaki orijinal silinir.',
  'deleteOriginalAskTitle': 'Orijinaller galeriden silinsin mi?',
  'deleteOriginalAskBody':
      'Açarsan, kasaya aktardığın fotoğrafların orijinalleri bundan sonra telefon galerisinden silinir. Ayarlar\'dan değiştirebilirsin.',
  'deleteOriginalAskYes': 'Evet, sil',
  'deleteOriginalAskNo': 'Hayır',
  'proSettingsHint_play': "Pro'yu satın al veya geri yükle",
  'payIntro':
      "Kasa, şifreleme, hesap makinesi girişi, sahte PIN, ekran görüntüsü koruması, hızlı kilit, çöp kutusu, video oynatma, tarayıcı ve yedekten geri yükleme ücretsizdir. Pro'yu bir kez satın al, şunlar açılsın:",
  'payF5': 'Sınırsız albüm (ücretsiz: 1)',
  'payF6': 'Kasanın tamamını tek dosyaya şifreli yedekleme',
  'payF7': 'Sınırsız yer imi (ücretsiz: {max})',
  'proF4': 'Sınırsız albüm',
  'proF5': 'Şifreli yedek',
  'proF6': 'Sınırsız yer imi',
  'payF1': 'İkinci telefon (iş profili) kurulumu',
  'payF2': 'Sınırsız öğe (ücretsiz: {max})',
  'payF3': 'Hesap makinesindeki ⓘ simgesini gizleme',
  'payF4': "Gelecek güncellemeler dahil",
  'payLifetime': "GizliAlan Pro – tek seferlik",
  'payLifetimeSub': "Bir kez öde, sonsuza kadar senin. Abonelik yok.",
  'payBuyOnce': "{price} – Bir kez satın al",
  'itemCounter': '{n} öğe',
  'quickLock': 'Hemen kilitle',
  'failedSummary': 'Son girişten beri {n} hatalı deneme',
  'pinHint': 'PIN ipucu',
  'pinHintOptional': 'PIN ipucu (isteğe bağlı)',
  'pinHintSub': 'Hesap makinesinde ekrana uzun basınca görünür',
  'pinHintExplain':
      'Yalnızca sana hatırlatacak kısa bir not yaz; PIN\'in kendisini yazma. Cihazda şifreli saklanır, hesap makinesinde sonuç ekranına uzun basınca görünür. E-posta veya sunucu ile kurtarma yoktur.',
  'pinHintBad': 'İpucu PIN\'i içeremez ve en fazla 60 karakter olabilir.',
  'trash': 'Çöp kutusu',
  'trashSub': 'Silinenler 30 gün saklanır, sonra kalıcı olarak silinir',
  'trashEmpty': 'Çöp kutusu boş',
  'trashEmptyAll': 'Çöp kutusunu boşalt',
  'trashEmptyConfirm':
      'Çöp kutusundaki her şey kalıcı olarak silinsin mi? Bu geri alınamaz.',
  'trashRestore': 'Geri yükle',
  'trashDeleteForever': 'Kalıcı olarak sil',
  'trashDaysLeft': '{d} gün sonra silinecek',
  'trashRestored': 'Geri yüklendi',
  'trashKindPhoto': 'Fotoğraf',
  'trashKindFile': 'Dosya',
  'trashKindNote': 'Not',
  'recentApps': 'Son açılanlar',
  'albumAll': 'Tümü',
  'albumNew': 'Yeni albüm',
  'albumName': 'Albüm adı',
  'albumRename': 'Yeniden adlandır',
  'albumDelete': 'Albümü sil',
  'albumDeleteSub': 'Fotoğraflar galeride kalır',
  'albumMoveTo': 'Albüme taşı',
  'albumRemoveFrom': 'Albümden çıkar',
  'albumEmpty': 'Bu albüm boş. Bir fotoğrafa uzun basıp "Albüme taşı"yı seç.',
  'albumLimitTitle': 'Ücretsiz sürümde 1 albüm',
  'albumLimitBody':
      'Ücretsiz sürümde bir albüm oluşturabilirsin. Pro ile sınırsız albüm açılır; mevcut albümlerin ve fotoğrafların olduğu gibi kalır.',
  'bookmarks': 'Yer imleri',
  'bookmarkAdd': 'Yer imi ekle',
  'bookmarkAdded': 'Yer imlerine eklendi',
  'bookmarksEmpty':
      'Henüz yer imi yok. Bir sayfadayken yer imi simgesine dokun. Yer imleri kasada şifreli saklanır; geçmiş kilitlenince yine silinir.',
  'bookmarkLimitTitle': 'Ücretsiz sürümde 5 yer imi',
  'bookmarkLimitBody':
      'Ücretsiz sürümde en fazla {max} yer imi saklanır. Pro ile sınırsız yer imi açılır; mevcut yer imlerin kalır.',
  'backupCreate': 'Şifreli yedek oluştur',
  'backupCreateSub': 'Kasayı seçtiğin tek bir dosyaya şifreli kaydeder (Pro)',
  'backupRestore': 'Yedekten geri yükle',
  'backupRestoreSub': 'Bir GizliAlan yedek dosyasını seç; olanlar korunur',
  'backupPassword': 'Yedek şifresi',
  'backupPasswordConfirm': 'Yedek şifresi (tekrar)',
  'backupPasswordShort': 'En az 6 karakter olmalı',
  'backupPasswordExplain':
      'Yedek bu şifreyle şifrelenir (AES-256-GCM). Şifreyi unutursan yedek açılamaz; kurtarma yoktur. Dosya yalnızca senin seçtiğin yere kaydedilir, hiçbir sunucuya gönderilmez.',
  'backupRestoreExplain':
      'Yedeği oluştururken belirlediğin şifreyi gir. Yedekteki fotoğraf, dosya, not, albüm ve yer imleri bu kasaya eklenir; mevcut içerik silinmez.',
  'backupWorking': 'Şifreleniyor / çözülüyor…',
  'backupSaved': 'Yedek kaydedildi',
  'backupFailed': 'Yedek oluşturulamadı',
  'backupRestored': 'Geri yüklendi: {p} fotoğraf, {f} dosya, {n} not',
  'backupWrongPassword': 'Şifre yanlış veya dosya bozuk',
  'backupBadFile': 'Bu bir GizliAlan yedek dosyası değil',
  'backupProTitle': 'Şifreli yedek Pro ile',
  'backupProBody':
      'Kasanın tamamını tek bir şifreli dosyaya yedeklemek Pro özelliğidir. Yedekten geri yükleme her zaman ücretsizdir.',
  'videoPlay': 'Oynat',
  'videoFailed':
      'Bu video bu cihazda oynatılamadı. Dışa aktarıp başka bir uygulamayla açabilirsin.',
  'freeBannerTitle': "Ücretsiz sürümdesin (en fazla {max} öğe)",
  'freeBannerBody':
      "Sınırlı plandasın. Pro'yu {price} karşılığında bir kez satın al: öğe sınırı kalkar, İkinci telefon (iş profili), sınırsız albüm, şifreli yedek açılır ve gelecek güncellemeler dahil.",
  'freeBannerBodyPlay':
      "Pro'yu {price} karşılığında bir kez satın al: öğe sınırı kalkar ve gelecek güncellemeler dahil.",
  'freeBannerCta': "Pro'yu al",
  'freeBannerDismiss': "Kapat",
  'payLoading': "Fiyatlar Google Play'den alınıyor…",
  'payUnavailable':
      "Google Play şu anda kullanılamıyor. İnternet bağlantını ve Play Store girişini kontrol et.",
  'payNoPlans': "Pro ürünü şu an yüklenemedi. Daha sonra tekrar dene.",
  'payRestore': 'Satın alımları geri yükle',
  'payManage': "Eski aboneliğini Google Play'de yönet",
  'payTerms':
      "Tek seferlik ödeme; abonelik yok, otomatik yenileme yok, ücretsiz deneme yok. Ücret Google Play hesabından alınır. Daha önce abone olduysan Pro'n aboneliğin süresince devam eder.",
  'payActive': 'Pro etkin. Teşekkürler!',
  'payPurchased': 'Pro etkinleştirildi. Teşekkürler!',
  'payPending': 'Ödeme bekleniyor. Onaylanınca Pro açılır.',
  'payCanceled': 'Satın alma iptal edildi.',
  'payError': 'Satın alma tamamlanamadı. Tekrar dene.',
  'payRestored': 'Pro geri yüklendi.',
  'payNothing': "Bu Google hesabında Pro satın alımı bulunamadı.",
  'payOffline': "Google Play'e ulaşılamadı. Bağlantını kontrol et.",
  'notNow': 'Şimdi değil',
  'proSeePlans': "Pro'yu gör",
  'limitTitle': 'Ücretsiz sınır doldu',
  'limitBody':
      "Ücretsiz sürümde en fazla {max} öğe (fotoğraf, dosya, not) saklanır. Mevcut öğelerin kilitlenmez ve silinmez. Sınırı kaldırmak için Pro'yu bir kez satın al.",
  'spProTitle': 'İkinci telefon Pro ile kurulur',
  'spProBody':
      "İkinci telefon bir Pro özelliğidir. Pro'yu tek seferlik ödemeyle bir kez satın al; abonelik yok.",
  'supportEmail': 'Destek',
  'copyEmail': 'E-postayı kopyala',
  'emailCopied': 'E-posta adresi kopyalandı',
  'privacyPolicy': 'Gizlilik politikası',
  'originalsDeletedN': '{n} orijinal silindi.',
  'originalsKeptN': '{n} orijinal silinemedi; kasadaki kopya güvende.',
  'originalsDeclined':
      'Orijinaller silinmedi (onay verilmedi); kasadaki kopya güvende.',
  'calcInfoTitle': 'Bu hesap makinesi hakkında',
  'calcInfoBody':
      'Bu gerçek bir hesap makinesidir ve aynı zamanda GizliAlan kasanın '
      'girişidir (uygulama listesinde "Hesap Makinesi" adıyla görünür): kasa '
      'PIN\'ini yazıp "=" tuşuna basarak kasayı açarsın. Biyometrik açıksa '
      '"=" tuşuna uzun bas. Hesap makinesi girişini kasa ayarlarından '
      'kapatabilirsin.',
  // Lock
  'unlock': 'PIN gir',
  'wrongPin': 'Yanlış PIN',
  'lockedOut': 'Çok fazla deneme. {s} sn sonra tekrar dene.',
  'lockedOutShort': 'Çok fazla deneme. Daha sonra tekrar dene.',
  'useBiometric': 'Biyometrik kullan',
  'biometricReason': 'GizliAlan kasasının kilidini aç',
  'biometricEnableReason': 'Biyometrik kilidi açmak için onayla',
  // Home
  'gallery': 'Galeri',
  'notes': 'Notlar',
  'files': 'Dosyalar',
  'settings': 'Ayarlar',
  'lock': 'Kilitle',
  // Gallery / files
  'importPhotos': 'Fotoğraf ekle',
  'importFile': 'Dosya ekle',
  'importing': 'Şifreleniyor…',
  'importedN':
      '{n} fotoğraf kasaya şifrelenerek eklendi. Orijinaller telefonunun '
      'galerisinde duruyor — istersen oradan sil.',
  'importedFilesN':
      '{n} dosya kasaya şifrelenerek eklendi. Orijinaller değiştirilmedi.',
  'tooBig': '100 MB\'tan büyük bazı dosyalar atlandı.',
  'emptyGallery':
      'Henüz fotoğraf yok.\n"Fotoğraf ekle"ye dokun — bu cihazda şifrelenir.',
  'emptyFiles':
      'Henüz dosya yok.\nPDF veya belge ekle — bu cihazda şifreli kalır.',
  'view': 'Görüntüle',
  'export': 'Dışa aktar',
  'exported': 'Dışa aktarıldı (şifresiz kopya seçtiğin yere kaydedildi)',
  'exportFailed': 'Dışa aktarma başarısız',
  'delete': 'Sil',
  'deleteItemConfirm':
      'Bu öğe çöp kutusuna taşınsın mı? 30 gün sonra kalıcı olarak silinir.',
  // Notes
  'newNote': 'Yeni not',
  'editNote': 'Notu düzenle',
  'untitled': 'Başlıksız',
  'noteTitle': 'Başlık',
  'noteBody': 'Not',
  'save': 'Kaydet',
  'search': 'Ara',
  'emptyNotes': 'Henüz not yok.\nİlk özel notun bu cihazda şifreli kalır.',
  'deleteNoteConfirm':
      'Bu not çöp kutusuna taşınsın mı? 30 gün sonra kalıcı olarak silinir.',
  // Settings
  'security': 'Güvenlik',
  'changePin': 'PIN değiştir',
  'currentPin': 'Mevcut PIN',
  'newPin': 'Yeni PIN',
  'wrongCurrentPin': 'Mevcut PIN yanlış',
  'pinSaved': 'PIN kaydedildi',
  'pinMustDiffer': 'Gerçek PIN ile sahte PIN farklı olmalı',
  'biometric': 'Biyometrik kilit açma',
  'biometricHint': 'Parmak izi/yüz gerçek kasayı açar (sahte kasayı asla)',
  'biometricUnavailable': 'Bu cihazda kayıtlı biyometrik yok',
  'decoyPin': 'Sahte PIN (isteğe bağlı)',
  'decoyPinOn': 'Açık — sahte PIN ayrı, boş bir kasa açar',
  'decoyPinOff': 'Kapalı',
  'decoyPinExplain':
      'Sahte PIN, boş başlayan ve kendi şifreleme anahtarı olan ayrı ikinci '
      'bir kasa açar. Gerçek kasan orada görünmez. Gerçek PIN\'inden farklı '
      'olmalıdır. Bu özellik mağaza açıklamasında belirtilir.',
  'decoyRemove': 'Sahte PIN\'i kaldır',
  'decoyRemoveConfirm':
      'Sahte PIN kaldırılsın ve sahte kasadaki her şey silinsin mi?',
  'screenSecurity': 'Ekran koruması',
  'screenSecurityHint':
      'Her zaman açık: ekran görüntüsü, ekran kaydı ve son uygulamalar önizlemesi engellenir (FLAG_SECURE)',
  'entry': 'Giriş',
  'general': 'Genel',
  'lockTimeout': 'Kilit süresi',
  'lockTimeoutHint':
      'Uygulamadan çıkınca veya ekran kapanınca kasa bu sürede kilitlenir. Süre bitmeden dönersen PIN istenmez.',
  'lockImmediately': 'Hemen',
  'lockAfter30': '30 saniye',
  'lockAfter60': '1 dakika',
  'lockAfterSec': '{n} sn sonra',
  'lockAfterMin': '{n} dk sonra',
  'analyticsToggle': 'Anonim istatistik ve reklam ölçümü',
  'analyticsToggleHint':
      "Uygulama açılışı, kurulum ve Pro satın alma olayları AppMetrica (Yandex) ve TikTok'a anonim olarak gönderilir. Kasa içeriği asla gönderilmez.",
  'analyticsPrivacyNotice':
      "GizliAlan, hizmetini geliştirmek için anonim kullanım verileri toplayabilir. Bu veriler; uygulama açılışları, ekran görüntülenme sayıları ve temel cihaz bilgilerini içerir ve kimliğinizi açığa çıkarmaz. Veriler AppMetrica ve TikTok analitik servisleri aracılığıyla işlenir. İstediğiniz zaman ayarlardan bu paylaşımı kapatabilirsiniz.",
  'language': 'Dil',
  'wallpaper': 'Duvar kağıdı',
  'homeBackground': 'Ana ekran arka planı',
  'homeBackgroundDefault':
      'Varsayılan (aşağıdaki görsel veya renk). Fotoğraf kullanmak için: Galeri → fotoğrafa uzun bas → "Ana ekran arka planı yap".',
  'homeBackgroundPhoto':
      'Kasadaki bir fotoğraf. Kaldırınca aşağıdaki varsayılana dönülür.',
  'wallpaperDefaultImage': 'Varsayılan görsel',
  'wallpaperPlain': 'Düz renk',
  'homeBackgroundRemove': 'Arka planı kaldır',
  'homeBackgroundSet':
      'Kasa ana ekranı arka planı yapıldı. Fotoğraf kasada şifreli kalır.',
  'setAsHomeBackground': 'Ana ekran arka planı yap',
  'open': 'Aç',
  'browser': 'Tarayıcı',
  'browserHint': 'Ara veya web adresi yaz',
  'browserSearchWith':
      'Aramalar {engine} ile yapılır. Yazarken arama önerisi gönderilmez.',
  'browserPrivacyNote':
      'Kasa içinde gizli tarayıcı; izleme ve reklam yok. Kasa kilitlenince çerezler ve geçmiş silinir, indirilenler şifreli kasaya gider.',
  'browserBack': 'Geri',
  'browserForward': 'İleri',
  'browserReload': 'Yenile',
  'browserBlockedLink':
      'Bu tür bağlantılar (uygulama, telefon, e-posta, dosya…) kasa tarayıcısından açılmaz.',
  'browserSaveImage': 'Resmi kasaya kaydet',
  'browserDownloading': 'Kasaya indiriliyor…',
  'browserSavedPhotos': 'Kasadaki Galeri\'ye kaydedildi: {name}',
  'browserSavedFiles': 'Kasadaki Dosyalar\'a kaydedildi: {name}',
  'browserDlTooLarge': 'Kaydetmek için çok büyük (en fazla {mb} MB).',
  'browserDlNotImage': 'Bu bir resim değil.',
  'browserDlUnsupported': 'Bu indirme kaydedilemez (desteklenmeyen bağlantı).',
  'browserDlFailed': 'İndirme başarısız.',
  'browserEngine': 'Arama motoru',
  'browserWipeOnLock': 'Kilitlenince temizle',
  'browserWipeOnLockHint':
      'Kasa her kilitlendiğinde tarayıcı çerezlerini, önbelleğini ve site verilerini sil.',
  'browserWipeNow': 'Tarayıcı verilerini şimdi temizle',
  'browserWiped': 'Tarayıcı verileri temizlendi.',
  'privacyTitle': 'Gizlilik ve izinler',
  'privacyBody':
      '• Tüm kasa içeriği (fotoğraf, dosya, not) Android Keystore destekli '
      'güvenli depoda tutulan bir anahtarla AES-256-GCM ile şifrelenir.\n'
      '• PIN\'in yalnızca tuzlanmış PBKDF2 özeti olarak saklanır.\n'
      '• Hesap, reklam gösterimi ve bize ait sunucu yok. Kasa içeriği, dosya '
      'adları ve PIN asla cihazdan çıkmaz. Yalnızca anonim uygulama açılışı, '
      'kurulum ve Pro satın alma olayları (cihaz/reklam kimliği, cihaz modeli, '
      'Android ve uygulama sürümü) reklam ölçümü için AppMetrica (Yandex) ve '
      'TikTok\'a gönderilir; Ayarlar → "Anonim istatistik ve reklam ölçümü" ile '
      'kapatılabilir. Dahili gizli tarayıcı yalnızca açtığın siteyle konuşur.\n'
      '• İzinler: biyometrik (isteğe bağlı kilit açma) ve internet (tarayıcı '
      've istatistik). Fotoğraf ve '
      'dosyaları sistem seçicileriyle sen seçersin — depolama/medya izni '
      'yok.\n'
      '• SMS, arama, rehber, konum, mikrofon, kamera, Erişilebilirlik veya '
      'ana cihaz yöneticisi yok. İsteğe bağlı İkinci telefon yalnızca senin '
      'oluşturduğun iş profilinin profil sahibidir.\n'
      '• Uygulama yedeği kapalıdır; kasa verisi buluta kopyalanmaz. '
      'Kaldırma veya "Verileri temizle" kasayı siler.',
  'dangerZone': 'Tehlikeli alan',
  'wipeVault': 'Her şeyi sıfırla',
  'wipeHint': 'Tüm kasaları, PIN\'leri ve anahtarları siler',
  'wipeConfirm':
      'Tüm kasalardaki fotoğraf, dosya ve notlar ile PIN ve anahtarların '
      'kalıcı olarak silinecek. Devam edilsin mi?',
  'cancel': 'İptal',
  'ok': 'Tamam',
  // Second phone (work profile)
  'secondPhone': 'İkinci telefon',
  'secondPhoneApps': 'İkinci telefon uygulamaları',
  'spIntro':
      'İkinci telefon, Android\'in kendi "iş profili" özelliğiyle bu cihazda ayrı bir alan oluşturur (Shelter/Island ile aynı yöntem). İçinde kendi Play Store\'u vardır; oraya ayrı bir Google hesabı ekleyip uygulama kurabilirsin. Uygulamalar, hesaplar ve dosyalar ana telefonundan ayrı tutulur.',
  'spDisclosure':
      'Nasıl çalışır: GizliAlan yalnızca kendi oluşturduğu bu iş profilinin "profil sahibi" olur. Ana profilin veya cihazın yöneticisi olmaz; hiçbir şeyi izlemez, başka uygulamaların verisini okumaz, hiçbir yere bir şey göndermez. Android kurulumda kendi bilgilendirmesini gösterir. Profildeki uygulamalar çanta rozetiyle, telefonun uygulama listesindeki "İş" sekmesinde de görünür. Kurulum ve yönetim yalnızca kasa açıkken yapılabilir.',
  'spSetUp': 'İkinci telefonu kur',
  'spSetUpConfirm':
      'Devam etmeden önce: Android bu telefonda ayrı bir iş profili oluşturacak (Android\'in cihaz yönetimi API\'si kullanılır; Android bunu iş profili olarak gösterir). GizliAlan yalnızca bu yeni profilin profil sahibi olur; ana profilin veya cihazın yöneticisi değildir ve şifre, kilit, silme gibi hiçbir yönetici politikası istemez. İş profilinin içinde GizliAlan\'ın kendi simgesi görünmez. "Kilitliyken iş uygulamalarını gizle" açıksa (varsayılan) kasa kilitliyken iş profilindeki uygulamalar ana ekranından gizlenir; hiçbir şey kaldırılmaz ve bunu bu ekrandan kapatabilirsin. Her şeyi "İkinci telefonu kaldır" ile veya Android Ayarlar > Hesaplar > İş profili yolundan kaldırabilirsin. Android şimdi kendi bilgilendirmelerini gösterecek. Devam edilsin mi?',
  'spCreated':
      'İkinci telefon hazır. Play Store\'u açıp ikinci Google hesabını ekleyebilirsin.',
  'spCreatedPending':
      'Kurulum tamamlandı; Android profili hazırlıyor. Birkaç saniye sonra tekrar kontrol et.',
  'spCanceled': 'Kurulum iptal edildi veya tamamlanamadı.',
  'spXiaomiWarn':
      "Bilgi: Xiaomi / Redmi / POCO (MIUI/HyperOS) cihazların çoğunda kurulum sorunsuz çalışır (ör. Redmi, MIUI 12.5.7'de test edildi). Bazı modellerde üretici iş profilini kısıtlayabilir; öyle olursa telefonun kendi \"İkinci alan\" özelliğini kullanabilirsin (Ayarlar → Özel özellikler → İkinci alan).",
  'spXiaomiBlocked':
      'Bu Xiaomi/Redmi/POCO cihaz (MIUI/HyperOS) iş profili oluşturmaya izin vermiyor. Alternatif: telefonun yerleşik "İkinci alan" özelliği (Ayarlar → Özel özellikler → İkinci alan) ya da Android 15+ ise "Özel alan" (Ayarlar → Güvenlik ve gizlilik → Özel alan).',
  'spNotAllowed':
      'Bu cihazda şu anda iş profili oluşturulamıyor. Genelde zaten bir iş profili (ör. şirket hesabı) olduğu ya da üretici bu özelliği kapattığı için olur. Alternatif: Android 15+ "Özel alan" veya üreticinin ikinci alan / güvenli klasör özelliği.',
  'spUnsupported':
      'Bu cihaz Android iş profillerini desteklemiyor. Alternatif: Android 15+ "Özel alan" veya üreticinin özelliği (Samsung Güvenli Klasör, Xiaomi İkinci Alan).',
  'spPrivateSpaceHint':
      'Bu telefon Android 15 veya üstü: "Özel alan" (Ayarlar → Güvenlik ve gizlilik → Özel alan) da işletim sistemi düzeyinde ayrı bir alan sunar.',
  'spUnlinked':
      'Bu cihazda GizliAlan içeren bir iş profili var ama bu kasaya bağlı değil (uygulama verisi silinmiş olabilir). Kaldırmak için: Android Ayarlar → Hesaplar (veya Parolalar ve hesaplar) → İş → İş profilini kaldır. Sonra yeniden kurabilirsin.',
  'spStatus': 'Durum',
  'spStatusOpen': 'Açık',
  'spStatusFrozen': 'Kapalı — uygulamalar gizli',
  'spStatusQuiet': 'Kapalı — uygulamalar gizli, iş profili duraklatıldı',
  'spOpenStore': 'Play Store\'u aç (ikinci hesap)',
  'spAddApp': 'Ana telefondan uygulama ekle',
  'spAddAppHint':
      'Sistem uygulamaları doğrudan kopyalanır; diğerleri için ikinci telefonun Play Store sayfası açılır.',
  'spCloseNow': 'İkinci telefonu şimdi kapat',
  'spOpenNow': 'İkinci telefonu aç',
  'spRemove': 'İkinci telefonu kaldır',
  'spRemoveConfirm':
      'İş profili ve içindeki TÜM uygulamalar, hesaplar ve dosyalar kalıcı olarak silinecek. Devam edilsin mi?',
  'spRemoved': 'İkinci telefon kaldırıldı.',
  'spCloneOk': '"{app}" ikinci telefona eklendi.',
  'spCloneStore':
      'Android bu uygulamanın doğrudan kopyalanmasına izin vermiyor. İkinci telefonun Play Store sayfası açıldı; oradan kur (önce ikinci hesabı ekle).',
  'spCloneFailed':
      'Uygulama eklenemedi. İkinci telefonun Play Store\'undan kurabilirsin.',
  'spNoApps':
      'İkinci telefonda henüz uygulama yok. Play Store\'dan kur veya ana telefondan ekle.',
  'spNoCandidates': 'Eklenebilecek uygulama bulunamadı.',
  'spFailed': 'İşlem tamamlanamadı ({s}).',
  'spClosed': 'İkinci telefon kapatıldı.',
  'spOpened': 'İkinci telefon açıldı.',
  'spQuietFallback':
      'Uygulamalar gizlendi. Android iş profilini duraklatmaya izin vermedi.',
  'spHideWhenLocked': 'Kilitliyken iş uygulamalarını gizle',
  'spHideWhenLockedHint':
      'Kasa kilitliyken ikinci telefondaki uygulamalar telefonun ana ekranından, "İş" klasöründen ve uygulama listesinden kaldırılır. Hiçbir şey silinmez, verileri durur. Gerçek PIN veya parmak izinle açınca geri gelir. Gizliyken bu uygulamalar çalışmaz ve bildirim almaz.',
  'spHideWhenLockedWhen':
      'Kilitle düğmesine basınca hemen gizlenir. Arka planda otomatik kilitlenirse Android GizliAlan\'ın işlem yapmasına izin vermez; uygulamalar GizliAlan kilitliyken bir sonraki açılışta (başlatma veya geri dönüş) gizlenir. Görünür kalanlar: GizliAlan ve profili yönetmek için gereken Google Play hizmetleri / yükleyici / ayar bileşenleri.',
  'spWorkGuideTitle': 'İş sekmesini de gizle',
  'spWorkGuideBody':
      'Kasa kilitliyken GizliAlan iş uygulamalarını gizler. Başlatıcıdaki İş sekmesini kendin de kapatmak veya duraklatmak için sonraki adımda sistem ayarları açılır. Orada şunu kapat:\n\n• İş profili / İş uygulamaları: "İş uygulamaları" anahtarını kapat (iş profilini duraklat)\n• Xiaomi / POCO başlatıcı: Ana ekran ayarları → "İş uygulamalarını göster" kapat\n• Aksi halde: Ayarlar → Hesaplar → İş profili → Duraklat\n\nGerektiğinde aynı yerden (veya İş sekmesinden) tekrar aç.',
  'spWorkGuideOpen': 'Ayarları aç',
  'spWorkGuideLater': 'Şimdi değil',
  'spWorkGuideReopen': 'Ayarları tekrar aç',
  'spWorkGuideFailed':
      'Ayarlar açılamadı. Ayarlar → Hesaplar → İş profili yolunu elle aç.',
  'spPauseToo': 'Ayrıca iş profilini duraklatmayı dene',
  'spPauseTooHint':
      'Android iş profilini duraklatmaya çoğu telefonda yalnızca varsayılan ana ekran uygulamasına izin verir; bu yüzden çoğu zaman yalnızca gizleme uygulanır. Duraklatılmış profilin simgeleri bazı ana ekranlarda (ör. Xiaomi) gri olarak görünmeye devam eder — simgeleri kaldıran gizlemedir. Hızlı ayarlardaki "İş uygulamaları" düğmesini de kullanabilirsin.',
  'notifications': 'Bildirimler',
  'notifEmpty':
      'Henüz bildirim yok. İçe/dışa aktarma, silme, İkinci telefon değişiklikleri ve hatalı PIN denemeleri burada listelenir.',
  'notifFooter':
      'Bu liste yalnızca kasanın içinde görünür ve şifreli saklanır. GizliAlan sistem bildirimi göndermez, başka uygulamaların bildirimlerini okumaz.',
  'notifMarkAllRead': 'Tümünü okundu say',
  'notifClearAll': 'Tümünü temizle',
  'notifClearConfirm': 'Bu kasadaki tüm bildirimler silinsin mi?',
  'evGalleryImported': 'Galeriye {n} fotoğraf eklendi',
  'evFilesImported': 'Dosyalara {n} dosya eklendi',
  'evItemExported': '"{name}" dışa aktarıldı',
  'evItemDeleted': '"{name}" silindi',
  'evFailedUnlocks': 'Son girişinden beri {n} hatalı PIN denemesi',
  'evSecondPhoneCreated': 'İkinci telefon oluşturuldu',
  'evSecondPhoneAppAdded': 'İkinci telefona "{app}" eklendi',
  'evSecondPhoneRemoved': 'İkinci telefon kaldırıldı',
  'proTitle': 'GizliAlan Pro',
  'proSettingsHint': "Pro'yu satın al veya geri yükle",
  'proSettingsHintStub':
      'Planlar ve fiyatlar (bu test sürümünde satın alma yok)',
  'proTestBuildNote':
      'Bu bir test sürümüdür: satın alma yoktur, ödeme alınmaz. Fiyatlar planlanan fiyatlardır.',
  'proFree': 'Ücretsiz',
  'proFreePrice': '0 TL',
  'proFreeF1': '{max} öğeye kadar',
  'proFreeF2': 'Reklam yok',
  'proFreeF3': 'Tüm veriler cihazda şifreli',
  'proUsage': 'Kullanım: {n} / {max} öğe',
  'proCurrent': 'Mevcut',
  'proLifetime': 'Pro — tek seferlik',
  'proLifetimePrice': '499 TL',
  'proF1': 'İkinci telefon',
  'proF2': 'Sınırsız öğe',
  'proF3': 'ⓘ simgesini gizleme',
  'proBuyOnce': 'Bir kez satın al',
  'proNotAvailableTitle': 'Henüz mevcut değil',
  'proNotAvailableBody':
      'Bu test sürümünde satın alma yoktur ve hiçbir ödeme alınmaz. Pro, ileride Google Play üzerinden sunulabilir.',
  'proFooter':
      "GizliAlan hesap istemez; kasa içeriğin hiçbir sunucuya gönderilmez. Uygulama Gumroad vb. yerlerde satılmaz.",
  // `play` flavor variants (no Second phone in that build), see L10n.t.
  'onboardingPrivacy_play':
      "İzleme aracı değildir. GizliAlan SMS, arama, rehber veya konum okumaz; Erişilebilirlik Hizmeti kullanmaz, telefonunun cihaz yöneticisi olmaz ve kendi sunucusu yoktur. Kasa içeriğin, dosya adların ve PIN'in asla cihazdan çıkmaz. Yalnızca anonim uygulama açılışı, kurulum ve Pro satın alma olayları reklam ölçümü için AppMetrica (Yandex) ve TikTok'a gider; Ayarlar → \"Anonim istatistik ve reklam ölçümü\" ile kapatabilirsin. Yalnızca kendi cihazında, kendi içeriğin için kullan.",
  'privacyBody_play':
      '• Tüm kasa içeriği (fotoğraf, dosya, not) Android Keystore destekli '
      'güvenli depoda tutulan bir anahtarla AES-256-GCM ile şifrelenir.\n'
      '• PIN\'in yalnızca tuzlanmış PBKDF2 özeti olarak saklanır.\n'
      '• Hesap, reklam gösterimi ve bize ait sunucu yok. Kasa içeriği, dosya '
      'adları ve PIN asla cihazdan çıkmaz. Yalnızca anonim uygulama açılışı, '
      'kurulum ve Pro satın alma olayları (cihaz/reklam kimliği, cihaz modeli, '
      'Android ve uygulama sürümü) reklam ölçümü için AppMetrica (Yandex) ve '
      'TikTok\'a gönderilir; Ayarlar → "Anonim istatistik ve reklam ölçümü" ile '
      'kapatılabilir. Dahili gizli tarayıcı yalnızca açtığın siteyle konuşur.\n'
      '• İzinler: biyometrik (isteğe bağlı kilit açma) ve internet (tarayıcı '
      've istatistik). Fotoğraf ve '
      'dosyaları sistem seçicileriyle sen seçersin — depolama/medya izni '
      'yok.\n'
      '• SMS, arama, rehber, konum, mikrofon, kamera, Erişilebilirlik veya '
      'cihaz yöneticisi yok.\n'
      '• Uygulama yedeği kapalıdır; kasa verisi buluta kopyalanmaz. '
      'Kaldırma veya "Verileri temizle" kasayı siler.',
  'notifEmpty_play':
      'Henüz bildirim yok. İçe/dışa aktarma, silme ve hatalı PIN denemeleri burada listelenir.',
  // Privacy policy link (#28), shown only when PRIVACY_URL is set.
  'privacyPolicyOnline': 'Gizlilik politikasının tamamı (çevrimiçi):',
  'openInBrowser': 'Tarayıcıda aç',
  'copyLink': 'Bağlantıyı kopyala',
  'linkCopied': 'Bağlantı kopyalandı',
  'noBrowser': 'Tarayıcı bulunamadı. Bunun yerine bağlantı kopyalandı.',
  // v0.5.1: appearance, help, share / rate / feedback (tester feedback)
  // v0.5.2: accent colour (tester feedback)
  'accentColor': 'Vurgu rengi',
  'accent_mint': 'Nane',
  'accent_blue': 'Mavi',
  'accent_purple': 'Mor',
  'accent_orange': 'Turuncu',
  'accent_pink': 'Pembe',
  'appearance': 'Görünüm',
  'themeSystem': 'Sistem',
  'themeLight': 'Açık',
  'themeDark': 'Koyu',
  'appearanceHint': 'Hesap makinesi ve kasa ekranları için tema',
  'helpFeedback': 'Yardım ve geri bildirim',
  'helpTitle': 'Yardım: nasıl kullanılır?',
  'helpHint':
      'Hesap makinesi girişi, görünüm, paylaş / değerlendir / geri bildirim, sahte PIN, kasa',
  'helpCalcTitle': 'Hesap makinesi girişi',
  'helpCalcBody':
      'Uygulama, telefonunun uygulama listesinde "Hesap Makinesi" adıyla görünür ve gerçek, çalışan bir hesap makinesi olarak açılır. Kasayı açmak için PIN\'ini yazıp "=" tuşuna bas. Biyometrik kilit açma etkinse "=" tuşuna uzun basman yeterli. PIN olmayan bir sayı yazarsan normal hesaplama yapılır. Bu girişi Ayarlar → Giriş bölümünden kapatabilirsin; o zaman uygulama doğrudan PIN ekranıyla açılır.',
  'helpDecoyTitle': 'Sahte PIN',
  'helpDecoyBody':
      'İstersen Ayarlar → Güvenlik bölümünden ikinci bir PIN belirleyebilirsin. Sahte PIN, boş başlayan ve kendi şifreleme anahtarı olan ayrı bir kasa açar; gerçek kasan ve içeriği orada görünmez. Sahte PIN gerçek PIN\'inden farklı olmalıdır. Biyometrik kilit açma her zaman yalnızca gerçek kasayı açar.',
  'helpVaultTitle': 'Kasa',
  'helpVaultBody':
      'Kasada fotoğrafları, notları ve dosyaları (video ve belgeler dahil) saklayabilir, özel tarayıcıyı kullanabilirsin. Tüm içerik bu cihazda AES-256-GCM ile şifrelenir; hesap, bulut ve sunucu yoktur. Ekran görüntüsü, ekran kaydı ve son uygulamalar önizlemesi engellenir. Geri tuşu klasör ve görüntüleyiciden bir önceki ekrana döner; kasadan çıkarmaz. Uygulamadan çıkınca veya ekran kapanınca kasa kilitlenir; süreyi Ayarlar → Kilit süresi ile değiştirebilirsin (Hemen, 30 saniye veya 1 dakika).',
  'helpPinTitle': 'PIN\'imi unutursam?',
  'helpPinBody':
      'PIN kurtarma yoktur: PIN\'in hiçbir yere gönderilmez ve içerik yalnızca bu cihazda çözülebilir. PIN\'ini unutursan kasa içeriği açılamaz; yalnızca uygulamayı tamamen sıfırlamak (veya silip yeniden kurmak) mümkündür.',
  'helpSecondPhoneTitle': 'İkinci telefon (iş profili)',
  'helpSecondPhoneBody':
      'İkinci telefon, Android\'in kendi iş profili özelliğiyle bu cihazda ayrı bir alan oluşturur. İçinde kendi Play Store\'u vardır; ayrı bir Google hesabı ve ayrı uygulamalar kullanabilirsin. Kurulum ve yönetim yalnızca gerçek kasa açıkken yapılır. İstersen kasa kilitliyken iş uygulamaları gizlenir ve kilidi açınca geri gelir. GizliAlan yalnızca kendi oluşturduğu iş profilini yönetir; ana telefonunu izlemez ve hiçbir yere veri göndermez.',
  'helpSecondPhonePro': 'İkinci telefonu kurmak Pro özelliğidir.',
  // v0.5.3: görünüm + paylaş/değerlendir/geri bildirim yardım bölümleri
  'helpAppearanceTitle': 'Görünüm',
  'helpAppearanceBody':
      'Ayarlar → Görünüm bölümünden Sistem, Açık veya Koyu temayı seçebilirsin. Vurgu rengi altında nane, mavi, mor, turuncu veya pembe seçebilirsin. Tema ve vurgu rengi yalnızca bu cihazda saklanır; hiçbir yere gönderilmez.',
  'helpShareTitle': 'Paylaş, değerlendir ve geri bildirim',
  'helpShareBody':
      'Ayarlar → Yardım ve geri bildirim altında: Uygulamayı paylaş, kısa ve nötr bir metin ile Google Play bağlantısını gönderir (önce giriş cümlesini düzenleyebilirsin). Uygulamayı değerlendir Play sayfasını açar. Geri bildirim gönder, e-posta uygulamanı konu satırında kategoriyle açar; isteğe bağlı olarak ne olduğunu ve ne beklediğini yazabilirsin. Cihaz kimliği, günlük veya kasa verisi otomatik eklenmez.',
  'shareApp': 'Uygulamayı paylaş',
  'shareAppHint': 'Google Play bağlantısını bir arkadaşına gönder',
  // Neutral on purpose: never mention the vault in shared text.
  'shareAppText': 'Bu uygulamaya bir göz at:',
  'shareIntroTitle': 'Paylaşım metni',
  'shareIntroHint': 'Nötr tut — kasa, PIN veya gizli özelliklerden bahsetme.',
  'shareAppFailed': 'Paylaşılamadı. Bunun yerine bağlantı kopyalandı.',
  'rateApp': 'Uygulamayı değerlendir',
  'rateAppHint': 'Google Play\'de puan ver veya yorum yaz',
  'rateAppFailed': 'Google Play açılamadı. Bunun yerine bağlantı kopyalandı.',
  'feedback': 'Geri bildirim gönder',
  'feedbackHint': 'Öneri veya hata bildirimi için e-posta',
  'feedbackSubject': 'GizliAlan geri bildirim',
  'feedbackCategoryTitle': 'Konu nedir?',
  'feedbackCatBug': 'Hata',
  'feedbackCatSuggestion': 'Öneri',
  'feedbackCatOther': 'Diğer',
  'feedbackBodyTitle': 'İsteğe bağlı ayrıntılar',
  'feedbackBodyWhat': 'Ne oldu',
  'feedbackBodyExpected': 'Ne bekliyordun',
  'feedbackBodySkip': 'Atla',
  'feedbackFailed':
      'E-posta uygulaması bulunamadı. Bunun yerine adres kopyalandı.',
  // 0.6.2: note reminders + Joi
  "remindShowAt": "Şu tarihte göster",
  "remindNone": "Hatırlatma yok — kasa açıkken uygulama içinde gösterilir",
  "remindClear": "Hatırlatmayı kaldır",
  "remindDismiss": "Kapat",
  "remindOpenNote": "Notu aç",
  "joiIntro":
      "Merhaba, ben Joi — GizliAlan'ın cihaz içi asistanı. Bana her şeyi sorabilirsin (ör. \"Aristoteles kim?\"), notlarını özetleyebilir ve notlarınla ilgili soruları yanıtlayabilirim. Hiçbir şey cihazından çıkmaz.",
  "joiIntroSearch":
      "Joi bu cihazda notlarında anahtar kelimeyle arama yapabilir. Aramak istediğin kelimeyi yaz.",
  "joiNoMatch": "Notlarında bununla eşleşen bir şey bulamadım.",
  "joiFoundNotes": "Notlarında bunları buldum:",
  "joiError": "Şu an yanıt veremedim. Biraz sonra tekrar dene.",
  "joiSummarizeAsk": "\"{title}\" notunu özetle",
  "joiSummarize": "Notu özetle",
  "joiAskNotes": "Notlarıma sor",
  "joiHint": "Joi'ye yaz…",
  "joiHintSearch": "Notlarında ara…",
  "joiSend": "Gönder",
  "joiDownloadable":
      "Joi'nin cihaz içi modeli (Gemini Nano) bu telefonda kullanılabilir ama henüz indirilmemiş. İndirmeyi Android sistemi (AICore) yapar; notların ve soruların gönderilmez.",
  "joiDownloading":
      "Gemini Nano Android sistemi tarafından indiriliyor. Bu sırada notlarında arama yapabilirsin.",
  "joiDownload": "Modeli indir",
  "joiUnavailable":
      "Joi'nin cihaz içi yapay zekâsı (Gemini Nano) bu cihazda desteklenmiyor. Burada notlarında sadece anahtar kelime araması yapabilir.",
  "joiOnlineNote":
      "Bu telefonda genel soruların (ör. \"Aristoteles kim?\") onayınla internet üzerinden Google Gemini'ye gönderilerek yanıtlanır. Not özetleme ve \"Notlarıma sor\" yalnızca cihaz içinde çalışır; notların asla gönderilmez — burada notlarında anahtar kelimeyle arama yapılır.",
  "joiIntroOnline":
      "Merhaba, ben Joi. Bana genel sorular sorabilirsin (ör. \"Aristoteles kim?\"); yanıtlar çevrimiçi olarak Google Gemini'den gelir. Notların asla gönderilmez; notlarında aramak için \"Notlarımda ara\"yı seç.",
  "joiSearchNotes": "Notlarımda ara",
  "joiConsentTitle": "Joi çevrimiçi yanıt versin mi?",
  "joiConsentBody":
      "Bu telefonda Joi'nin cihaz içi modeli yok. İzin verirsen yazdığın genel sorular internet üzerinden Google'a (Gemini, Firebase AI Logic) gönderilir ve yanıt oradan gelir.\n\n• Notların, dosyaların ve kasa içeriğin asla gönderilmez.\n• Sorularını biz saklamayız.\n• Bu izni istediğin zaman Ayarlar'dan geri alabilirsin.",
  "joiConsentAllow": "İzin ver",
  "joiConsentDeny": "Vazgeç",
  "joiNoConsent":
      "Çevrimiçi yanıt için izin verilmedi. Notlarında anahtar kelimeyle arama yapabilirsin; izni Ayarlar'dan açabilirsin.",
  "joiBusy": "Joi şu an yoğun (kota doldu). Biraz sonra tekrar dene.",
  "joiOffline":
      "İnternet yok gibi görünüyor. Bağlantını kontrol edip tekrar dene.",
  "joiBadgeOnline": "çevrimiçi",
  "joiBadgeDevice": "cihazda",
  "joiOnlineToggle": "Joi çevrimiçi yanıtlar",
  "joiOnlineToggleHint":
      "Gemini Nano olmayan telefonlarda genel sorular Google Gemini'ye gönderilir. Notlar asla gönderilmez.",
  "joiTimeout": "Joi zamanında yanıt alamadı. Tekrar dene.",
  "joiServer":
      "Google tarafında geçici bir sorun var. Biraz sonra tekrar dene.",
  "joiAuth":
      "Joi'nin çevrimiçi hizmetine erişim reddedildi (uygulama doğrulaması). Bu sürümde çevrimiçi yanıt kullanılamıyor.",
  "joiModelErr":
      "Joi'nin çevrimiçi modeli şu an kullanılamıyor. Uygulama güncellemesi gerekebilir.",
  "joiTileHint": "Asistanın — sor, sohbet et, notlarında ara",
  "joiImgNeedsOnline":
      "Fotoğraf aramak için çevrimiçi özelliklere izin vermen gerekiyor (Ayarlar → Joi çevrimiçi yanıtlar).",
  "joiImgNone":
      "\"{q}\" için Wikimedia Commons'ta serbest lisanslı fotoğraf bulamadım.",
  "joiImgFound":
      "\"{q}\" için Wikimedia Commons fotoğrafları. Kaydetmek için birine dokun:",
  "joiImgError": "Fotoğraf araması şu an yapılamadı. Biraz sonra tekrar dene.",
  "joiImgSavePictures": "Galeriye kaydet (Resimler/GizliAlan/Joi)",
  "joiImgSaveVault": "Kasaya kaydet",
  "joiImgSavedPictures": "Galeriye kaydedildi ✓ (Pictures/GizliAlan/Joi)",
  "joiImgSavedVault": "Kasana kaydedildi:",
  "joiImgCredit": "Yazar/lisans",
  "joiImgSaveFailed": "Fotoğraf kaydedilemedi.",
  "joiNoteNeedsAi":
      "Not yazmak için Joi'nin yapay zekâsı gerekiyor (cihazda Gemini Nano veya çevrimiçi yanıtlar). Kendi metnini kaydetmek için: \"not defterime şunu yaz: …\"",
  "joiNoteTitle": "Joi notu",
  "joiNoteFailed": "Not oluşturulamadı.",
  "joiNoteCreated": "Not defterine \"{title}\" notunu ekledim.",
  "joiOpenNote": "Notu aç",
  "joiMicTitle": "Mikrofon izni",
  "joiMicBody":
      "Joi'ye sesli soru sorabilmen için mikrofon izni gerekiyor. Ses, Android'in konuşma tanıma hizmetinde yazıya çevrilir; GizliAlan ses kaydı saklamaz.",
  "joiMicContinue": "Devam",
  "joiMicDenied":
      "Mikrofon izni verilmedi. Sesli soru için Android ayarlarından izin verebilirsin.",
  "joiMicError":
      "Ses anlaşılamadı ya da konuşma tanıma kullanılamıyor. Tekrar dene.",
  "joiMic": "Sesli sor",
  "joiStopSpeaking": "Okumayı durdur",
  "joiSpeakToggle": "Yanıtları sesli oku",
  "joiSpeakSetting": "Joi yanıtlarını sesli oku",
  "joiSpeakSettingHint":
      "Açıkken Joi yanıtlarını Türkçe okur. Sesli sorduğun sorular her zaman sesli yanıtlanır.",
  "joiClear": "Sohbeti temizle",
  "joiClearBody":
      "Joi ile olan sohbet geçmişi bu cihazdan silinecek. Notların etkilenmez.",
  "joiClearOk": "Temizle",
  "joiTry": "Şunları deneyebilirsin:",
  "joiEx1": "Sokrates'in hayatını not defterime özetle",
  "joiEx2": "Galata Kulesi'nin fotoğrafını indir",
  "joiEx3": "Not defterime hafta sonu için market listesi yaz",
  "joiEx4": "Bana bir motivasyon sözü söyle",
  "joiEx5": "Akşam yemeği için 3 kolay tarif öner",
  "joiEx6": "Kedilerin fotoğrafını bul",
  "joiExNotes": "Notlarımda şifre geçenleri bul",
  "resumeTitle": "Çıkınca bıraktığım yerden devam et",
  "resumeHint":
      "Kapalı (önerilen): uygulamadan çıkınca hesap makinesine döner. Açık: geri geldiğinde kasa aynı ekranda açık kalır (en fazla seçilen süre kadar; telefon yeniden başlarsa yine kilitlenir).",
  "resumeWarnTitle": "Emin misin?",
  "resumeWarnBody":
      "Telefonuna erişen biri kasayı açık bulabilir. Kasa, arka planda seçtiğin süreden (varsayılan 5 dakika) uzun kalınca yine kilitlenir.",
  "resumeWarnOk": "Aç",
  "resumeMax": "En fazla açık kalma süresi",
  "resumeMinutes": "{n} dk",
  "updTitle": "Yeni sürüm mevcut",
  "updBody":
      "GizliAlan'ın yeni bir sürümü ({v}) Google Play'de hazır. Güncelleme indirildikten sonra uygulama yeniden başlar.",
  "updUpdate": "Güncelle",
  "updLater": "Daha sonra",
  "updSeeNotes": "Play Store'da yenilikleri gör",
  "updReady": "Güncelleme indirildi. Yüklemek için yeniden başlat.",
  "updRestart": "Yeniden başlat",
  "updWhatsNew": "Bu sürümde yenilikler",
  "updOk": "Tamam",
  "joiProTitle": "Joi Pro'da",
  "joiProBody":
      "Ücretsiz sürümde Joi ile soru-cevap sohbeti yapabilirsin. Not yazma, fotoğraf indirme, sesli sohbet, notlarında arama/özet ve kalıcı sohbet geçmişi GizliAlan Pro ile açılır.",
  "joiProOnly":
      "{what} GizliAlan Pro'ya özel. Ücretsiz sürümde benimle soru-cevap sohbeti yapabilirsin.",
  "joiProPhotos": "Fotoğraf indirme",
  "joiProWrite": "Not defterine yazma",
  "joiProVoice": "Sesli sohbet",
  "joiProNotes": "Notlarında arama ve özet",
  "joiListening": "Dinliyorum… (bitince bırak ya da tekrar dokun)",
  "joiVoiceNoMatch":
      "Ses algılanmadı. Mikrofona biraz daha yakın ve net konuşup tekrar dene.",
  "joiVoiceOffline":
      "Konuşma tanıma için internet gerekiyor (cihazda Türkçe ses modeli yüklü değil). Bağlantını kontrol et.",
  "joiVoiceBusy": "Konuşma tanıma meşgul. Bir saniye sonra tekrar dene.",
  "joiVoiceLanguage":
      "Türkçe konuşma tanıma bu cihazda yok. Google uygulamasında / Ayarlar → Sistem → Diller → Konuşma tanıma'da Türkçe'yi indir.",
  "joiVoiceUnavailable":
      "Bu cihazda konuşma tanıma hizmeti bulunamadı. Google uygulamasını veya 'Google Konuşma Hizmetleri'ni yükleyip etkinleştir.",
  "joiImgSearching": "Wikimedia Commons'ta \"{q}\" fotoğraflarını arıyorum…",
  "joiImgNothing":
      "Wikimedia Commons'ta \"{q}\" için fotoğraf bulamadım. Farklı bir yazımla dene.",
  "joiImgOffline":
      "Fotoğraf araması için internete bağlanılamadı ya da Wikimedia yanıt vermedi. Tekrar dene.",
  "joiImgWhich": "Neyin fotoğrafını indireyim? Örneğin \"Hadise\" yaz.",
  "joiNoFakeAction":
      "Ben kendim bir şey indiremem ya da kaydedemem; bunu uygulama yapar. Fotoğraf için örneğin \"Hadise'nin fotoğrafını indir\" yaz, sonuçları burada gösteririm, dokununca galerine kaydedilir.",
  "joiImgSaveFirst": "İlkini galeriye kaydet",
};
