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

## 2026-09-25 23:59 +03:00 — joi
- Finished: #5 Pro/payment UI stub on `joi/5-pro-ui-stub` (stacked on #19, PR into `main`; merge #19 first).
- Free tasks for the other side: #6 screenshots, #7 device test plan, #8 signing config, #9 docs sync, #10 (post-MVP).
- Next (Joi, next session 10:07): check open PRs/issues, pick the next free task (likely #8 or #7 if not claimed).

## 2026-09-26 00:00 +03:00 — joi
- Finished: #8 release signing config on `joi/8-release-signing` (stacked on #20). Verified debug fallback,
  a throwaway keystore (deleted afterwards, never committed), and the blank-value error.
- For the owner: #13 (create the keystore + key.properties locally, steps in README).
- Next (Joi): #9 docs sync.

## 2026-09-26 00:10 +03:00 — joi
- Finished: #9 docs sync on `joi/9-docs-sync` (stacked on #21). Brief §2 ticked/linked, §6 current, §7 partly ticked.
- If #19/#20/#21 change before merge, re-check the brief ticks that cite them.
- Next (Joi): #7 device test plan if still unclaimed; #6 is left for the Cursor agents.

## 2026-09-26 00:25 +03:00 — joi
- Finished: #7 plan part — `docs/DEVICE_TEST_PLAN.md` on `joi/7-device-test-plan` (stacked on #22).
- HANDOFF: the emulator run of #7 (§5 of the plan). The Joi box has no emulator and no KVM access. Any agent
  with a Pixel emulator (API 34/35, Play image) can run §1–§3 and fill in §6; the issue carries `handoff`.
- Left for the Cursor agents: #6 screenshots (unclaimed). Owner items: #11–#16.
- Joi's open PRs, merge order: #18 → #19 → #20 → #21 → #22 → #7's PR (each stacked on the previous).

## 2026-09-26 00:07 +03:00 — joi
- Finished: #7 emulator close — re-verified no usable emulator on the box (`/dev/kvm` present but
  inaccessible to `box`; no system image); strengthened `docs/DEVICE_TEST_PLAN.md` §5 + §6 N/A row;
  synced `AUTONOMOUS_BRIEF.md` §6 (PRs #18–#23 merged) + DECISIONS rows. PR into `main` with Closes #7.
- Note for the other side / Cursor: **#6** is claimed by cursor (`status:in-progress`); screenshots
  finished locally on `cursor/6-store-screenshots` but the **branch is not on GitHub** (push blocked
  from that environment). Need push access or a HANDOFF so Joi can take the files. Do **not** take
  over yet — 24 h rule not met.
- Next (Joi): wait for owner merge of this PR; do not claim #6 or #10; owner items #11–#16 stay owner.

## 2026-09-26 00:45 +03:00 — joi
- TAKEOVER of #6 (owner-approved; the Cursor agent finished it locally on `cursor/6-store-screenshots` 03413eb
  but could not push). Redone from `main` on `joi/6-store-screenshots`; credit to the Cursor agent.
- Finished: 12 store screenshots (`docs/store/screenshots/{tr,en}/`), generator `tool/gen_store_screenshots.sh`
  (widget rendering, skipped in normal `flutter test`), PLAY_COMPLIANCE ticked, DECISIONS row.
- Merged #24 (close #7 emulator path) before this, at the owner's request.
- Next: owner decisions #11–#16; #10 (post-MVP) is free.

## 2026-09-26 01:30 +03:00 — joi
- Finished: #11 (owner: "ikisini de üretip deneyelim") on `joi/11-play-full-flavors` — `play` / `full` product
  flavors (source sets `android/app/src/{play,full}`), `lib/flavor.dart` gating, flavor tests, screenshots
  `docs/store/screenshots/{play,full}/{tr,en}/`, docs, version 0.3.0+3, prerelease `v0.3.0-test` with both APKs.
- #11 keeps the `owner` label: which flavor is submitted to Play is the owner's call after device testing (#14).
- Note for all agents: Android builds now need `--flavor play|full`. Never put Second phone code or manifest
  entries in `src/main`; they go in `src/full`. New Second phone UI must check `Flavor.hasSecondPhone`.
