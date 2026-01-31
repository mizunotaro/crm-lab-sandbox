# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a lightweight coverage reporting step (if existing test runner supports it) without introducing new dependencies unless already present.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] CI outputs coverage summary (best-effort) (Eval)
- [ ] No new deps unless issue has ai:deps
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
1) Check current test runner capabilities.
2) Enable coverage output if supported.
3) Add CI step to publish summary.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If enabling coverage requires new deps, mark ai:blocked or require ai:deps label.

# 6) Context / Links
- Files/dirs:
- package.json scripts
- .github/workflows/ci.yml
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
medium

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Add minimal test coverage reporting (area:test)
- Requirements:
- [ ] CI outputs coverage summary (best-effort) (Eval)
- [ ] No new deps unless issue has ai:deps
- [ ] CI remains green
