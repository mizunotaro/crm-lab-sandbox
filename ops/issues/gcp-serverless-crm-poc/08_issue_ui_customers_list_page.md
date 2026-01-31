# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Create a customers list page that calls GET /api/customers, supports basic search and pagination, and is accessible only after login.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Customers list page renders customer rows from API
- [ ] Search input triggers list refresh (debounce optional)
- [ ] Pagination control exists (next/prev or page numbers) based on API parameters
- [ ] Unauthenticated access redirects to login
- [ ] UI behavior is covered by at least one test (component/integration)
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Create customers list page route.
2) Integrate API call and render list states (loading/empty/error).
3) Add search + pagination controls.
4) Add minimal tests for render/redirect behavior.

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
- app/customers/page.tsx (or equivalent)
- lib/api/client (if exists)
- tests/ui/customers_list.test.ts
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
- Title: UI: Customers list page (search + pagination)
- Requirements:
- [ ] Customers list page renders customer rows from API
- [ ] Search input triggers list refresh (debounce optional)
- [ ] Pagination control exists (next/prev or page numbers) based on API parameters
- [ ] Unauthenticated access redirects to login
- [ ] UI behavior is covered by at least one test (component/integration)
