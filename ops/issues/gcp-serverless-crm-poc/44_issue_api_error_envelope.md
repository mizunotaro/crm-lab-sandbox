# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Ensure API errors return a consistent JSON shape (code/message/requestId) and never include stack traces or internal paths.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] All API error responses follow one JSON envelope shape
- [ ] Envelope includes requestId if available
- [ ] At least one test asserts the envelope keys
- [ ] No stack traces in response bodies
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Define error envelope type and helper to create responses.
2) Update existing endpoints to use it.
3) Add tests for error shape.

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
- lib/api/errors.ts (new or updated)
- tests/api/error_envelope.test.ts
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
- Title: [AI] Standardize API error envelope (area:api)
- Requirements:
- [ ] All API error responses follow one JSON envelope shape
- [ ] Envelope includes requestId if available
- [ ] At least one test asserts the envelope keys
- [ ] No stack traces in response bodies
