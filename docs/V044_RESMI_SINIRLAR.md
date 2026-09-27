# v0.4.4 — resmi yollar ve sınırlar

Sürüm `0.4.4+11` (`full` çeşidi). Root, sistem imzası, gizli API ve güvenlik açığı yok. Aşağıdaki satırlar bu depodaki kodun yaptığı çağrılardır. Xiaomi başlatıcının boş klasörü gizleyip gizlemediği bu ortamda ölçülmedi; o satır boş bırakıldı.

## Olan

Profilin içinden, GizliAlan profil sahibiyken:

| Ne | API | Sonuç |
|---|---|---|
| Uygulamaları gizle | `DevicePolicyManager.setApplicationHidden` | Başlatıcı simgesi olan her paket gizlenir. Play Store (`com.android.vending`) buna dahildir. Gizlenemeyen paket `setPackagesSuspended` ile askıya alınır (simge gri kalabilir). |
| Dosyalar | aynı API, `HidePolicy.ALSO_HIDE` | Simgesi olmasa da denenir: DocumentsUI, Google Dosyalar (`com.google.android.apps.nbu.files`), Xiaomi Dosyalar (`com.mi.android.globalFileexplorer`, `com.android.fileexplorer`, `com.miui.fileexplorer`). Profilde yüklü değillerse gizlenecek paket yoktur. |
| Profil adı | `setProfileName("Alan")` ve `setOrganizationName("Alan")` | Kurulumda ve her kilit/açılışta yazılır. Eski metin `İş` / `Work` idi; o metin sekmeyi işaret eden addır. Boş ad gönderilmez; Android `setProfileName("")` çağrısını reddeder. |
| Profili duraklat | `UserManager.requestQuietModeEnabled(true, profil)` | Çağrı yapılır. Android bunu yalnızca öndeki varsayılan başlatıcıya ya da `MANAGE_USERS` / `MODIFY_QUIET_MODE` iznine açar. GizliAlan başlatıcı değildir ve bu izinleri alamaz. Telefonda dönüş `SecurityException` olur; gizleme yine uygulanır. Profil sahibinin kendi profilini duraklatan bir `DevicePolicyManager` metodu yoktur. |

Kilit açılınca yalnızca bizim gizlediğimiz paketler (ve Play Store emniyet ağı) geri açılır. Kişisel profildeki uygulamalara dokunulmaz.

Gizlenmeyenler, profil yönetilebilsin diye: GizliAlan'ın kendisi, Play hizmetleri (`com.google.android.gms`, `com.google.android.gsf`), paket yükleyici, izin ekranı, Ayarlar, SystemUI, MIUI güvenlik ve başlatıcı paketleri. Bunlar gizlense de sekmeyi kaldıran bir API ortaya çıkmaz.

## Olmayan

- İş sekmesini veya MIUI'deki klasörü kaldıran bir açık API yok. AOSP Launcher3, yönetilen profil durduğu sürece İş sayfasını tutar; uygulamalar gizlenince sayfa boş kalır, sekme durur. Sekmeyi kaldırmak profili silmektir.
- Xiaomi (MIUI / HyperOS) boş klasörü gizleyip gizlemediği **bu yazılımın derlendiği ortamda ölçülmedi.** Aşağıdaki tablo doldurulmadan "klasör kayboldu" denmez.
- Kişisel taraftaki uygulamalar gizlenemez. Organization-owned profil kurulmuyor; o kurulum kişisel tarafa politika uygulayabilir.
- Varsayılan başlatıcı rolü istenmiyor. O rol Xiaomi başlatıcının yerine geçer ve bu telefonun ana ekranını riske atar. Duraklatma ancak o rolle mümkün olur; rol alınmadığı için duraklatma reddedilir.
- Arka planda (Home tuşu) anında gizleme yok. Android, arka plandaki uygulamadan karşı profile etkinlik açmayı engeller. Sonraki öne geliş veya profildeki 15 dakikalık iş bunu tamamlar.
- Play incelemesi, Play Store'u gizlemeyi amaçlayan bir uygulamayı yine de reddedebilir. Çağrı açık API'dir; bu risk kapanmaz. `play` çeşidinde ikinci telefon ve bu kod yoktur.

## Xiaomi'de bakılacak (henüz bakılmadı)

`full` APK, kasa kilitli, ikinci telefonda Play Store ve Dosyalar kurulu olsun.

| Bakış | Sonuç |
|---|---|
| Kilitliyken Play Store simgesi | |
| Kilitliyken Dosyalar simgesi | |
| Ayarlar'da profil adı `Alan` mı | |
| Başlatıcıdaki klasör/sekme adı `Alan` mı, `İş` mi | |
| Simgeler gidince klasör/sekme duruyor mu | |
| Hızlı ayardan profil duraklatılınca klasör/sekme duruyor mu | |

Cihaz modeli, Android sürümü ve HyperOS/MIUI sürümü satırın yanına yazılır.
