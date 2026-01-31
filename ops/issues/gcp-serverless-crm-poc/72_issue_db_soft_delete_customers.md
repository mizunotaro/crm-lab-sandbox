# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement soft-delete (deletedAt) for customers and ensure list/detail APIs respect it (exclude by default).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Schema adds deletedAt to customers with migration
- [ ] DELETE API sets deletedAt instead of hard delete (or add new endpoint) (Decision Gate)
- [ ] List and detail APIs exclude soft-deleted customers by default
- [ ] Automated tests cover soft-delete behavior
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add deletedAt column and migrate.
2) Update delete handler to set deletedAt.
3) Update queries to filter deletedAt IS NULL.
4) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Confirm whether hard delete is acceptable for PoC; if yes, skip this issue.

# 6) Context / Links
- Files/dirs:
- prisma/schema.prisma
- app/api/customers/[id]/route.ts
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
- Title: [AI] Add soft-delete for customers (area:db)
- Requirements:
- [ ] Schema adds deletedAt to customers with migration
- [ ] DELETE API sets deletedAt instead of hard delete (or add new endpoint) (Decision Gate)
- [ ] List and detail APIs exclude soft-deleted customers by default
- [ ] Automated tests cover soft-delete behavior
