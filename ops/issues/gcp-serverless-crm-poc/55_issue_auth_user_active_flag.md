# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a user 'active' flag so disabled users cannot log in, supporting basic admin control.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] DB schema adds a boolean active flag for users with a migration
- [ ] Login denies inactive users with safe message
- [ ] Automated test covers inactive login denial
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add active flag in schema and migrate.
2) Update login logic to check active.
3) Update seed to set active=true.
4) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
N/A

# 6) Context / Links
- Files/dirs:
- prisma/schema.prisma (or DB schema)
- app/api/auth/login/route.ts
- tests/auth/inactive_user.test.ts
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
- Title: [AI] Add user active/disabled flag (area:auth)
- Requirements:
- [ ] DB schema adds a boolean active flag for users with a migration
- [ ] Login denies inactive users with safe message
- [ ] Automated test covers inactive login denial
