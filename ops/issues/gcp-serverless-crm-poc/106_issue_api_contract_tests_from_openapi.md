# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add basic contract tests against OpenAPI (or minimal schema assertions) to reduce drift; requires additional tooling if not present.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Contract tests run in CI and validate key endpoints response shape
- [ ] No secrets required
- [ ] Issue must be labeled ai:deps if new tooling is introduced
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? Yes (requires label ai:deps)

# 4) Suggested Plan (optional but recommended)
1) Select minimal contract approach (lightweight).
2) Implement for 1-2 endpoints.
3) Wire into CI.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If adding tooling is too heavy, defer and keep only hand-written OpenAPI.

# 6) Context / Links
- Files/dirs:
- tests/contract/* (new)
- .github/workflows/ci.yml
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
- Title: [AI] Add basic API contract tests (area:test) [needs ai:deps]
- Requirements:
- [ ] Contract tests run in CI and validate key endpoints response shape
- [ ] No secrets required
- [ ] Issue must be labeled ai:deps if new tooling is introduced
