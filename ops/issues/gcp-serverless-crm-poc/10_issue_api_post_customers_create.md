# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement an authenticated endpoint to create a Customer record via POST /api/customers with minimal validation and stable response typing.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] POST /api/customers returns 201 with created customer for authenticated users
- [ ] Unauthenticated requests return 401 (or redirect per policy)
- [ ] Request body validation rejects missing/empty name with 400
- [ ] Automated tests cover 201/400/401 cases
- [ ] No sensitive data is logged on validation or errors
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add POST handler for /api/customers with minimal validation.
2) Implement DB repository create method.
3) Add tests for auth and validation.
4) Update internal dev docs for endpoint usage.

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
- tests/api/customers_create.test.ts
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
- Title: [AI] Add customers create API (POST) (area:api)
- Requirements:
- [ ] POST /api/customers returns 201 with created customer for authenticated users
- [ ] Unauthenticated requests return 401 (or redirect per policy)
- [ ] Request body validation rejects missing/empty name with 400
- [ ] Automated tests cover 201/400/401 cases
- [ ] No sensitive data is logged on validation or errors
