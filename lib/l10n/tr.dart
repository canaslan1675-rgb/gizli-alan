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
      'İzleme aracı değildir. GizliAlan SMS, arama, rehber veya konum okumaz; Erişilebilirlik Hizmeti kullanmaz, telefonunun cihaz yöneticisi olmaz ve hiçbir şey yüklemez — sunucu yoktur. (İsteğe bağlı "İkinci telefon" yalnızca senin oluşturduğun ayrı iş profilini yönetir.) Yalnızca kendi cihazında, kendi içeriğin için kullan.',
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
  'confirmPin': 'PIN Tekrar',
  'pinFormat': 'PIN 4–8 haneli rakam olmalı',
  'pinMismatch': 'PIN\'ler eşleşmiyor',
  'pinNoRecovery':
      'Önemli: PIN kurtarma yoktur. PIN\'ini unutursan kasa içeriği '
      'çözülemez; yalnızca tamamen sıfırlama mümkündür.',
  'finishSetup': 'Kasayı oluştur',
  'continue': 'Devam',
  'back': 'Geri',
  'dataSafetyShort':
      'Veriler bu cihazda, şifreli kalır. Hesap yok, bulut yok, reklam yok, analitik yok.',
  // Calculator
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
      '{n} fotoğraf kasaya şifrelenerek eklendi. Orijinaller telefon '
      'galerinde duruyor — istersen oradan sil.',
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
  'deleteItemConfirm': 'Bu öğe kasadan kalıcı olarak silinsin mi?',
  // Notes
  'newNote': 'Yeni not',
  'editNote': 'Notu düzenle',
  'untitled': 'Başlıksız',
  'noteTitle': 'Başlık',
  'noteBody': 'Not',
  'save': 'Kaydet',
  'search': 'Ara',
  'emptyNotes': 'Henüz not yok.\nİlk özel notun bu cihazda şifreli kalır.',
  'deleteNoteConfirm': 'Bu not silinsin mi?',
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
  'lockTimeout': 'Otomatik kilit',
  'lockTimeoutHint': 'Uygulama arka plana geçince kilitlenir',
  'lockImmediately': 'Hemen',
  'lockAfterSec': '{n} sn sonra',
  'lockAfterMin': '{n} dk sonra',
  'language': 'Dil',
  'wallpaper': 'Duvar kağıdı',
  'privacyTitle': 'Gizlilik ve izinler',
  'privacyBody':
      '• Tüm kasa içeriği (fotoğraf, dosya, not) Android Keystore destekli '
      'güvenli depoda tutulan bir anahtarla AES-256-GCM ile şifrelenir.\n'
      '• PIN\'in yalnızca tuzlanmış PBKDF2 özeti olarak saklanır.\n'
      '• Yayın sürümünde internet izni yok; hesap, analitik, reklam yok. Sen '
      'dışa aktarmadıkça hiçbir şey cihazdan çıkmaz.\n'
      '• İzinler: yalnızca biyometrik (isteğe bağlı kilit açma). Fotoğraf ve '
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
      'Nasıl çalışır: GizliAlan yalnızca kendi oluşturduğu bu iş profilinin "profil sahibi" olur. Ana profilin veya cihazın yöneticisi olmaz; hiçbir şeyi izlemez, başka uygulamaların verisini okumaz, hiçbir şey yüklemez. Android kurulumda kendi bilgilendirmesini gösterir. Profildeki uygulamalar çanta rozetiyle, telefonun uygulama listesindeki "İş" sekmesinde de görünür. Kurulum ve yönetim yalnızca kasa açıkken yapılabilir.',
  'spSetUp': 'İkinci telefonu kur',
  'spSetUpConfirm':
      'Android şimdi iş profili kurulumunu başlatacak. Birkaç dakika sürebilir ve sistem ekranları gösterilir. Devam edilsin mi?',
  'spCreated':
      'İkinci telefon hazır. Play Store\'u açıp ikinci Google hesabını ekleyebilirsin.',
  'spCreatedPending':
      'Kurulum tamamlandı; Android profili hazırlıyor. Birkaç saniye sonra tekrar kontrol et.',
  'spCanceled': 'Kurulum iptal edildi veya tamamlanamadı.',
  'spXiaomiWarn':
      'Xiaomi / Redmi / POCO (MIUI/HyperOS) cihazlarda iş profili kurulumu sıklıkla engellenir veya yarım kalır. Yine de deneyebilirsin; olmazsa telefonun kendi "İkinci alan" özelliğini kullan (Ayarlar → Özel özellikler → İkinci alan).',
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
  'spStatusQuiet': 'Kapalı — iş profili kapalı',
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
      'Android iş profilini kapatmaya izin vermedi; bunun yerine uygulamalar gizlendi.',
  'spCloseMode': 'Kilitleyince ikinci telefon',
  'spCloseModeHint':
      'Kilitle düğmesiyle kilitlerken uygulanır, kasa açılınca geri açılır. Arka planda otomatik kilitte uygulanmaz (ikinci telefondaki uygulamayı kullanıyor olabilirsin).',
  'spModeOff': 'Açık kalsın',
  'spModeFreeze': 'Uygulamaları gizle',
  'spModeQuiet': 'İş profilini kapat',
  'spQuietNote':
      'Android iş profilini kapatmaya çoğu zaman yalnızca varsayılan ana ekran uygulamasına izin verir. İzin yoksa GizliAlan uygulamaları gizlemeye geçer. Hızlı ayarlardaki "İş uygulamaları" düğmesini de kullanabilirsin.',
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
};
