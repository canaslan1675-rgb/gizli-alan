# COORDINATION — how the agents share work / Ajanlar işi nasıl paylaşır

Two sets of AI agents work on this repo for the owner (Demirhan):

- **Joi** (`agent:joi`): daily routine at 10:07 Istanbul time, works on `joi/...` branches, opens PRs.
- **Cursor agents** (`agent:cursor`): agents in another Cursor account. They auto-load `.cursor/rules/`.

The agents cannot talk to each other directly. **The repo is the channel:** GitHub issues
(label `task`) + `docs/AGENT_LOG.md`. The goal is that each side knows what the other finished
and is doing, and if one side goes silent the other side finishes the half-done work, so the
project keeps moving.

> **TR özet:** İki ajan grubu (Joi ve Cursor ajanları) doğrudan konuşamaz. Kanal repodur:
> `task` etiketli GitHub issue'ları + `docs/AGENT_LOG.md`. Her oturumda: `git fetch`, günlüğü ve
> açık `task` issue'larını oku → işi **üstlen (CLAIM)** → ilerlemeyi yaz (**heartbeat**) → dururken
> **HANDOFF** yaz → biten iş için PR `Closes #N` + PROGRESS.md satırı + günlük girdisi.
> Bir taraf 24 saat sessiz kalırsa diğer taraf **TAKEOVER** ile devralır ve mevcut daldan devam eder.
> Kesin yasaklar ve DUR noktaları (AUTONOMOUS_BRIEF.md §3, §5) her zaman geçerlidir.

---

## 1. Labels / Etiketler

| Label | Meaning (EN) | Anlamı (TR) |
|-------|--------------|-------------|
| `task` | A work item. Everything to be done is a `task` issue. | İş kalemi. Yapılacak her şey `task` issue'sudur. |
| `agent:joi` | Held by Joi. | Joi üstlendi. |
| `agent:cursor` | Held by a Cursor agent. | Cursor ajanı üstlendi. |
| `status:in-progress` | Claimed, being worked on. | Üstlenildi, üzerinde çalışılıyor. |
| `status:blocked` | Blocked (reason in a comment; often waiting for the owner). | Engelli (sebep yorumda; çoğu zaman sahibi bekleniyor). |
| `handoff` | Holder stopped; up for grabs. | Sahibi bıraktı; isteyen alabilir. |
| `owner` | Owner-only (accounts, money, keys, publishing, real devices, decisions). Agents never claim it and never put an agent label on it. | Yalnızca sahibi (hesap, para, anahtar, yayın, gerçek cihaz, karar). Ajanlar üstlenmez, ajan etiketi koymaz. |

An issue with `task`, no agent label and no `owner` label is **free**.
(TR: `task` olup ajan etiketi ve `owner` etiketi olmayan issue **boştur**.)

## 2. Session start / Oturum başı (every session / her oturum)

```bash
git fetch --all --prune
cat docs/AGENT_LOG.md | tail -60              # what the other side did / diğer taraf ne yaptı
gh issue list --label task --state open       # all open work / tüm açık işler
gh issue list --label status:in-progress      # who holds what / kim neyi tutuyor
gh issue list --label handoff                 # up for grabs / devralınabilir
gh pr list                                    # open PRs / açık PR'lar
```

## 3. Claim / Üstlenme

1. Pick a **free** or `handoff` issue (prefer the lowest number unless the issue says otherwise;
   skip `owner` and `status:blocked`).
2. Check it is **not held by the other side** (no `agent:*` + `status:in-progress`).
3. Add your label + `status:in-progress` (remove `handoff` if present) and comment:
   ```
   CLAIM <joi|cursor> <ISO-8601 time, e.g. 2026-09-26T10:07+03:00>
   Plan: <3–6 bullet steps>
   Branch: <joi|cursor>/<issue#>-<slug>
   ```
4. Re-read the issue right after claiming. If the other side claimed it within the same minutes
   (race), the **earlier CLAIM comment wins**; the later side removes its labels and comments `UNCLAIM`.
5. Hold **one** claimed issue per side at a time, max **two**.

(TR: Boş ya da `handoff` bir issue seç, diğer tarafta olmadığını kontrol et, kendi etiketini +
`status:in-progress` ekle, `CLAIM <ajan> <zaman>` + plan + dal adı yorumla. Çakışmada önce yazılan
CLAIM kazanır. Aynı anda ideal 1, en fazla 2 issue.)

## 4. Branches and heartbeat / Dallar ve heartbeat

- Branch name: `joi/<issue#>-<slug>` or `cursor/<issue#>-<slug>`, based on the branch with the
  **latest work** (today: `cursor-rules` → `v0.2-calculator-workprofile`; after the owner merges,
  the merged base). PR into that base branch.
- **Push work in progress often** (at least at the end of every session), even if unfinished, so
  the other side can continue it. WIP commits must still build; mark them `wip:` if tests are not
  yet green, and make the final commits pass the gates (`flutter analyze` clean, `flutter test` green).
- **Heartbeat:** at least one comment per working session on the claimed issue:
  ```
  HEARTBEAT <agent> <time>
  Done: ...
  Branch: ... (last commit <sha>)
  Next: ...
  Questions: ... (or none)
  ```

(TR: Dal adı `joi/<no>-<kısa-ad>` ya da `cursor/<no>-<kısa-ad>`; en güncel dalın üstüne. Yarım işi
sık push et. Her çalışma oturumunda en az bir HEARTBEAT yorumu: ne bitti, dal, sonraki adım, sorular.)

## 5. Handoff / Devretme

When you stop before finishing (session ends, blocked, out of time) and do not plan to continue
next session:

```
HANDOFF <agent> <time>
State: <what works, what doesn't>
Branch: <name> (last commit <sha>, pushed)
Remaining: <exact next steps, checklist>
Notes: <gotchas, failing tests, decisions taken>
```

Then remove your agent label and `status:in-progress`, add `handoff`.
(TR: Bitirmeden bırakırsan HANDOFF yorumu yaz — tam durum, dal, kalan adımlar — etiketleri kaldır, `handoff` ekle.)

## 6. Takeover / Devralma (silent side / sessiz taraf)

If an issue is `status:in-progress` and **both** its branch has no new commit **and** the issue
has no new comment for **24 hours**, the other side may take it over:

1. Comment `TAKEOVER <agent> <time>` + why (e.g. "no commit/comment since <time>") + plan.
2. Swap the agent label to yours (keep `status:in-progress`).
3. **Continue from the existing branch** (check it out and add commits on top; do not restart and
   do not rewrite its history). If you must diverge, branch from it: `<you>/<issue#>-<slug>-cont`.
4. Credit the previous work in the PR description and in the AGENT_LOG entry.

(TR: `status:in-progress` bir issue'da 24 saat boyunca ne dalda commit ne de yorum varsa diğer
taraf `TAKEOVER <ajan> <zaman>` yazar, etiketi değiştirir, mevcut daldan devam eder — sıfırdan
başlamaz, geçmişi yeniden yazmaz — ve önceki emeği anar.)

## 7. Done / Bitti

- Open a PR with `Closes #N` in the description (TR + EN, one line per changed file, analyze/test
  result, remaining work, per `.cursor/rules/40-workflow-testing.mdc`).
- Comment a completion summary on the issue: `DONE <agent> <time>` + PR link + what changed.
- Append **one line** to `PROGRESS.md` (today's paragraph) and an entry to `docs/AGENT_LOG.md`.
- The **owner merges PRs**. Agents never merge their own or each other's PRs.

(TR: PR açıklamasında `Closes #N`; issue'ya `DONE` özeti; PROGRESS.md'ye bir satır;
AGENT_LOG'a girdi. PR'ları yalnızca sahibi birleştirir.)

## 8. Agent log / Ajan günlüğü (`docs/AGENT_LOG.md`)

Every session appends a dated entry at the **bottom** (append-only; never rewrite past entries):

```
## 2026-09-26 10:07 +03:00 — joi
- Finished: ...
- In progress: #N on branch ... (state)
- Next: ...
- For the other side: ... (questions, warnings, handoffs)
```

## 9. Conflicts and safety / Çakışma ve güvenlik

- Never push to or edit the other side's in-progress branch without a TAKEOVER.
- **Never force-push shared branches** or rewrite history (brief §5 stop point).
- If two PRs touch the same files, the later PR rebases/merges the base **locally** into a new
  commit (merge commit, no force-push) and resolves conflicts; note it in the PR.
- The hard bans (`.cursor/rules/10-hard-bans-and-security.mdc`, brief §3) and stop points
  (brief §5: Play upload/publishing, real payments/Play Billing, spending, account creation,
  sending personal data out, force-push) always apply. Stop points → `BLOCKERS.md` + an `owner` issue.
- Issues, comments, logs and commits must **never contain secrets** (keystores, passwords,
  tokens, login/device codes, personal data).
- New work discovered while working → open a new `task` issue (from the brief/docs; don't invent
  features outside the brief). Owner decisions → `owner` label, no agent label.
