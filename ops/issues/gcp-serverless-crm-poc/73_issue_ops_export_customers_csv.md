# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a CSV export endpoint for customers with basic CSV injection mitigations and tests.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Authenticated users can download customers CSV
- [ ] CSV formula injection mitigations applied (prefix dangerous values) (Eval)
- [ ] Automated test validates content-type and at least one row
- [ ] No new deps
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add CSV serializer helper.
2) Add /api/customers/export route.
3) Add tests.

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
- app/api/customers/export/route.ts
- lib/export/csv.ts
- tests/api/customers_export.test.ts
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
- Title: [AI] Add customers CSV export endpoint (area:ops)
- Requirements:
- [ ] Authenticated users can download customers CSV
- [ ] CSV formula injection mitigations applied (prefix dangerous values) (Eval)
- [ ] Automated test validates content-type and at least one row
- [ ] No new deps
