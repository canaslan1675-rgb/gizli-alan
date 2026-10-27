# Joi online fallback (0.6.2) — setup, privacy, Data safety

## What it does
- Priority: Gemini Nano on the device (AVAILABLE / DOWNLOADABLE / DOWNLOADING) →
  otherwise the opt-in online backend (`JoiOnlineBackend`, Firebase AI Logic,
  Gemini Developer API, models `gemini-3.5-flash-lite` → fallback `gemini-flash-lite-latest` (streaming, 12 s first-token timeout per model), override `--dart-define=JOI_ONLINE_MODEL=…` / `JOI_ONLINE_FALLBACK_MODEL=…`).
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

## 0.6.2 test6 additions

### Free vs Pro (owner decision)
- **Free:** plain question-and-answer chat only (Nano or online). Chat history lives only while the Joi screen is open.
- **Pro** (`gizlialan_pro_lifetime`, `ProEntitlement.isActive`): write to notes, photo download (Wikimedia Commons), voice (mic + read aloud), notes search / summarize / "Notlarıma sor", persistent encrypted chat history.
- Pro-only example chips and the notes chip show a small "Pro" badge; triggering a Pro-only action as a free user (also via typed command) is NOT executed — Joi replies with an upsell line and the existing Pro dialog opens.
- Test APKs (`PRO_STUB=true`): Settings → Pro (stub screen) toggles Pro on/off to test both states.

### Photo download — Wikimedia Commons
- Intent detection: on-device keyword/regex parser (TR/EN), e.g. "Galata Kulesi'nin fotoğrafını indir", "Download a photo of X". (No extra model call → instant and predictable; function calling not used.)
- Request goes from the phone directly to `commons.wikimedia.org/w/api.php` (search query text only, User-Agent `GizliAlan/0.6.2 …`), thumbnails/images from `upload.wikimedia.org`. Only files with a free licence (CC, PD, GFDL, FAL…) and JPEG/PNG/WebP are shown (max 6), with title, author, licence.
- Requires the online consent (same toggle). Offline / nothing found → Turkish messages.
- Save: "Galeriye kaydet" → MediaStore `Pictures/GizliAlan/Joi`, Android 10+ only (no storage permission; MediaStore DESCRIPTION = title — author — licence — source URL). Android 9 (minSdk 28): only "Kasaya kaydet" is offered (no WRITE_EXTERNAL_STORAGE added). "Kasaya kaydet" → encrypted vault gallery (free item limit applies). Attribution is also written into the chat.
- **Privacy/Data safety later:** Wikimedia Foundation receives the search text and the device IP (as any web request). Nothing stored by us.

### Write to notes
- "Not defterime … yaz/özetle", "not defterime şunu yaz: …". Literal text → saved directly. Otherwise content is generated by Nano (if available) or online (consent) from the user's request only; the new note goes into the encrypted notes. Existing notes are never sent; created-note messages are marked private and never used as online context.

### Chat history
- Stored per vault space in `joi_chat.gae` (AES-GCM like other vault data), last 200 messages; survives leaving the screen, app restart and re-lock. "Sohbeti temizle" in the Joi menu (with confirmation). Single conversation (multiple past conversations not implemented).
- Online context: last 20 non-private turns (note search hits, summaries, ask-my-notes answers and created notes excluded), each capped to 600 chars.

### Voice
- Mic: Android `SpeechRecognizer` (on-device recogniser preferred: `createOnDeviceSpeechRecognizer` on Android 12+ when available, `EXTRA_PREFER_OFFLINE`), language tr-TR / en-US / ru-RU from app language. `RECORD_AUDIO` is requested only when the mic is first tapped, after a Turkish rationale. Audio is processed by the system speech service (may be Google's online service if no offline model); GizliAlan never records or stores audio.
- Read aloud: Android `TextToSpeech`, app-language voice. Header speaker toggle + Settings "Joi yanıtlarını sesli oku"; voice questions are always answered aloud; stop button while speaking. Conversation mode (auto-listen after speaking) NOT implemented (skipped for robustness).
- **Privacy/Data safety later:** declare Audio → "Voice or sound recordings"? Only if processed off-device by us — we don't; the system speech service does. Mention mic use in the privacy policy.
- Manifest: `RECORD_AUDIO` changed from `tools:node="remove"` to granted; `<queries>` for RecognitionService and TTS_SERVICE.

### Other (same build)
- Settings → "Çıkınca bıraktığım yerden devam et" (default off). On: auto-lock waits 1/5/15 min (default 5) in the background instead of the normal lock timeout; process death / reboot always locks (key is memory-only); FLAG_SECURE unchanged. Warning dialog when enabling.
- Google Play In-App Updates (flexible, `com.google.android.play:app-update:2.1.0`): checked only after the vault opens; "Yeni sürüm mevcut" with Güncelle / Daha sonra (snooze 1 day per version) and a Play Store link; after download a "Yeniden başlat" snackbar; after an update, "Bu sürümde yenilikler" once from `assets/changelog.json`. Silent on sideloaded APKs (installer ≠ Play). Only testable via a Play track (internal testing).

## Image requests (test8)
- Local detector covers many TR/EN variants (indir/at/gönder/göster/bul/getir; fotoğraf/foto/resim/görsel; "X'in resmi", "bana X göster", "picture of X").
- Missing subject ("fotoğrafını indir", "bir resmini at"): a small online classifier call gets `{"is_image_request","query"}` from the last 6 non-private chat turns (never notes); offline fallback = topic of the last "X kimdir/nedir/nerede" question; otherwise Joi asks "Neyin fotoğrafını indireyim?".
- "niye inmedi / indirdin mi / hani fotoğraf" repeat the last image request.
- Hallucination guard: chat replies claiming an action ("indireceğim", "bekliyorum"…) are replaced by an honest message and, if a subject is known, the image flow runs.
- Explicit "indir" shows "İlkini galeriye kaydet"; nothing is saved without a tap.
- Wikimedia HTTP 429: waits Retry-After (≤3 s) and retries once.

## Persona & answer quality (test9)
- Online system prompt = identity + style rules (short by default, longer on request, no robotic phrases, one clarifying question when ambiguous, empathy, light humour, user's language, Markdown lists/bold) + current Istanbul date/time + "live data may be out of date" rule + 4 few-shot examples.
- Multi-turn history: last 20 non-private messages as user/model contents (unchanged plumbing, verified).
- Generation: temperature 0.7, topP 0.95, maxOutputTokens 1024 (was 0.4 / 300). No thinkingConfig (lite models reject budget 0).
- Models: non-lite flash variants (gemini-3.5-flash, gemini-flash-latest, gemini-3.8-flash) return 429/500 on the free tier from the box → kept gemini-3.5-flash-lite + gemini-flash-lite-latest.
- Bubbles render a safe Markdown subset (JoiMarkdown: bold, italic, code, bullets, numbered, headings→bold); TTS reads the plain text.

## Long-term memory v1 (test10, Pro)
- Storage: `joi_memory.gae` in the vault space, encrypted with the same EncryptedFiles key as `joi_chat.gae`. Facts: text, category, importance 1-5, created/updated, source date. Max 200 facts, 10 summaries.
- Extraction (mem0 pattern): after every 10 new messages, on app pause, on leaving the Joi screen and before "Sohbeti temizle". One call (Gemini Nano if active, otherwise flash-lite) with a strict JSON prompt returning ≤5 ops `{op: add|update|delete, text, category, importance, target_id}`. Similar existing facts (profile + keyword matches) are sent so it can update/merge.
- Input filtering IN CODE (`joiMemoryInput`): only user turns and online model answers. Note-derived messages (private), Joi-created notes, tool results and "not defterime … yaz" requests are excluded. Sensitive facts (health, finances, credentials, addresses, IDs, phone/IBAN/card/TC numbers) are dropped in code (`joiMemorySensitive`) even if the model returns them.
- Retrieval: Turkish-aware keyword stems (suffix stripping, prefix matching) + importance + recency. The system prompt gets a "HAFIZA" block: profile facts (identity/people/pets, ≤~300 tokens) + up to 8 relevant facts + the latest 1-2 rolling summaries (≤150 words each, of messages older than the 20-message window), with an instruction to use them naturally and not recite.
- UI: "Joi'nin hatırladıkları" (Settings and the Joi menu): list, edit, delete, "Tümünü unut" (confirm), on/off toggle. Chip "Joi bunu hatırladı" when facts are saved. Free users see the Pro upsell and nothing is extracted or injected.
- "Sohbeti temizle" keeps memories; "Tümünü unut" deletes them (not the chat).

### Privacy policy / Data safety notes (to update later — NOT changed yet)
Google's Gemini API Additional Terms (https://ai.google.dev/gemini-api/terms, effective 23 Mar 2026, last updated 2026-04-28), section "Unpaid Services → How Google Uses Your Data":
> "When you use Unpaid Services, including, for example, Google AI Studio and the unpaid quota on Gemini API, Google uses the content you submit to the Services and any generated responses to provide, improve, and develop Google products and services and machine learning technologies, including Google's enterprise features, products, and services, consistent with our Privacy Policy."
> "To help with quality and improve our products, human reviewers may read, annotate, and process your API input and output. Google takes steps to protect your privacy as part of this process. This includes disconnecting this data from your Google Account, API key, and Cloud project before reviewers see or annotate it. Do not submit sensitive, confidential, or personal information to the Unpaid Services."
Also: "You may use only Paid Services when making API Clients available to users in the European Economic Area, Switzerland, or the United Kingdom." and "Use of Google AI Studio and Gemini API is for developers building with Google AI models for professional or business purposes, not for consumer use." and the 18+ age requirement.
Implications: while on the Spark/unpaid quota, online questions, chat history context, memory facts in the prompt and memory-extraction inputs may be used by Google to improve products and may be human-reviewed. Privacy policy + Data safety ("shared with Google for processing; may be used to improve Google products on the free tier") and the in-app consent text must say this before public release; EEA/CH/UK users need the paid tier (or the online feature disabled there); memory extraction should switch to Nano-only or paid tier for a strict "no personal data" stance.
