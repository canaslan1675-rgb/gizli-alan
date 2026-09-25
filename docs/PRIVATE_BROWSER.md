# Private in-vault browser (v0.4.0, #32)

> **TR özet.** Kasa ana ekranında "Tarayıcı". Android System WebView (`webview_flutter`).
> Uygulama hiçbir yere veri göndermez (analitik/telemetri/çökme raporu/reklam/sunucu yok);
> tek trafik kullanıcının açtığı sayfalaradır. Varsayılan arama DuckDuckGo (seçilebilir, öneri
> API'si yok). Çerez/önbellek/site verisi uygulamaya özel depoda, kasa kilitlenince silinir
> ("Kilitlenince temizle", varsayılan açık). Geçmiş yalnızca bellekte. Üçüncü taraf çerez engelli,
> dosya erişimi / JS köprüsü / konum / kamera / mikrofon / indirme / dosya yükleme kapalı.
> FLAG_SECURE tarayıcıyı da kapsar. Safe Browsing WebView varsayılanında bırakıldı.

## Scope

| Feature | Status |
|---|---|
| Address / search bar | ✅ URLs load directly, bare domains get `https://`, everything else is a search |
| Search engine | DuckDuckGo (default), Startpage, Brave, Google, Bing — Settings → Browser. Plain `?q=` URL, **no suggestion API** |
| Back / forward / reload | ✅ (system Back = page back, then leave) |
| Tabs | 1 tab (by design) |
| History | In memory only (WebView back stack); gone when the screen closes |
| Cookies / cache / DOM storage | App-private WebView storage; **wiped on vault lock** when "Kilitlenince temizle" is on (default), and on app start while locked; "Şimdi temizle" wipes immediately |
| Third-party cookies | Blocked (`AndroidWebViewCookieManager.setAcceptThirdPartyCookies(false)`) |
| Downloads | **Disabled** — no `DownloadListener` is registered, so download links do nothing. Saving into the vault encrypted was not "simple" (needs a streamed fetch outside WebView, cookie/auth forwarding and MIME handling); left for a later issue |
| File upload (`<input type=file>`) | Disabled (no file chooser handler) |
| Geolocation / camera / mic / MIDI | Denied (`onPermissionRequest → deny`, `setGeolocationEnabled(false)`, location permissions removed from manifest) |
| `file://`, `content://`, `intent:`, `tel:` … | Blocked by the navigation delegate (only `http`, `https`, `about:blank`); snackbar "blocked" |
| JS bridges | None (`addJavaScriptChannel` is never called; a test scans the sources) |
| FLAG_SECURE | Set on the single Flutter activity → covers the browser (verify on device, DEVICE_TEST_PLAN 2.19) |

## What goes over the network

1. Requests to the pages the user opens (and their sub-resources), and to the chosen search
   engine when the user searches. Those sites see the device IP, user agent and whatever the
   user submits — as with every browser.
2. **Safe Browsing:** left at the Android System WebView default. On devices with Google Play
   services, WebView may check URLs against Google's Safe Browsing list (hash-prefix lookups).
   This is part of the platform component, not an SDK or API call in GizliAlan. We don't toggle
   it off because it protects users from phishing/malware; documented in PRIVACY.md.
3. **WebView metrics:** opted out via `<meta-data android:name="android.webkit.WebView.MetricsOptOut" android:value="true"/>`.

Nothing else: the app has no server, no analytics, telemetry, crash reporting, ads or remote
config. The only permission added is `INTERNET` (tests assert the full permission set).

## Wipe implementation

`BrowserData.wipe()` → method channel `gizlialan/system` → `wipeWebData` in `SystemChannel.kt`:
`CookieManager.removeAllCookies` + `flush`, `WebStorage.deleteAllData`,
`GeolocationPermissions.clearAll`, `WebViewDatabase.clearHttpAuthUsernamePassword/clearFormData`,
and a temporary `WebView.clearCache(true)` + `destroy`. Called from `lockVault()` and on bootstrap.
The browser screen is torn down on lock (the vault route stack is replaced), so no page stays
alive behind the calculator.

## Play policy notes

- `INTERNET` is a normal permission; no declaration form.
- Data safety stays **"no data collected or shared"** by the developer: browsing is
  user-initiated traffic to sites the user chose (see `docs/play-submission/DATA_SAFETY.md`).
- Listing no longer claims "no internet permission"; it says "No tracking · No ads".
