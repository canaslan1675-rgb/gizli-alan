# Joi online fallback (0.6.2) — setup, privacy, Data safety

## What it does
- Priority: Gemini Nano on the device (AVAILABLE / DOWNLOADABLE / DOWNLOADING) →
  otherwise the opt-in online backend (`JoiOnlineBackend`, Firebase AI Logic,
  Gemini Developer API, model `gemini-3.8-flash`, override `--dart-define=JOI_ONLINE_MODEL=…`).
- Online is ONLY for general questions. "Notlarıma sor" and "Notu özetle" are
  Nano-only; on other phones the chip becomes "Notlarımda ara" (local keyword
  search) and the status card says notes stay on the device.
- One-time consent dialog before the first online question (stored in
  SharedPreferences `joi_online_consent`; Settings → "Joi çevrimiçi yanıtlar"
  revokes). No consent → no network call.
- Only the typed question (≤500 chars) + fixed system prompt is sent; output
  ≤400 tokens. Notes are blocked at three layers (UI, `JoiService.ask/generate`,
  `JoiOnlineBackend` notes-marker check) and covered by `test/joi_test.dart`.
- Errors: quota/429/5xx → "Joi şu an yoğun…", network → "İnternet yok…", other
  → generic error. Never throws.
- Answers carry a badge: "çevrimiçi" (cloud) or "cihazda" (Nano).

## Build-time gate (no google-services.json needed)
Firebase is initialised at runtime as a named app from dart-defines:

```
flutter build apk --release --flavor full \
  --dart-define=FIREBASE_API_KEY=AIza... \
  --dart-define=FIREBASE_APP_ID=1:123456789:android:abc... \
  --dart-define=FIREBASE_PROJECT_ID=gizlialan-xxxx
```
Without these, the online backend reports unavailable and the app behaves
exactly like before (Nano or keyword search). These values are not secrets
in the strict sense (they ship in every Firebase app) but keep them out of
git like the other keys; add them as GitHub Actions secrets for CI.

## Console steps (owner, ~10 min, needs Google login)
1. https://console.firebase.google.com → Add project (e.g. `gizlialan`), Analytics not needed. Plan: Spark (free).
2. Project settings → Add app → Android, package `com.offerforge.gizlialan`.
   Add SHA-256 of the **Play app signing key** (Play Console → Test and release → App integrity) and of the upload/debug key used for test APKs.
   Copy `apiKey` (current_key), `mobilesdk_app_id` and `project_id` from the downloaded google-services.json (the file itself isn't needed in the repo).
3. Build → **AI Logic** → Get started → choose **Gemini Developer API** (free tier). This enables the Gemini API and the Firebase AI Logic API and creates the restricted key.
4. Build → **App Check** → register the Android app with **Play Integrity** (link the Play Console app / Cloud project). Start in *monitor* mode; after metrics look clean, **Enforce** for "Firebase AI Logic". (Test APKs not installed from Play will then fail Play Integrity — keep enforcement off while sideload-testing, or add a debug provider.)
5. Optional: Google Cloud console → APIs & Services → Credentials → restrict the Android API key to the package + SHA-256 and to the "Firebase AI Logic API".
6. Build with the three dart-defines above.

## Data safety (Play Console) changes required before a Play release with these values
- Data collected: **App activity → Other user-generated content** (the questions typed to Joi in online mode).
  - Shared with third party? Sent to Google (Gemini via Firebase) as a **service provider** processing on our behalf → per Play rules this counts as *collected*, not *shared*.
  - Processed ephemerally: **Yes** (we don't store it; Gemini Developer API free tier may use prompts to improve Google products per Google's terms — mention in privacy policy).
  - Required or optional: **Optional** (consent dialog, can be revoked).
  - Purpose: **App functionality**.
  - Encrypted in transit: Yes.
- App Check / Play Integrity: device integrity token is sent to Google → covered as "App info and performance / Other" or "Device or other IDs" depending on Google's current guidance for Play Integrity (usually declared as *Fraud prevention, security* purpose).
- Privacy policy (PRIVACY.md + docs/privacy, TR/EN/RU) must add a "Joi çevrimiçi yanıtlar" section: only typed questions, only with consent, never notes/files, sent to Google Gemini, not stored by us. **Not changed in this commit** (feature is dormant until the dart-defines are set).
- Store listing: if it says "Joi works fully offline", qualify it ("cihaz içi; desteklenmeyen telefonlarda isteğe bağlı çevrimiçi genel sorular").
- INTERNET permission already present since v0.4.0 (browser, analytics); no new runtime permissions. Firebase adds no new dangerous permissions.
