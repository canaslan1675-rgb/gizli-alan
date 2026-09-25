/// Turkish strings (default locale).
const Map<String, String> tr = {
  'appName': 'GizliAlan',
  'appNameVault': 'GizliAlan Kasa',
  'decoyTitle': 'Hesap Makinesi',
  // Onboarding
  'onboardingTitle': 'GizliAlan\'a Hoş Geldin',
  'onboardingBody':
      'GizliAlan, bu telefonun sahibine ait kişisel bir kasadır: özel '
      'fotoğraflar, notlar ve dosyalar PIN (ve isteğe bağlı parmak izi/yüz) '
      'ile korunur ve bu cihazda şifrelenir.',
  'onboardingPrivacy':
      'İzleme aracı değildir. GizliAlan SMS, arama, rehber veya konum okumaz; '
      'Erişilebilirlik Hizmeti veya Cihaz Yöneticisi kullanmaz ve hiçbir şey '
      'yüklemez — sunucu yoktur. Yalnızca kendi cihazında, kendi içeriğin '
      'için kullan.',
  'ownDeviceConfirm':
      'Bu benim kendi cihazım ve yalnızca kendi içeriğimi saklayacağım.',
  'entryTitle': 'Hesap makinesi girişi',
  'entryBody':
      'GizliAlan normal, tam çalışan bir hesap makinesi olarak açılabilir. '
      'Kasaya girmek için PIN\'ini yazıp "=" tuşuna bas. Biyometrik için "=" '
      'tuşuna uzun bas (açıksa).',
  'entryDisclosure':
      'Bu gizlenmiş bir özellik değildir; mağaza açıklamasında ve hesap '
      'makinesindeki ⓘ düğmesinde anlatılır. Uygulama simgesi ve adı '
      '"GizliAlan" olarak kalır. Ayarlar\'dan istediğin zaman kapatabilirsin.',
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
      'girişidir: kasa PIN\'ini yazıp "=" tuşuna basarak kasayı açarsın. '
      'Biyometrik açıksa "=" tuşuna uzun bas. Hesap makinesi girişini kasa '
      'ayarlarından kapatabilirsin.',
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
      'Cihaz Yöneticisi yok.\n'
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
};
