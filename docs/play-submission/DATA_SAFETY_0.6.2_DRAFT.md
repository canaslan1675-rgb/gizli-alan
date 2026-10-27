# DRAFT — Data safety changes for GizliAlan 0.6.2 (Joi)

> **Status: draft, NOT submitted.** Show to Demirhan before changing anything in
> Play Console → App content → Data safety. Builds on the approved
> `DATA_SAFETY_ANALYTICS.md` (0.6.1) — keep all of those answers and ADD the rows below.

## New data that leaves the device in 0.6.2

| Play data type | Collected? | Shared? | Why / with whom | Optional? | Ephemeral? |
|---|---|---|---|---|---|
| **App activity → Other user-generated content** (text typed/dictated to Joi, last few chat turns, Pro memory facts relevant to the question) | **Yes** | **No** (Google acts as our service provider/processor via Firebase AI Logic → Gemini API; service-provider transfers are not "sharing" per Play definitions) | App functionality (answers) | **Yes** — only after Joi online consent; on-device mode sends nothing | **Yes** — processed to answer, we keep no server copy (Gemini paid tier: not used for training) |
| **App activity → In-app search history** (photo search words sent to Wikimedia Commons) | Yes | No (fetched from Wikimedia to show results; consider declaring "shared" conservatively — **owner decision**) | App functionality | Yes (Pro, only when asked) | Yes |
| **Device or other IDs** (Play Integrity / App Check attestation) | Yes | No (Google service provider) | Fraud prevention, security, and compliance | No (required for Joi online) | Yes |
| Audio (voice) | **No** — speech is handled by Android's system SpeechRecognizer; GizliAlan receives only the text | — | — | — | — |
| Notes, photos, files, PIN, chat history, memory store | **No** (stay encrypted on device) | No | — | — | — |

- **Encrypted in transit:** Yes (HTTPS/TLS to Google and Wikimedia).
- **Deletion:** no server copy; on-device chat/memory deletable in app; support e-mail for questions.
- **Free daily limit counter:** date + number stored in SharedPreferences only — not collected.

## Form checklist (do NOT submit without approval)
- [ ] Data collection stays **Yes**
- [ ] Add **App activity → Other user-generated content**: collected, not shared, App functionality, optional, ephemeral
- [ ] Add **App activity → In-app search history**: collected, App functionality, optional, ephemeral (shared? — owner)
- [ ] Device or other IDs: add purpose **Fraud prevention, security, and compliance** (App Check)
- [ ] Security practices: encrypted in transit = Yes; deletion request = Yes (support e-mail)
- [ ] App content → **AI-generated content** declaration: in-app reporting = "Bildir" button on every Joi answer (opens e-mail with the answer)

## Open questions for the owner
1. Wikimedia search words: declare as "shared" (conservative) or "not shared"?
2. Confirm privacy-policy draft (`PRIVACY_0.6.2_DRAFT.md`) before both go live together.
