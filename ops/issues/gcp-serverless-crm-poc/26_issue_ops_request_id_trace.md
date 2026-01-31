# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Generate/propagate a request-id for each request (UI + API) and include it in responses and logs for troubleshooting.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Each request gets a request-id (header X-Request-Id or equivalent)
- [ ] API responses include the request-id header
- [ ] Logs include the same request-id for correlation
- [ ] At least one test validates request-id presence on a route
- [ ] No dependency changes
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement request-id middleware/helper.
2) Add to API routes and key pages.
3) Integrate with logger utility (if present).
4) Add test for header presence.

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
- middleware.ts (or equivalent)
- lib/ops/requestId.ts (new)
- tests/ops/request_id.test.ts
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
- Title: [AI] Add request-id propagation (area:ops)
- Requirements:
- [ ] Each request gets a request-id (header X-Request-Id or equivalent)
- [ ] API responses include the request-id header
- [ ] Logs include the same request-id for correlation
- [ ] At least one test validates request-id presence on a route
- [ ] No dependency changes
