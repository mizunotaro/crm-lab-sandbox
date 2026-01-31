# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Add a safe seed mechanism to create one demo user and a small set of sample customers for PoC without hardcoding any credentials.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] A seed command exists (e.g., `pnpm seed`) that creates demo user only when env vars are provided
- [ ] Seed reads DEMO_USER_ID and DEMO_USER_PASSWORD from environment; stores only password hash
- [ ] Seed inserts at least 5 sample customers with non-sensitive dummy data
- [ ] CI can run seed with non-secret dummy env values (set in workflow) to validate behavior
- [ ] Seed is idempotent (re-running does not create duplicates unexpectedly)
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? No

# 4) Suggested Plan (optional but recommended)
1) Add seed script under `scripts/seed`.
2) Use DB layer to upsert demo user and sample customers.
3) Add tests verifying seed safety (no action when env missing).
4) Wire CI to run seed against ephemeral DB with dummy values.

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
- scripts/seed (new)
- lib/db
- .github/workflows/ci.yml
- Related issues/PRs:
- Screenshots/logs:

# 7) Risk Level
high

# 8) Reporting requirement (daily + completion)
- During work: update PR description with progress + verification
- When “done & deployable”: comment back to Issue with:
  - Summary (EN+JP)
  - Verification evidence (commands + CI link)
  - Risk/rollback

対象タスク（Titleと要件）:
- Title: Seed: Demo user + sample customers via environment variables
- Requirements:
- [ ] A seed command exists (e.g., `pnpm seed`) that creates demo user only when env vars are provided
- [ ] Seed reads DEMO_USER_ID and DEMO_USER_PASSWORD from environment; stores only password hash
- [ ] Seed inserts at least 5 sample customers with non-sensitive dummy data
- [ ] CI can run seed with non-secret dummy env values (set in workflow) to validate behavior
- [ ] Seed is idempotent (re-running does not create duplicates unexpectedly)
