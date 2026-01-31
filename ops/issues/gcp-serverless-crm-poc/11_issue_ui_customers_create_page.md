# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Create a UI screen to add a new customer (name + minimal fields) that calls POST /api/customers and navigates back to list/detail on success.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Create customer page exists and is auth-protected
- [ ] Submitting valid form calls POST /api/customers and shows created customer (redirect or success state)
- [ ] Validation errors from API are shown safely (no stack traces)
- [ ] At least one UI/integration test covers success and failure state
- [ ] No secrets are stored or logged in the browser console by default
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add create page route and form UI.
2) Wire submission to POST /api/customers.
3) Handle loading/success/error states.
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
- app/customers/new/page.tsx (or equivalent)
- tests/ui/customer_create.test.ts
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
- Title: [AI] Build customer create UI (area:ui)
- Requirements:
- [ ] Create customer page exists and is auth-protected
- [ ] Submitting valid form calls POST /api/customers and shows created customer (redirect or success state)
- [ ] Validation errors from API are shown safely (no stack traces)
- [ ] At least one UI/integration test covers success and failure state
- [ ] No secrets are stored or logged in the browser console by default
