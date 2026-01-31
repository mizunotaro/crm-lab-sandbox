# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement a customer list API endpoint that supports basic search and pagination and is accessible only when authenticated.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] GET /api/customers returns 200 with customer list for authenticated users
- [ ] GET /api/customers returns 401 (or redirect per policy) when unauthenticated
- [ ] Supports query params: q (name partial match) and limit/offset (or cursor) for pagination
- [ ] Response schema is stable and typed; does not include sensitive fields
- [ ] Automated tests cover 200/401 and pagination/search behavior
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add route handler/controller for GET /api/customers.
2) Add DB query in repository with pagination/search.
3) Add tests for auth and query behavior.
4) Update docs for endpoint usage (dev only).

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
- app/api/customers/route.ts (or equivalent)
- lib/db/repositories/customer
- tests/api/customers.test.ts
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
- Title: API: GET /api/customers (list with search + pagination, auth required)
- Requirements:
- [ ] GET /api/customers returns 200 with customer list for authenticated users
- [ ] GET /api/customers returns 401 (or redirect per policy) when unauthenticated
- [ ] Supports query params: q (name partial match) and limit/offset (or cursor) for pagination
- [ ] Response schema is stable and typed; does not include sensitive fields
- [ ] Automated tests cover 200/401 and pagination/search behavior
