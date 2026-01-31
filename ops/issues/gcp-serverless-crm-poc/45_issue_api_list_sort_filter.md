# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add optional query params for sorting and filtering to customers list API while keeping backward compatibility.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] GET /api/customers supports ?sort=...&order=... with allowlist
- [ ] GET /api/customers supports ?q=... (simple substring search) without SQL injection risk
- [ ] Automated test covers at least one sort and one search case
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add allowlisted sort fields and default ordering.
2) Add optional search query param with safe parameterization.
3) Add tests for sort/search.

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
- app/api/customers/route.ts
- tests/api/customers_list_sort_search.test.ts
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
- Title: [AI] Enhance customers list API with sort + filter (area:api)
- Requirements:
- [ ] GET /api/customers supports ?sort=...&order=... with allowlist
- [ ] GET /api/customers supports ?q=... (simple substring search) without SQL injection risk
- [ ] Automated test covers at least one sort and one search case
