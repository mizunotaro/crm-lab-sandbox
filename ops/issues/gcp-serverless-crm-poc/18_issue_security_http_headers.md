# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Apply baseline security headers appropriate for an internal web app and verify headers are set consistently.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Responses include baseline headers (e.g., X-Frame-Options or frame-ancestors, Referrer-Policy, X-Content-Type-Options, Permissions-Policy) per defined policy
- [ ] CSP is minimal (CSP-lite) and does not break core pages
- [ ] Headers are applied consistently to app routes and API routes (as applicable)
- [ ] Automated test verifies presence of key headers on at least one route
- [ ] No dependency changes in this PR
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Define baseline header policy in code/docs.
2) Implement in Next.js config or middleware.
3) Add test to assert headers exist.
4) Verify local build and CI.

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
- middleware.ts (or next.config.js/ts)
- docs/security/headers.md (new or updated)
- tests/security/headers.test.ts
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
- Title: [AI] Add baseline security headers (area:security)
- Requirements:
- [ ] Responses include baseline headers (e.g., X-Frame-Options or frame-ancestors, Referrer-Policy, X-Content-Type-Options, Permissions-Policy) per defined policy
- [ ] CSP is minimal (CSP-lite) and does not break core pages
- [ ] Headers are applied consistently to app routes and API routes (as applicable)
- [ ] Automated test verifies presence of key headers on at least one route
- [ ] No dependency changes in this PR
