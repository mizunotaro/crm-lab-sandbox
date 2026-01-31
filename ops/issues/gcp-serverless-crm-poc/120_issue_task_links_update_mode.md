# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
publish-issues スクリプトの「Spec への Task Links 自動生成」を **更新型（Option 2）**に変更し、同一Specに対して実行を繰り返しても **Task Links コメントが増殖しない（重複ゼロ）**状態を実現する。
具体的には、Spec Issue に既存の自動生成 Task Links コメント（marker付き）がある場合は **そのコメントを編集更新**し、無い場合のみ **新規コメント作成**する。

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] `publish-issues_*.ps1` の Task Links 投稿は「更新型」になり、2回以上実行しても Spec Issue の Task Links コメントが増殖しない
- [ ] 自動生成コメントには固定の marker（例：`<!-- TASK_LINKS_AUTOGEN v1 -->`）が含まれる
- [ ] marker コメントが既に存在する場合：新規コメント作成ではなく **既存コメントの更新（PATCH）**が行われる
- [ ] marker コメントが存在しない場合：**新規コメント作成（POST）**が行われる
- [ ] 生成内容が既存コメントと同一の場合：更新をスキップし、無駄な編集をしない（idempotent + low-noise）
- [ ] DryRun 時：GitHubへの変更（POST/PATCH）を行わず、「would update/create/skip」のみを出力する
- [ ] 既存の publish の主要動作（Issue作成の冪等性、検索非依存の確定的解決）を壊さない
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- Do not print full Task Links body to logs (avoid noisy logs / accidental leakage). Log only counts + comment id + action result.
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Locate the Task Links generation code path (the block that currently does `gh issue comment --repo ...`).
2) Introduce a marker constant (e.g., `<!-- TASK_LINKS_AUTOGEN v1 -->`) and ensure it is included in the generated body.
3) Implement helper functions (PowerShell):
   - `Get-SpecIssueNumber()` (existing logic may already exist)
   - `Get-SpecComments()` via `gh api` (not search) to fetch comments JSON
   - `Find-AutogenTaskLinksComment()` to find the best target comment:
     - Prefer the most recent comment containing the marker
     - If multiple exist, update the newest one and (optionally) warn (do NOT delete)
   - `Build-TaskLinksBody()` (existing) but ensure marker header + stable formatting
   - `Update-Or-Create-TaskLinksComment()`:
     - If none found → create comment (POST)
     - If found:
       - If body identical → skip
       - Else → update comment by id (PATCH)
4) Keep current behavior behind a small option if needed (Decision Gate): add `-TaskLinksWriteMode append|update` default `update`.
5) Add verification steps (script output + gh api checks) and document in PR description:
   - Pre/post counts of marker comments should remain 1
   - Run script twice and confirm “create once, then update/skip” behavior
6) Run local checks (lint/typecheck/test/build as applicable) and ensure CI is green.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Comment selection when multiple marker comments exist:
  - Option A (recommended): Update the newest marker comment; leave others untouched; print a warning with the list of duplicate comment IDs (no bodies)
    - Pros: Safe, non-destructive, small diff
    - Cons: Old duplicates remain
    - Rollback: revert to previous behavior; duplicates remain but no harm
  - Option B: Attempt to “consolidate” by deleting older marker comments
    - Pros: Cleans history
    - Cons: Destructive; higher risk; requires delete privileges; violates safety preference
    - Rollback: difficult (deleted comments not easily restored)
  - Decision criteria: prefer non-destructive + smallest change (Option A)

- Whether to add a new flag `-TaskLinksWriteMode`:
  - Option A (recommended): Add flag with default `update` and keep `append` for emergency rollback
    - Pros: Safe rollback path, explicit behavior
    - Cons: Slightly more code
  - Option B: Hard switch to update-only (no flag)
    - Pros: Minimal surface area
    - Cons: No easy rollback without code revert
  - Decision criteria: prioritize operational safety and rollback (Option A)

# 6) Context / Links
- Files/dirs:
- `ops/scripts/publish-issues_*.ps1` (Task Links generation block)
- `ops/issues/gcp-serverless-crm-poc/` (Issue SSOT)
- Related issues/PRs:
- Parent Spec: (fill actual Spec issue number in PR description; e.g., #9 in current environment)
- Screenshots/logs:
- N/A

# 7) Risk Level
medium

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Make Spec Task Links update-in-place (no duplicates) (area:ops)
- Requirements:
- [ ] `publish-issues_*.ps1` の Task Links 投稿は「更新型」になり、2回以上実行しても Spec Issue の Task Links コメントが増殖しない
- [ ] 自動生成コメントには固定の marker（例：`<!-- TASK_LINKS_AUTOGEN v1 -->`）が含まれる
- [ ] marker コメントが既に存在する場合：新規コメント作成ではなく **既存コメントの更新（PATCH）**が行われる
- [ ] marker コメントが存在しない場合：**新規コメント作成（POST）**が行われる
- [ ] 生成内容が既存コメントと同一の場合：更新をスキップし、無駄な編集をしない（idempotent + low-noise）
- [ ] DryRun 時：GitHubへの変更（POST/PATCH）を行わず、「would update/create/skip」のみを出力する
- [ ] 既存の publish の主要動作（Issue作成の冪等性、検索非依存の確定的解決）を壊さない
