# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Improve supply-chain security by pinning GitHub Actions used in workflows to commit SHAs (Decision Gate for effort).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] At least 1 workflow pins third-party actions to SHA (Eval)
- [ ] Docs note recommended pinning strategy and maintenance cost
- [ ] CI remains green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Identify third-party actions in workflows.
2) Pin to known SHA and verify workflow still works.
3) Document update process.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Decide whether to pin all actions now vs phase-in; optimize for security vs maintenance.

# 6) Context / Links
- Files/dirs:
- .github/workflows/*.yml
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
- Title: [AI] Pin GitHub Actions to full-length SHAs (area:ci)
- Requirements:
- [ ] At least 1 workflow pins third-party actions to SHA (Eval)
- [ ] Docs note recommended pinning strategy and maintenance cost
- [ ] CI remains green
