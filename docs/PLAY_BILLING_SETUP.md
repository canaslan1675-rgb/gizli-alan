# Google Play Billing setup — GizliAlan Pro (v0.4.9+)

Since v0.5.0 the Play upload is the **`full`** flavor (`com.offerforge.gizlialan`,
Second phone included; build `flutter build appbundle --release --flavor full`).
Both `full` and the lite `play` flavor sell **GizliAlan Pro** as an
auto-renewing subscription through Google Play Billing (official Flutter
`in_app_purchase` plugin, Play Billing Library 8.0.0). No server: the app
asks Play for the purchase state, acknowledges purchases, and caches
"Pro active" on the device. The local "Simulate Pro" switch exists only in
debug builds and in CI test APKs built with `--dart-define=PRO_STUB=true`
(never in the Play AAB).

## What the app expects (must match exactly)

| Item | Value |
|---|---|
| Product type | Subscription |
| Product ID | `gizlialan_pro` |
| Base plan 1 | `monthly` — auto-renewing, billing period **1 month**, price **150 TL** |
| Base plan 2 | `yearly` — auto-renewing, billing period **1 year**, price **999 TL** |
| Offer (optional, recommended) | Free trial **7 days** on each base plan, eligibility "New customer acquisition — never had this subscription" |

Prices shown in the app always come from Play (`ProductDetails.price`), so
changing prices in Play Console needs no app update. The app buys the
free-trial offer automatically when Play says the user is eligible and
otherwise the plain base plan. Other product IDs are ignored.

## Steps in Play Console

1. **Payments profile** (one time): Play Console → *Setup → Payments profile*
   → create/link a Google payments merchant profile (legal name, address,
   bank account for payouts, tax info). Subscriptions cannot be created
   until this is done. For Turkey, also fill in the tax information that
   Play asks for.
2. **Upload a build that contains billing** (the `com.android.vending.BILLING`
   permission comes from the billing library): upload the v0.4.9+ `play` AAB
   to **Internal testing** (Testing → Internal testing → Create release).
   Play only lets you create products after such a build exists.
3. **Create the subscription**: *Monetize with Play → Products →
   Subscriptions → Create subscription*
   - Product ID: `gizlialan_pro` (cannot be changed later)
   - Name: `GizliAlan Pro`
   - Benefits (shown by Play): "İkinci telefon", "Sınırsız öğe",
     "Hesap makinesindeki ⓘ simgesini gizleme"
4. **Base plan `monthly`**: *Add base plan* → ID `monthly` → Auto-renewing →
   Billing period 1 month → Grace period (default ok) → *Set prices* →
   Turkey **150 TRY** (let Play convert other countries, or set them) →
   Save → **Activate**.
5. **Base plan `yearly`**: same with ID `yearly`, billing period 1 year,
   Turkey **999 TRY** → Save → **Activate**.
6. **7-day free trial**: on each base plan → *Add offer* → Offer ID e.g.
   `trial7` → Eligibility *New customer acquisition* ("Never had this
   subscription") → Phase: **Free trial, 7 days** → Save → **Activate**.
7. **License testers**: *Setup → License testing* → add the Gmail accounts
   of testers (and the owner) → License response `RESPOND_NORMALLY`. These
   accounts are never charged; test subscriptions renew fast (monthly ≈ 5
   min, yearly ≈ 30 min, trial ≈ 3 min) and auto-cancel after 6 renewals.
   Testers must also be in the Internal testing list and install the app
   from the Play opt-in link (side-loaded APKs signed with another key
   cannot buy).
8. **Test on a phone** (tester account): Settings → GizliAlan Pro → prices
   appear → subscribe with the test card → "Pro etkinleştirildi" → the
   "Hesap makinesinde bilgi simgesini gizle" switch unlocks. Then test:
   "Satın alımları geri yükle", cancel in Play → after expiry and an app
   restart Pro turns off; "Slow test card, approves after a few minutes" →
   "Ödeme bekleniyor" and Pro turns on only after approval.
9. **Store listing / Data safety**: payments are handled by Google Play;
   the app itself collects no payment data and has no server. Mention in the
   listing that Pro is an optional subscription.

## Behaviour summary (for review)

- Paywall: Settings → "GizliAlan Pro" (or a locked Pro row). Lists benefits,
  monthly / yearly buttons with Play prices, "Restore purchases", "Manage
  subscription in Google Play" (opens
  `play.google.com/store/account/subscriptions?sku=gizlialan_pro&package=com.offerforge.gizlialan`),
  and the auto-renew / cancel-anytime note. Nothing preselected, no timers.
- Purchase: `purchaseStream` → purchased → Pro on + `completePurchase`
  (acknowledge within 3 days, otherwise Play refunds). Pending → no Pro until
  confirmed. Cancelled / error → message, no change.
- Start-up: cached Pro is used immediately, then `queryPastPurchases`
  re-checks Play; if Play answers with no active `gizlialan_pro`, Pro turns
  off. If Play is unreachable (offline) the cache is kept.
- Free: vault, encryption, calculator entry, browser, delete-original-after-
  import, up to **50 items** (photos + files + notes per vault space).
- Pro: Second phone setup, unlimited items, hiding the calculator ⓘ. When Pro
  lapses nothing stored is locked or deleted and an existing work profile
  keeps working; only new items above 50 and a NEW Second phone setup need Pro.
