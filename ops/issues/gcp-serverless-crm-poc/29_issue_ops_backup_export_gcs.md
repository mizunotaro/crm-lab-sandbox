# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a CSV export endpoint for customers and (optionally) a script to upload exports to GCS using workload identity / ADC (no hardcoded creds).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Authenticated users can export customers to CSV (download)
- [ ] CSV export avoids formula injection (prefix dangerous cells) (Eval)
- [ ] Optional: upload script uses ADC and does not store credentials in repo (Eval)
- [ ] Automated test validates CSV export content-type and basic shape
- [ ] No dependency changes unless explicitly marked ai:deps
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement CSV serialization for customer list (safe escaping).
2) Add export route handler (auth-protected).
3) Add tests for response headers and sample row.
4) Optionally add ops script for GCS upload using ADC with clear docs (Eval).

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If adding GCS upload needs additional libraries/tools, mark ai:blocked or add [needs ai:deps] and request label.

# 6) Context / Links
- Files/dirs:
- app/api/customers/export/route.ts (or equivalent)
- lib/export/csv.ts (new)
- tests/api/customers_export.test.ts
- ops/scripts/upload-export-to-gcs.ps1 (optional) (Eval)
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
- Title: [AI] Add customer export (CSV) + optional GCS upload (area:ops)
- Requirements:
- [ ] Authenticated users can export customers to CSV (download)
- [ ] CSV export avoids formula injection (prefix dangerous cells) (Eval)
- [ ] Optional: upload script uses ADC and does not store credentials in repo (Eval)
- [ ] Automated test validates CSV export content-type and basic shape
- [ ] No dependency changes unless explicitly marked ai:deps
