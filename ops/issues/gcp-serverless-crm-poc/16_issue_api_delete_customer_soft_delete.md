# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement an authenticated endpoint to soft-delete a customer via DELETE /api/customers/:id by setting deletedAt.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] DELETE /api/customers/:id returns 204 (or 200) for authenticated users when successful
- [ ] Returns 404 for non-existent or already deleted customers
- [ ] Unauthenticated requests return 401 (or redirect per policy)
- [ ] Automated tests cover 204/401/404 cases
- [ ] Deletion does not remove rows physically; it sets deletedAt
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add DELETE handler for /api/customers/:id.
2) Implement repository soft-delete method.
3) Add tests for auth and idempotency/404 behavior.
4) Ensure responses do not leak internal details.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If API should return 204 vs 200 with body, mark ai:blocked and propose options.

# 6) Context / Links
- Files/dirs:
- app/api/customers/[id]/route.ts (or equivalent)
- lib/db/repositories/customer
- tests/api/customer_delete.test.ts
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
- Title: [AI] Add customer delete API (soft delete) (area:api)
- Requirements:
- [ ] DELETE /api/customers/:id returns 204 (or 200) for authenticated users when successful
- [ ] Returns 404 for non-existent or already deleted customers
- [ ] Unauthenticated requests return 401 (or redirect per policy)
- [ ] Automated tests cover 204/401/404 cases
- [ ] Deletion does not remove rows physically; it sets deletedAt
