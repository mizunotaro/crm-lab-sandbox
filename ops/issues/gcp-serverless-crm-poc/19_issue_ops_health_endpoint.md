# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a simple health endpoint (e.g., GET /api/healthz) for Cloud Run readiness/liveness checks, with safe behavior and tests.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] GET /api/healthz returns 200 with a small JSON payload
- [ ] Endpoint does not expose secrets or internal details
- [ ] Optional: includes a lightweight DB connectivity check behind a flag (Eval)
- [ ] Automated test verifies 200 response
- [ ] CI remains green
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add /api/healthz route handler.
2) Implement safe response (and optional DB check via env flag).
3) Add test for 200 and payload shape.
4) Document intended use for Cloud Run.

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
- app/api/healthz/route.ts (or equivalent)
- tests/api/healthz.test.ts
- docs/deploy/gcp.md (optional update)
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
low

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: [AI] Add health endpoint for Cloud Run (area:ops)
- Requirements:
- [ ] GET /api/healthz returns 200 with a small JSON payload
- [ ] Endpoint does not expose secrets or internal details
- [ ] Optional: includes a lightweight DB connectivity check behind a flag (Eval)
- [ ] Automated test verifies 200 response
- [ ] CI remains green
