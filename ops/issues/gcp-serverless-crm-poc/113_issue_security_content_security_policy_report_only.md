# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
If CSP is set to report-only, add a minimal report endpoint/handler to receive CSP violation reports safely (store only aggregate or log).

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] CSP report endpoint exists and returns 204/200
- [ ] Endpoint does not log sensitive payloads verbatim (redaction applied)
- [ ] Automated test validates endpoint responds successfully
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add /api/security/csp-report handler.
2) Redact/limit logged fields.
3) Add test.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If CSP is enforced (not report-only), this issue may be skipped.

# 6) Context / Links
- Files/dirs:
- app/api/security/csp-report/route.ts (new)
- lib/logging/redact.ts
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
- Title: [AI] Add CSP report-only endpoint (optional) (area:security)
- Requirements:
- [ ] CSP report endpoint exists and returns 204/200
- [ ] Endpoint does not log sensitive payloads verbatim (redaction applied)
- [ ] Automated test validates endpoint responds successfully
