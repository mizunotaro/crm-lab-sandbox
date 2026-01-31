# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Enforce a basic password policy for any user creation/seed flows (length + simple complexity), without storing plaintext.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Password policy is defined in one place (min length etc.)
- [ ] User creation/seed rejects/avoids weak passwords (Eval for PoC seed)
- [ ] Automated test covers policy helper
- [ ] No new dependencies
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add password policy helper.
2) Apply to user seed and any future user create endpoints.
3) Add unit test.

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
- lib/auth/passwordPolicy.ts (new)
- seed scripts
- tests/auth/password_policy.test.ts
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
- Title: [AI] Enforce basic password policy (area:auth)
- Requirements:
- [ ] Password policy is defined in one place (min length etc.)
- [ ] User creation/seed rejects/avoids weak passwords (Eval for PoC seed)
- [ ] Automated test covers policy helper
- [ ] No new dependencies
