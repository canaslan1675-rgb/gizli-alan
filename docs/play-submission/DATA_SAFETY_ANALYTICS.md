# Data Safety — Analytics package (AppMetrica + TikTok) — **DRAFT**

> **Status: DRAFT** for GizliAlan **0.6.1+44**. Combine with the base
> `DATA_SAFETY.md` answers when filling Play Console. Do **not** submit until
> the owner reviews and the hosted privacy policy (PRIVACY.md /
> docs/privacy/index.html) is updated to match.

Source definitions: [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469).

## Summary change vs pre-0.6.1

| Question | Pre-0.6.1 | 0.6.1 (this package) |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | **Yes** (when the in-app toggle is on; SDKs are present in the binary) |
| Advertising ID | No | **Yes** declare — TikTok SDK merges `com.google.android.gms.permission.AD_ID` |
| Ads in the app? | No | **Still No** (no ads shown; SDKs are attribution / measurement only) |

Both SDKs are gated by Settings → **«Anonim istatistik ve reklam ölçümü»** /
**«Анонимная статистика и измерение рекламы»**. Default **on**. When off,
AppMetrica `setDataSendingEnabled(false)` and TikTok `setSdkGlobalSwitch(false)`
/ deferred `startTrack` — neither sends data. Vault content is **never** sent.

iOS App Tracking Transparency is **not applicable** (Android-only app).

## Data shared with third parties (for attribution / analytics)

| Data type | Collected? | Shared? | Purposes | Ephemeral? |
|---|---|---|---|---|
| **Device or other IDs** (Advertising ID / GAID, app-set / SDK IDs) | Yes | Yes — AppMetrica (Yandex), TikTok / ByteDance | Analytics; Advertising or marketing | No |
| **App interactions** (install, app open / launch, session) | Yes | Yes — same | Analytics; Advertising or marketing | No |
| **Purchase history** (lifetime Pro product id, value, currency — only on a fresh purchase success) | Yes (if Purchase event fires) | Yes — same | Analytics; Advertising or marketing | No |
| Vault photos / files / notes / PIN / browser URLs | **No** | **No** | — | — |
| Name, email, phone (`identify`) | **No** | **No** | — | — |

- **Encrypted in transit:** Yes (HTTPS to AppMetrica and TikTok endpoints).
- **Optional:** Yes — user can turn the toggle off; also can reset/delete GAID in Android Settings → Google → Ads.
- **Deletion request:** support email; AppMetrica / TikTok each have their own deletion / opt-out flows (no first-party server copy of these events).

## Processors

| Processor | Role | Policy |
|---|---|---|
| **AppMetrica (Yandex LLC / Yandex services)** | Mobile analytics + install attribution (Yandex Direct) | https://appmetrica.yandex.com/about/privacy-policy (also Yandex privacy) |
| **TikTok / ByteDance (TikTok Pte. Ltd. / TikTok Inc., TikTok for Business)** | App Events / conversion tracking for TikTok app-install ads | https://www.tiktok.com/legal/page/us/privacy-policy/en and TikTok Business / Events Manager docs |

## Permissions added by these SDKs (verify on each release AAB)

Re-check with `aapt2 dump permissions` / `bundletool dump manifest` after every
release build:

| Permission / component | Likely source |
|---|---|
| `com.google.android.gms.permission.AD_ID` | TikTok Business SDK (and possibly AppMetrica) |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Play Install Referrer (`installreferrer:2.2`) used by TikTok |
| `android.permission.ACCESS_NETWORK_STATE` | Analytics SDKs (no longer stripped in 0.6.1) |
| `android.permission.INTERNET` | Already present (browser + measurement) |

## Form checklist (Play Console)

- [ ] Data collection = **Yes**
- [ ] Device or other IDs — collected + shared — Analytics + Advertising or marketing — encrypted in transit — optional
- [ ] App interactions — collected + shared — same purposes — encrypted — optional
- [ ] Purchase history — collected + shared — same — encrypted — optional (only if Purchase event is shipped)
- [ ] Advertising ID declaration = **Yes**
- [ ] Ads declaration (“Does your app contain ads?”) = **No**
- [ ] Privacy policy URL updated with AppMetrica + TikTok sections
- [ ] This DRAFT reviewed by owner → remove DRAFT marker when live

## Build notes

- AppMetrica API key: `--dart-define=APPMETRICA_API_KEY=…` (from
  `/home/box/.secrets/appmetrica_gizlialan_api_key` on the build machine; never git).
- TikTok App Secret: `--dart-define=TIKTOK_APP_SECRET=…` (from
  `/home/box/.secrets/tiktok_gizlialan_app_secret`; never git).
- TikTok App ID (non-secret): `7700201711725477895` (default in code; overridable via
  `--dart-define=TIKTOK_APP_ID=…`).
