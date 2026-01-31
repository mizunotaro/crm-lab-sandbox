# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add an AuditLog table and write minimal audit entries for customer create/update/delete actions (who/when/what).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Schema adds AuditLog table with one migration in this PR
- [ ] Customer create/update/delete write an AuditLog record with actor userId and action type
- [ ] AuditLog does not store secrets (no passwords/tokens)
- [ ] Automated tests verify at least one audit entry is created for a customer mutation
- [ ] No dependency changes
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add AuditLog schema and migration.
2) Add repository helper to write audit logs.
3) Hook into customer mutation handlers to write logs.
4) Add tests for audit logging.

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
- lib/db/repositories/auditLog (new)
- app/api/customers/... route handlers
- tests/audit/auditlog.test.ts
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
- Title: [AI] Add AuditLog table + minimal write hooks (area:db)
- Requirements:
- [ ] Schema adds AuditLog table with one migration in this PR
- [ ] Customer create/update/delete write an AuditLog record with actor userId and action type
- [ ] AuditLog does not store secrets (no passwords/tokens)
- [ ] Automated tests verify at least one audit entry is created for a customer mutation
- [ ] No dependency changes
