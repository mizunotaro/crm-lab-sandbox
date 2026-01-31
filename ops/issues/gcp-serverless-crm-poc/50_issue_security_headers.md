# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add baseline HTTP security headers (CSP-safe default, X-Content-Type-Options, Referrer-Policy, etc.) via middleware or framework config.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Security headers are set on all responses (or documented exceptions)
- [ ] CSP is present (can be report-only initially) (Eval)
- [ ] Automated test verifies at least 2 headers exist on a page/API response
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Implement middleware/config to set headers.
2) Start with safe defaults and avoid breaking scripts/styles.
3) Add tests for header presence.

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
- middleware.ts / next.config.js
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
- Title: [AI] Add security headers baseline (area:security)
- Requirements:
- [ ] Security headers are set on all responses (or documented exceptions)
- [ ] CSP is present (can be report-only initially) (Eval)
- [ ] Automated test verifies at least 2 headers exist on a page/API response
