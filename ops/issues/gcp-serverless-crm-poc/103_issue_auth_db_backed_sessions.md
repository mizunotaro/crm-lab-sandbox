# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement DB-backed sessions (table + middleware changes) for better server-side invalidation and multi-instance support.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] DB schema adds Sessions table with one migration
- [ ] Login creates session record; logout deletes it
- [ ] Auth middleware validates session against DB
- [ ] Automated tests cover login/logout and session invalidation
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add sessions table and migration.
2) Update login/logout to create/delete sessions.
3) Update auth middleware to check session id.
4) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If current design is JWT-only, mark ai:blocked and propose minimal DB session plan.

# 6) Context / Links
- Files/dirs:
- prisma/schema.prisma
- lib/auth/session.ts
- tests/auth/db_sessions.test.ts
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
- Title: [AI] Add DB-backed sessions (area:auth)
- Requirements:
- [ ] DB schema adds Sessions table with one migration
- [ ] Login creates session record; logout deletes it
- [ ] Auth middleware validates session against DB
- [ ] Automated tests cover login/logout and session invalidation
