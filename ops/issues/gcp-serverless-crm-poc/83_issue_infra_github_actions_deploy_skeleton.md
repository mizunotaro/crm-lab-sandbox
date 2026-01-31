# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a deploy workflow skeleton that can deploy to Cloud Run using Workload Identity Federation (recommended) with placeholders and clear TODOs.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] A deploy workflow file exists but is safe-by-default (disabled or manual dispatch) (Eval)
- [ ] Workflow contains placeholders for WIF and does not require storing long-lived keys
- [ ] No secrets printed in logs
- [ ] CI remains green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? Yes (requires label ai:deps)

# 4) Suggested Plan (optional but recommended)
1) Add workflow_dispatch deploy skeleton.
2) Document required secrets/vars names (placeholders).
3) Ensure it is not auto-triggered unless intended.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Decide whether to keep deploy workflow disabled until WIF is configured.

# 6) Context / Links
- Files/dirs:
- .github/workflows/deploy-cloud-run.yml (new)
- docs/deploy/github-actions-wif.md (new)
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
high

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Add GitHub Actions deploy skeleton for Cloud Run (area:ci) [needs ai:deps]
- Requirements:
- [ ] A deploy workflow file exists but is safe-by-default (disabled or manual dispatch) (Eval)
- [ ] Workflow contains placeholders for WIF and does not require storing long-lived keys
- [ ] No secrets printed in logs
- [ ] CI remains green
