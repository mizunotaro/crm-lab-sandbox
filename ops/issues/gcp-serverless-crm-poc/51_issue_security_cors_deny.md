# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Ensure API routes do not allow cross-origin credentialed requests unless explicitly required.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] API responses do not include permissive Access-Control-Allow-Origin with credentials
- [ ] If CORS is needed for specific endpoints, it is allowlisted and documented
- [ ] Test validates CORS headers are absent or restrictive
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Review current CORS behavior.
2) Add explicit restrictive policy in middleware/handlers.
3) Add test for headers.

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
- middleware.ts / lib/security/cors.ts
- tests/security/cors.test.ts
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
- Title: [AI] Restrict CORS policy (area:security)
- Requirements:
- [ ] API responses do not include permissive Access-Control-Allow-Origin with credentials
- [ ] If CORS is needed for specific endpoints, it is allowlisted and documented
- [ ] Test validates CORS headers are absent or restrictive
