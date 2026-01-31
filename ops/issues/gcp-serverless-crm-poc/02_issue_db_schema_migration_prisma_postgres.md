# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Introduce a minimal PostgreSQL schema for User/Session/Customer and provide a single migration that can be applied locally and in CI without exposing secrets.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] DB schema includes: User, Session, Customer (minimum fields) and compiles in TypeScript
- [ ] Exactly one migration is added in this PR (no multiple schema change rounds)
- [ ] Local dev can run DB using docker-compose (or equivalent) with non-secret defaults
- [ ] CI can run minimal DB-dependent tests using ephemeral local DB (no external services required)
- [ ] Database connection config uses environment variables; no credentials hardcoded
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? Yes (requires label ai:deps)

# 4) Suggested Plan (optional but recommended)
1) Add DB access layer (Prisma or alternative) behind `lib/db` boundary.
2) Define schema and generate one migration.
3) Add docker-compose for local Postgres (non-secret dev creds).
4) Add minimal tests to validate migration/app can connect in CI.
5) Document local setup and test commands.

# 5) Decision Gates (human-only; if needed)
If you must decide, convert this Issue to ai:blocked and include:
- Question:
- Option A: pros/cons, risk, effort, rollback
- Option B: pros/cons, risk, effort, rollback
- Decision criteria (what the human should optimize for)

Decision gates for this Issue:
- If choosing Prisma vs node-postgres impacts dependencies significantly, mark ai:blocked and propose options.

# 6) Context / Links
- Files/dirs:
- lib/db (new)
- prisma/ (if Prisma chosen)
- docker-compose.yml (new)
- .github/workflows/ci.yml
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
- Title: DB: PostgreSQL schema (User/Session/Customer) + Migration
- Requirements:
- [ ] DB schema includes: User, Session, Customer (minimum fields) and compiles in TypeScript
- [ ] Exactly one migration is added in this PR (no multiple schema change rounds)
- [ ] Local dev can run DB using docker-compose (or equivalent) with non-secret defaults
- [ ] CI can run minimal DB-dependent tests using ephemeral local DB (no external services required)
- [ ] Database connection config uses environment variables; no credentials hardcoded
