# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a soft-delete capability to Customer via a deletedAt field and update list/detail queries to ignore deleted records by default.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Schema adds Customer.deletedAt (nullable timestamp) with exactly one migration in this PR
- [ ] Customer list queries exclude deleted customers by default
- [ ] Customer detail returns 404 (or equivalent) when the record is soft-deleted
- [ ] Automated tests validate excluded/404 behavior
- [ ] No dependency changes in this PR
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add deletedAt to schema and generate one migration.
2) Update repository queries to filter deletedAt is null.
3) Update existing tests (or add new) for filtering behavior.
4) Document soft-delete semantics briefly (dev docs).

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
- prisma/schema.prisma (or db schema)
- lib/db/repositories/customer
- tests/api/customers_list.test.ts
- tests/api/customer_detail.test.ts
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
- Title: [AI] Add Customer soft-delete field + migration (area:db)
- Requirements:
- [ ] Schema adds Customer.deletedAt (nullable timestamp) with exactly one migration in this PR
- [ ] Customer list queries exclude deleted customers by default
- [ ] Customer detail returns 404 (or equivalent) when the record is soft-deleted
- [ ] Automated tests validate excluded/404 behavior
- [ ] No dependency changes in this PR
