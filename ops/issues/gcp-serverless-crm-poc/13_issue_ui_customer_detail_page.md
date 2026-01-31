# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Create a customer detail page that calls GET /api/customers/:id, displays fields, and provides navigation to edit.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Customer detail page exists and is auth-protected
- [ ] Displays customer data from GET /api/customers/:id
- [ ] Shows a safe 404 UI when customer is missing
- [ ] Provides link/button to edit screen
- [ ] At least one UI/integration test covers 200 and 404 rendering
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add customer detail page route.
2) Fetch and render customer details; implement 404 state.
3) Add navigation to edit.
4) Add minimal tests.

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
- app/customers/[id]/page.tsx (or equivalent)
- tests/ui/customer_detail.test.ts
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
- Title: [AI] Build customer detail UI (area:ui)
- Requirements:
- [ ] Customer detail page exists and is auth-protected
- [ ] Displays customer data from GET /api/customers/:id
- [ ] Shows a safe 404 UI when customer is missing
- [ ] Provides link/button to edit screen
- [ ] At least one UI/integration test covers 200 and 404 rendering
