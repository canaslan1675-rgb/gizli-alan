# Rejection & appeal playbook

> **TR özet.** Olası ret nedenleri, her biri için **önce düzeltme planı**, sonra (yalnızca gerçekten haksız bir kararsa) dürüst itiraz metni. Kural: ret e-postasını değil
> **Policy status** sayfasını oku; ihlal gerçekse düzelt ve yeniden gönder (Google: "düzeltmeden yeniden gönderme"); itiraz yalnızca inceleme hatasıysa. Ret hesabın itibarını
> etkilemez, ama tekrar eden kaldırmalar/askıya almalar "strike" sayılır. Hiçbir cevapta inceleyiciden bir şey saklanmaz, davranış değiştirilmez; "farklı derleme gönderip
> geçme" gibi hileler yok. En olası ret: aldatıcı davranış (hesap makinesi adı), bozuk işlev (Pro taslağı / kasayı bulamama), eksik gizlilik politikası, üretim erişimi için "daha fazla test gerekli".

## 0. Procedure

1. Read **Play Console → Policy status** (not only the e-mail): it names the policy, the element (e.g. "Launch / On Device Icon", "Full description (en-US)") and screenshots. ([Check your app's policy status](https://support.google.com/googleplay/android-developer/answer/9842754))
2. Decide honestly: **is the finding true?** If yes → fix, bump versionCode, resubmit. Google: *"Do not attempt to resubmit a rejected app until you've fixed all the policy violations."* ([Enforcement process](https://support.google.com/googleplay/android-developer/answer/9899234))
3. If the reviewer misunderstood (e.g. couldn't find the vault) → fix what caused the misunderstanding (App access text, screenshot, listing sentence) **and** reply/appeal with facts.
4. Appeal via the link in the enforcement e-mail or the Policy status page ([Managing violations and appeals](https://support.google.com/googleplay/android-developer/answer/9899142), [Get developer support](https://support.google.com/googleplay/android-developer/answer/10357403)). One appeal per decision; no duplicates.
5. Record every decision in the PR/issue log (date, policy, element, action).
6. Never: resubmit unchanged, open a second account, upload a different binary to "get through", add reviewer detection, or remove disclosure to look "cleaner".

Account impact: rejections don't affect standing; removals can accumulate; **suspensions are strikes**; repeated violations can terminate the account ([Enforcement process](https://support.google.com/googleplay/android-developer/answer/9899234)). So fix rather than argue when in doubt.

---

## 1. Deceptive Behavior / Misrepresentation — "icon/title misrepresents functionality" (most likely policy finding)

**Signals:** element "Launch / On Device Icon", "App title", "Hi-res icon"; text "Make sure that the app's title and description do not misrepresent the function of the app".

**Fix plan (in order, stop when resolved):**
1. Make sure the Play title contains "Calculator Vault" / "Hesap Makineli Kasa" (LISTING_*.md). Screenshot 1 = calculator with ⓘ open.
2. Put the calculator-entry paragraph in the first 2–3 lines of the full description and short description.
3. Launcher label: change to a descriptive label that still fits the product, e.g. **"Calculator Vault" / "Hesap Kasası"** *(code change: `@string/app_name` in `values`/`values-tr` + l10n `launcherName`; owner decision — this is the reversible "one step more explicit" fallback)*.
4. Last resort: launcher label "GizliAlan" with the calculator icon, calculator entry remains an option (DECISIONS: owner).

**Response (only if the listing already discloses everything):**
```
Hello, thank you for the review. GizliAlan's primary function is an encrypted personal vault, and the listing states this in the title ("GizliAlan: Calculator Vault"), the short description and the first paragraphs of the full description. The app is also a fully working calculator; the launcher label "Calculator" and our original calculator icon (not copied from any vendor) reflect that real function. The vault entry (PIN then "=") is disclosed (1) in the store listing section "CALCULATOR ENTRY – DISCLOSED", (2) on onboarding step 2 before first use, with a toggle to turn it off, (3) in the ⓘ dialog on the calculator, (4) in screenshots 1–2 and (5) in the App access instructions. There is no reviewer- or region-specific behaviour (the app contacts no developer server and has no remote configuration). If a different wording or label would make this clearer for users, please tell us which element and we will change it promptly.
```

## 2. Broken functionality / minimum functionality

**Likely causes:** reviewer couldn't get past the calculator; Pro buttons "not available"; crash on Android 16.

**Fix plan:** (a) App access instructions present and short (REVIEWER_NOTES §1); (b) hide the Pro stub in the `play` release or implement Play Billing (#15); (c) check pre-launch report + Android vitals, fix crash, bump versionCode.

**Response (if caused by access instructions):**
```
Thank you. The vault is protected by a PIN that the user creates on first launch; there is no account. We have updated the App access instructions: on first launch set PIN <DEMO_PIN>, then type <DEMO_PIN> and press "=" on the calculator to open the vault. All features are listed there step by step. We also uploaded a short demo video: <DEMO_VIDEO_URL>.
```

## 3. User Data — privacy policy missing/invalid, or not in-app

**Fix plan:** host `PRIVACY.md` on HTTPS (#12; GitHub Pages is fine), make it public (no login, not a PDF), app name + developer name in it, same statements as Data safety; add the URL to the in-app privacy screen; resubmit.

**Response:** usually not needed — fix and resubmit. If already compliant:
```
Our privacy policy is available at <PRIVACY_URL> (public HTTPS, no login) and is also shown in the app under Settings → Privacy & permissions. It states that the app collects and shares no user data; all content is encrypted and stays on the device, and the app has no server, analytics or ads; the INTERNET permission is used only by the in-vault browser to load pages the user opens.
```

## 4. Data safety mismatch

**Cause:** Google's scan thinks an SDK collects data. **Fix plan:** check `aapt2 dump badging` + dependency list; if a plugin added a permission/SDK, remove it (`tools:node="remove"`) or declare truthfully. **Response** (if false positive): list permissions (`USE_BIOMETRIC`, `INTERNET` for the user-driven in-vault browser only), dependency list, and quote the on-device processing definition from the [Data safety help page](https://support.google.com/googleplay/android-developer/answer/10787469).

## 5. Impersonation / intellectual property (icon)

**Fix plan:** icon is generated by `tool/gen_launcher_icon.py` (navy, mint "="). If flagged as similar to a vendor calculator: change colours/geometry further (e.g. add a small lock/vault mark inside the "=" key), regenerate launcher + store icon together, resubmit. **Response** (only if clearly unrelated): "The icon is our original artwork (source script in our repo); it does not reproduce any company's logo, and the title/developer name make no claim of affiliation."

## 6. Stalkerware / Spyware / "hidden app" concerns

**Response:**
```
GizliAlan does not monitor anyone. It contacts no server and transmits no data (INTERNET is used only by an in-vault browser for pages the user opens); it requests no SMS, call log, contacts, location, microphone, camera, Accessibility or notification-listener access, and it is not a device administrator. It only stores content the device owner explicitly adds (via the system pickers) in an encrypted local vault. Onboarding requires confirming "This is my own device", and the listing states it must only be used on one's own device. The launcher icon is always visible; the app never hides its icon.
```
**Fix plan:** re-read listing for words like "secret", "hide from", "no one will know"; remove them.

## 7. Enabling dishonest behaviour (decoy PIN)

**Response:** "The decoy PIN is an optional, disclosed privacy feature (common in vault apps on Google Play) that opens a separate, empty vault the user creates; it does not generate fake documents or deceive third parties about identity, and biometrics always open the real vault." **Fix plan if upheld:** rename in UI/listing to "second vault PIN" with neutral description, or remove the feature in `play` (owner decision).

## 8. Production access refused: "more testing required" (new personal account)

Not a policy violation. **Fix plan:** run a new ≥ 14-day closed test with ≥ 12 (aim 20) **engaged, real** testers; ship at least one improvement based on feedback; keep a log (date, tester feedback, fix); answer the questionnaire concretely (how testers were recruited, what they tested, what changed). ([requirements](https://support.google.com/googleplay/android-developer/answer/14151465))

## 9. `full` flavor only — Device & Network Abuse / Permissions / Unwanted Software (device admin)

**Fix plan:** (1) confirm the in-app explanation before provisioning mentions "device admin / profile owner" and removal; (2) listing "DEVICE ADMIN PRIVILEGE" bullet present; (3) App access + DECLARATIONS §2 text + demo video; (4) if still refused → keep Play on `play` only, `full` side-load (already the recommended plan). **Response:** DECLARATIONS §2.2 full justification + video link. Mention the precedent factually ("the same work-profile model used by apps such as Island that are available on Google Play") without arguing that others' presence entitles approval.

## 10. Payments (once Pro exists)

If Pro prices appear in the app without Play Billing → hide stub or integrate Play Billing (#15). Listing must say which features need payment.

---

## Template — generic appeal structure

```
App: GizliAlan (<package>), version <versionName> (<versionCode>)
Policy cited: <policy>, element: <element>

1. What the app does: <one sentence>.
2. Why this element complies: <facts, with where in the app/listing>.
3. What we changed anyway to make it clearer: <list> (new version <versionCode>).
4. Access: App access instructions updated; demo video <URL>.
We're happy to adjust any specific wording or asset you point to.
```
