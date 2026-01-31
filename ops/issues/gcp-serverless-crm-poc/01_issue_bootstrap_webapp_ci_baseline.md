# 0) Intent (6-step ops)
This Issue is queued for AI automation.
- You (AI) MUST: Plan -> Implement -> Verify -> Report.
- Human will intervene ONLY when you mark ai:blocked with options + decision criteria.

# 1) Goal (What to achieve)
Create a minimal Next.js (TypeScript) web application skeleton with a CI baseline that always stays green on PRs.

# 2) Acceptance Criteria (AC) — MUST be checkable
- [ ] Repository has a runnable Next.js app (local dev) without requiring any secrets
- [ ] CI runs: install -> lint -> typecheck -> test -> build
- [ ] README includes from-scratch dev steps (Windows11 + PowerShell7) and CI commands
- [ ] Lockfile is committed; dependency installation is deterministic
- [ ] No deployment workflows in this PR (CI only)
- [ ] CI is green (tests/build/lint/typecheck as applicable)
- [ ] No secrets exposed, no destructive ops
- [ ] No dependency changes unless Issue has label ai:deps

# 3) Constraints / Guardrails (hard)
- Scope: small PR only (minimal diff, no broad refactor)
- Security: never log/commit credentials
- If ambiguous: STOP and ask via PR description OR open ai:blocked with options
- Dependency changes allowed? Yes (requires label ai:deps)

# 4) Suggested Plan (optional but recommended)
1) Initialize Next.js TypeScript project structure (minimal).
2) Add scripts for lint/typecheck/test/build.
3) Add GitHub Actions CI workflow for PR.
4) Ensure `pnpm` (or repo standard) is used consistently and documented.
5) Verify locally and via CI.

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
- PROJECT_CONTEXT.md
- AGENTS.md
- CHEATSHEET_COMMANDS.md
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
- Title: Bootstrap: Next.js (TypeScript) Web App + CI Baseline
- Requirements:
- [ ] Repository has a runnable Next.js app (local dev) without requiring any secrets
- [ ] CI runs: install -> lint -> typecheck -> test -> build
- [ ] README includes from-scratch dev steps (Windows11 + PowerShell7) and CI commands
- [ ] Lockfile is committed; dependency installation is deterministic
- [ ] No deployment workflows in this PR (CI only)
