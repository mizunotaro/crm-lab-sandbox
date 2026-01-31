# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a tags field to customers (simple string array or join table) with minimal API support.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Schema adds tags representation with one migration
- [ ] Create/update APIs accept tags (optional) with validation
- [ ] List API can filter by a tag (basic)
- [ ] Automated test covers tags roundtrip
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Choose simplest representation supported by DB/ORM.
2) Update APIs for tags field.
3) Add tests.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- Decide representation: A) string[] column, B) join table. Optimize for PoC simplicity.

# 6) Context / Links
- Files/dirs:
- prisma/schema.prisma
- app/api/customers/...
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
- Title: [AI] Add customer tags field (schema) (area:db)
- Requirements:
- [ ] Schema adds tags representation with one migration
- [ ] Create/update APIs accept tags (optional) with validation
- [ ] List API can filter by a tag (basic)
- [ ] Automated test covers tags roundtrip
