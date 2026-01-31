# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Implement an authenticated API endpoint to update an existing customer record (partial update) with validation and not-found handling.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] PATCH /api/customers/:id updates allowed fields and returns 200
- [ ] Non-existent id returns 404
- [ ] Invalid payload returns 400
- [ ] Automated test covers update success + 404
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add PATCH handler for /api/customers/[id].
2) Validate id and payload; restrict fields to an allowlist.
3) Update DB; return updated entity/DTO.
4) Add tests (200 + 404).

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
- app/api/customers/[id]/route.ts
- tests/api/customers_update.test.ts
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
- Title: [AI] Add update customer API (PATCH) (area:api)
- Requirements:
- [ ] PATCH /api/customers/:id updates allowed fields and returns 200
- [ ] Non-existent id returns 404
- [ ] Invalid payload returns 400
- [ ] Automated test covers update success + 404
