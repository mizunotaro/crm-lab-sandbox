# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add an authenticated endpoint to import customers from a CSV payload (small-batch) using the shared parser, with safe validation.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] POST /api/customers/import accepts CSV text/file and imports up to N rows (cap)
- [ ] Invalid rows are reported safely; import is transactional (all-or-nothing or documented partial) (Decision Gate)
- [ ] Automated test covers basic import of 2 rows
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
1) Add import handler with row cap and validation.
2) Decide transaction semantics and implement.
3) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Choose import semantics: A) all-or-nothing transaction, B) partial import with error report. Optimize for safety.

# 6) Context / Links
- Files/dirs:
- app/api/customers/import/route.ts (new)
- lib/import/csvParse.ts
- tests/api/customers_import.test.ts
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
high

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Add customers CSV import API (area:api)
- Requirements:
- [ ] POST /api/customers/import accepts CSV text/file and imports up to N rows (cap)
- [ ] Invalid rows are reported safely; import is transactional (all-or-nothing or documented partial) (Decision Gate)
- [ ] Automated test covers basic import of 2 rows
- [ ] No new deps
