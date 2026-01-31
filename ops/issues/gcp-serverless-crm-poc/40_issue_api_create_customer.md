# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement an authenticated API endpoint to create a customer record with server-side validation and appropriate error handling.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] POST /api/customers creates a customer and returns 201 + created payload
- [ ] Invalid payload returns 400 with safe error message (no stack trace)
- [ ] Endpoint requires authentication (unauthenticated => 401/302 as applicable)
- [ ] Automated test covers success + invalid payload
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add route handler for POST /api/customers.
2) Validate required fields and normalize input.
3) Persist customer in DB and return created entity (or minimal DTO).
4) Add tests (success + validation error).

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
- lib/api/request.ts / validation helpers
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
- Title: [AI] Add create customer API (POST) (area:api)
- Requirements:
- [ ] POST /api/customers creates a customer and returns 201 + created payload
- [ ] Invalid payload returns 400 with safe error message (no stack trace)
- [ ] Endpoint requires authentication (unauthenticated => 401/302 as applicable)
- [ ] Automated test covers success + invalid payload
