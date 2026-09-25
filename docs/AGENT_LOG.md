# Agent log / Ajan günlüğü

Append-only. Each session adds a dated entry at the bottom (see COORDINATION.md §8).
Her oturum en alta tarihli bir girdi ekler; eski girdiler değiştirilmez.

---

## 2026-09-25 23:10 +03:00 — joi (summary of everything so far / şimdiye kadarki özet)
- **v0.1 MVP** (branch `mvp-v1`, PR #1 → `main`): Flutter 3.47 Android project (FLAG_SECURE,
  USE_BIOMETRIC-only manifest, backup disabled, minSdk 28); always-encrypted vault (AES-256-GCM,
  per-space keys in Keystore-backed secure storage, encrypted index, legacy migration); PBKDF2 PIN
  with lockout + optional decoy PIN; biometric unlock; auto-lock; working calculator with PIN+`=`
  entry; 3-step onboarding with own-device confirmation and calculator disclosure; virtual-phone
  home grid with wallpapers; encrypted gallery, files, notes with search; settings; TR/EN.
  Docs: PRIVACY.md, docs/PLAY_COMPLIANCE.md, DECISIONS.md, BLOCKERS.md. 34 tests.
- **v0.2** (branch `v0.2-calculator-workprofile`, PR #2 → `mvp-v1`): neutral launcher label
  "Hesap Makinesi"/"Calculator" + original adaptive calculator icon (`tool/gen_launcher_icon.py`);
  "Second phone" = managed work profile, app is profile owner only (empty policies), HMAC-signed
  cross-profile trampoline, freeze/quiet-mode on Lock, clone fallback chain, profile Play Store,
  profile app grid, removal, Xiaomi fallback. Play risk logged in BLOCKERS.md. 50 tests, analyze clean.
- **Cursor rules** (branch `cursor-rules`, PR #3 → `v0.2-calculator-workprofile`):
  `.cursor/rules/00–40*.mdc` + legacy `.cursorrules`.
- **Release `v0.2.0-test`**: pre-release with `GizliAlan-test-v0.2.apk` (arm64, debug-signed, not for store).
- **Coordination** (this session, on `cursor-rules`/PR #3): COORDINATION.md, `.cursor/rules/05-coordination.mdc`,
  this log, labels, issues #4–#17 (agent tasks #4–#10, owner items #11–#17).
- **Next (Joi):** claim #4 (vault-only notification list), then #5 (Pro UI stub).
- **For Cursor agents:** free tasks are #6, #7, #8, #9 (and #10 later). Check the labels before
  claiming. The owner still has to merge PRs #1–#3 (#17).

## 2026-09-25 23:20 +03:00 — joi
- Finished: at the owner's request merged PR #3 → #2 → #1 (merge commits, branches kept). `main`
  now contains MVP v1, v0.2, the Cursor rules and the coordination protocol; analyze clean, 50 tests pass on `main`.
- **`main` is the integration branch from now on**: branch `joi/…` / `cursor/…` from `origin/main`, PR into `main`
  (COORDINATION.md §4 and the rules updated in this PR).
- In progress: #4 (vault-only notification list) on `joi/4-vault-notifications`.

## 2026-09-25 23:45 +03:00 — joi
- Finished: #4 vault-only notification list on `joi/4-vault-notifications` (PR into `main`). 58 tests, analyze clean.
- Note for the other side: widget tests that trigger encrypted writes from a tap need real-zone time;
  mark-read/clear are covered in `test/vault_events_test.dart` unit tests (see comment there).
- Next (Joi): #5 Pro/payment UI stub.
