# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Document and configure recommended Cloud SQL connection approach (connector/Unix socket) for Cloud Run without embedding credentials.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Docs explain Cloud SQL connection method used by app
- [ ] App configuration reads DB connection from environment variables
- [ ] No secrets committed; uses placeholders in docs
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Document connection method and env vars required.
2) Ensure app reads connection string safely.
3) Add sanity check docs.

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
- docs/deploy/cloudsql-connection.md (new)
- app DB config module
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
- Title: [AI] Document Cloud SQL connection strategy for Cloud Run (area:infra)
- Requirements:
- [ ] Docs explain Cloud SQL connection method used by app
- [ ] App configuration reads DB connection from environment variables
- [ ] No secrets committed; uses placeholders in docs
