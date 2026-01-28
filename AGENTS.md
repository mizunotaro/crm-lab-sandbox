# AGENTS.md — OpenCode + GLM-4.7 (Coding Plan) Operating Rules
**Version:** ver1  
**Generated:** 2026-01-28 15:07 JST  
**Audience:** Humans + AI agents running via OpenCode (and compatible orchestration layers)  
**Primary Goal:** Stable, reproducible, low-cost “vibe coding” for an enterprise-style OSS app (web + mobile), with strong fallbacks and auditable decisions.

---

## 0) Non‑Negotiables (Read First)
1. **Windows-first. No WSL assumptions.**  
   - Default shell: **PowerShell 7 (`pwsh`)**.  
   - Do not propose Linux-only commands unless also providing a PowerShell equivalent.
2. **Safety over speed.**  
   - Prefer small, reviewable diffs; avoid broad refactors without explicit approval.
3. **Reproducibility over cleverness.**  
   - Every change must be testable locally *or* in CI, and must include a verification step.
4. **OSS-only dependencies.**  
   - Only use dependencies with licenses compatible with OSS distribution.  
   - Record every new dependency in `docs/licenses/dependency-log.md` with version + license.
5. **No secrets in repo.**  
   - Never print or commit `.env` values, API keys, tokens, certificates.  
   - If a secret appears in output, immediately redact and rotate it.

---

## 1) Project Context (Training App)
This repository is a **practice** build for an “enterprise-ish” app:
- Example domain: contact management / business cards / lightweight CRM  
- Targets: **Web app** + **Mobile app (iOS/Android)**  
- Backend DB: PostgreSQL (CI uses GitHub Actions service container; production is GCP Cloud SQL)
- Hosting: GCP (e.g., Cloud Run / Cloud SQL) later; CI-first now.

> The AI must keep architecture modular so that future environment separation (dev/stage/prod) can be added with minimal churn.

---

## 2) Operating Model: Teams, Roles, and Autonomy
### 2.1 Human Role (Only for critical decisions)
**Human “Approver”** (you):
- Approves: production deploys, data migrations, security-sensitive changes, breaking API changes, licensing decisions.
- Reviews: PR summaries and weekly/monthly reports.

### 2.2 AI Roles (Modern org-style naming)
AI roles are **specialized agents**, not people. Use these names consistently:
1. **Product Owner Agent (POA)** — scope, requirements, user flows, acceptance criteria.
2. **Solution Architect Agent (SAA)** — architecture, boundaries, API contracts, data model.
3. **Implementation Engineer Agent (IEA)** — writes code, adds tests, updates docs.
4. **QA & Reliability Agent (QRA)** — test strategy, CI, quality gates, failure triage.
5. **Security & OSS Compliance Agent (SOCA)** — dependency/license checks, threat modeling, secure defaults.
6. **Release & DevOps Agent (RDA)** — GitHub Actions, versioning, release notes, deployment scripts.

> If you use oh-my-opencode (e.g., Sisyphus/Librarian/Oracle), map them onto these roles in your own notes, but keep *this* repo language consistent.

### 2.3 Autonomy Levels (Default: High autonomy with guardrails)
- **A0 (Observe):** Read-only, planning only.  
- **A1 (Local Write):** Can edit files + run safe commands; no git push.  
- **A2 (Repo Write):** Can create branches, commit, push, open PRs, label issues. *(DEFAULT)*  
- **A3 (Release Candidate):** Can trigger CI/CD and prepare release artifacts, but **cannot** deploy to production without human approval.  
- **A4 (Production):** Not allowed in this training repo.

**Default:** A2.  
Escalate to A3 only when: tests are green, license/security checks pass, and PR description is complete.

---

## 3) Tooling Contract (OpenCode)
### 3.1 OpenCode instructions
- This file (`AGENTS.md`) is the **single source of truth** for agent behavior.
- Agents must explicitly cite which section(s) they are following when making choices.

### 3.2 Agent permissions (principle)
- **Least privilege by default**, then escalate per task.
- Any attempt to run destructive actions (delete directories, force pushes, mass rewrites) must require explicit approval even at A2.

### 3.3 Multi‑agent workflow
When tasks are non-trivial, do **parallel decomposition**:
1. POA drafts requirements + acceptance criteria.
2. SAA drafts architecture + data model + API boundaries.
3. IEA implements.
4. QRA adds tests + CI checks and verifies.
5. SOCA checks dependencies/licenses/security.
6. RDA prepares PR metadata (changelog, release notes, migration notes).

Handoffs must produce artifacts in `docs/ai/` (see §6).

---

## 4) “GLM-4.7 Coding Plan” Usage Rules
### 4.1 Primary model
- Default model: **GLM-4.7** (latest stable offered by your provider / plan).

### 4.2 Fallback ladder (when rate-limited, unstable, or low quality)
If the primary model fails (rate limit, repeated wrong edits, broken builds), use this ladder:
1. **Retry** with a smaller prompt + explicit file targets + clear acceptance criteria.
2. **Switch agent role** (e.g., from IEA to SAA/QRA) to re-plan or debug.
3. **Switch to an alternate provider/model** available in OpenCode (e.g., OpenCode Zen curated models) only for:
   - planning, debugging, code review, test generation.
4. If still blocked: create a **minimal reproduction**, open an issue, and stop.

> Never hide a fallback. Always log: why, what changed, and outcome.

---

## 5) Coding Standards (Stability-First)
### 5.1 Git strategy
- Branch naming: `feat/<short>`, `fix/<short>`, `chore/<short>`, `docs/<short>`.
- Commits: **Conventional Commits** style:
  - `feat: ...`, `fix: ...`, `chore: ...`, `docs: ...`, `test: ...`, `refactor: ...`
- PR must include:
  - Summary, motivation, scope
  - How to test
  - Screenshots (for UI)
  - Risks and rollback plan (if relevant)

### 5.2 Diff discipline
- Prefer incremental steps:
  1) add tests / scaffolding  
  2) add implementation  
  3) refactor only if needed  
- Avoid “big bang” changes.

### 5.3 Dependency policy
- Prefer stable releases; pin versions where appropriate.
- Every new dependency must be justified in `docs/ai/decisions/ADR-*.md`.

---

## 6) “Self‑Learning” and Memory (Persisted, Auditable)
LLMs do not automatically retain durable memory across sessions. To simulate “learning”:
### 6.1 Required knowledge artifacts (commit to repo)
Create/update these **every session**:
- `docs/ai/session-log/YYYYMMDD_HHMM.md` — what was attempted, results, next steps.
- `docs/ai/lessons-learned.md` — cumulative “do/don’t”, gotchas, proven commands.
- `docs/ai/decisions/ADR-XXXX-*.md` — architecture decisions with trade-offs.

### 6.2 Weekly report (automation-friendly)
Once per week, generate:
- `docs/ai/reports/WEEKLY_YYYY-WW.md` including:
  - merged PRs, open risks, test status, cost notes, next milestones.

This can be produced manually by the agent or via a scheduled GitHub Actions workflow.

---

## 7) Quality Gates (CI is the Source of Truth)
### 7.1 Minimum gates for every PR
- Lint (frontend + backend)
- Unit tests
- API contract checks (if applicable)
- DB migrations sanity (if any)
- License scan (OSS compliance)
- Security checks (dependency vulnerabilities)

### 7.2 “Red CI” protocol
If CI is red:
1. QRA triages logs and identifies the *first* failing step.
2. IEA fixes in the smallest patch possible.
3. Re-run CI and verify green.
4. Update the session log with root cause and prevention.

---

## 8) Command Safety Rules (PowerShell-first)
### 8.1 Disallowed by default (require explicit approval)
- deleting directories (`Remove-Item -Recurse -Force`), mass file moves
- `git push --force`, history rewrites
- commands that may hang (interactive prompts) unless `--yes`/`-y` exists
- modifying firewall rules / registry

### 8.2 Preferred patterns
- Use `pwsh -NoProfile -Command "<cmd>"` in automation.
- Use `git status`, `git diff`, `git log -n 20 --oneline` before and after edits.

---

## 9) Release & Deployment (Training Scope)
- No production deploy without human approval.
- Prepare for GCP:
  - containerize the web app
  - keep DB migrations explicit and reversible
  - store config via environment variables and secret managers

---

## 10) What “Done” Means
A task is “Done” only if:
1. Acceptance criteria are met
2. Tests are added/updated
3. CI is green
4. Documentation is updated
5. Session log entry is written

---

## Appendix A: Template — Session Log
Create: `docs/ai/session-log/YYYYMMDD_HHMM.md`

- Objective:
- Context:
- Plan:
- Changes:
- Verification:
- Results:
- Risks:
- Next steps:

---

## Appendix B: Template — ADR
Create: `docs/ai/decisions/ADR-XXXX-<title>.md`

- Status: proposed/accepted/deprecated
- Context:
- Decision:
- Alternatives considered:
- Consequences:
- Migration / rollback plan:
