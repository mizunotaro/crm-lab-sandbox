# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Define and implement a stable pagination contract (limit/offset or cursor) for customers list API and document it in-code.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] List API accepts limit and offset (or cursor) with sane max limit
- [ ] Response includes pagination metadata (total/nextOffset or nextCursor)
- [ ] Automated test validates metadata behavior
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Choose limit/offset (default) with max cap.
2) Implement metadata fields in response.
3) Add tests for pagination behavior.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If cursor pagination already exists, prefer minimal changes and document current contract.

# 6) Context / Links
- Files/dirs:
- app/api/customers/route.ts
- tests/api/customers_list_pagination.test.ts
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
- Title: [AI] Add pagination contract to list API (area:api)
- Requirements:
- [ ] List API accepts limit and offset (or cursor) with sane max limit
- [ ] Response includes pagination metadata (total/nextOffset or nextCursor)
- [ ] Automated test validates metadata behavior
