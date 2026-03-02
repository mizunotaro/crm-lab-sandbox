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

---

## Appendix C: Security Checklist & Review Protocol

### C.1 Pre-Implementation Security Checklist
Before writing ANY code that handles authentication, authorization, or user data, verify:

#### Authentication & Session
- [ ] **ID Token Verification**: Never decode JWT payload without verifying signature
  - Use libraries like `jose` for JWT verification
  - Verify `iss` (issuer), `aud` (audience), `exp` (expiration)
- [ ] **Session Regeneration**: Generate new session ID after successful authentication
- [ ] **No Default Secrets**: All secrets must be validated at startup, never use hardcoded defaults
- [ ] **Secret Length Requirements**:
  - `SESSION_SECRET`: minimum 32 characters
  - `ENCRYPTION_KEY`: 64 hex characters (32 bytes)

#### Input Validation
- [ ] **Zod/Yup Schema**: All user inputs validated with schema
- [ ] **Integer Parsing**: Always check `isNaN()` after `parseInt()`
- [ ] **ID Validation**: Use `isValidId()` for all resource IDs
- [ ] **Amount Limits**: Set `max(Number.MAX_SAFE_INTEGER)` for numeric inputs
- [ ] **Array Limits**: Limit array size in bulk operations (e.g., max 1000 items)

#### Output Encoding
- [ ] **HTML Escape**: All user data in HTML must use `escapeHtml()`
- [ ] **CSV Escape**: Use `escapeCSV()` for CSV exports
- [ ] **JSON Response**: Never include raw error messages from external APIs

#### Rate Limiting & Access Control
- [ ] **Rate Limit**: All API endpoints should have rate limiting
- [ ] **Resource Ownership**: Verify `userId` matches resource owner before any operation
- [ ] **Origin Validation**: Non-GET requests must validate `Origin` header

### C.2 Security Review Persona (Activate for Code Review)

When reviewing code, adopt the **Security Auditor Persona**:

```
You are a security auditor performing a penetration test. Your goal is to find 
vulnerabilities before attackers do. For each code change, consider:

1. AUTHENTICATION BYPASS
   - Can an attacker forge tokens or session cookies?
   - Are OAuth callbacks properly validated?
   - Is the JWT signature verified?

2. AUTHORIZATION BYPASS
   - Can user A access user B's data by changing an ID?
   - Are resource ownership checks in place?

3. INJECTION ATTACKS
   - SQL: Is Prisma used correctly with parameterized queries?
   - XSS: Is user input escaped in HTML/CSV/Excel output?
   - Command: Are there any shell executions with user input?

4. DATA EXPOSURE
   - Are secrets logged or returned in API responses?
   - Are encryption keys hardcoded or properly managed?

5. RATE LIMITING
   - Can an attacker brute-force authentication?
   - Can bulk operations be abused?

Report findings with severity: CRITICAL / HIGH / MEDIUM / LOW
```

### C.3 Mandatory Security Patterns

```typescript
// ✅ CORRECT: Validate environment at startup
export const SESSION_SECRET = (() => {
  const secret = process.env.SESSION_SECRET
  if (!secret || secret.length < 32) {
    throw new Error('SESSION_SECRET must be set and at least 32 characters')
  }
  return secret
})()

// ❌ WRONG: Hardcoded default
const SECRET = process.env.SECRET || 'default_secret_key'
```

```typescript
// ✅ CORRECT: Verify JWT signature
import { jwtVerify, createRemoteJWKSet } from 'jose'
const { payload } = await jwtVerify(token, JWKS, { issuer, audience })

// ❌ WRONG: Just decode payload
const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString())
```

```typescript
// ✅ CORRECT: Escape user input in HTML
const escapeHtml = (s: string) => s
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;')

// ❌ WRONG: Direct interpolation
`<div>${userInput}</div>`
```

```typescript
// ✅ CORRECT: Validate and parse integers
export function validateInteger(value: string | null | undefined, name: string): number | null {
  if (!value) return null
  const parsed = parseInt(value, 10)
  if (isNaN(parsed)) throw new Error(`Invalid ${name}`)
  return parsed
}

// ❌ WRONG: No validation
const year = parseInt(req.query('year'))
```

```typescript
// ✅ CORRECT: Resource ownership check
const resource = await db.resource.findFirst({ 
  where: { id, userId: session.userId } 
})

// ❌ WRONG: No ownership check
const resource = await db.resource.findUnique({ where: { id } })
```

### C.4 Security Review Checklist (Before Merge)

- [ ] No hardcoded secrets or default credentials
- [ ] All JWTs verified with signature check
- [ ] All user inputs validated with Zod/Yup
- [ ] All outputs escaped (HTML, CSV, JSON)
- [ ] Rate limiting on authentication endpoints
- [ ] Resource ownership verified
- [ ] Origin validation for state-changing operations
- [ ] Session regenerated after login
- [ ] Dependencies scanned for vulnerabilities
- [ ] Error messages don't leak sensitive info

### C.5 Common Vulnerability Patterns to Avoid

| Pattern | Vulnerability | Fix |
|---------|--------------|-----|
| `process.env.X \|\| 'default'` | Hardcoded secret | Validate at startup, throw if missing |
| `JSON.parse(atob(token.split('.')[1]))` | JWT forgery | Use `jwtVerify()` with JWKS |
| `<div>${input}</div>` | XSS | Use `escapeHtml()` |
| `parseInt(req.query.x)` | NaN/undefined | Use `validateInteger()` |
| `findUnique({ where: { id } })` | IDOR | Use `findFirst({ where: { id, userId } })` |
| `X-Forwarded-For` directly | IP spoofing | Take first IP only |
| Session not regenerated | Session fixation | Clear + recreate after auth |

---

## Appendix D: Environment Variable Security Requirements

All projects MUST validate required environment variables at startup:

```typescript
// config/index.ts
function getRequiredEnv(name: string): string {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Environment variable ${name} is required`)
  }
  return value
}

export const CONFIG = {
  sessionSecret: (() => {
    const s = process.env.SESSION_SECRET
    if (!s || s.length < 32) throw new Error('SESSION_SECRET: min 32 chars')
    return s
  })(),
  encryptionKey: (() => {
    const k = process.env.ENCRYPTION_KEY
    if (!k || k.length !== 64 || !/^[0-9a-fA-F]+$/.test(k)) {
      throw new Error('ENCRYPTION_KEY: must be 64 hex chars')
    }
    return Buffer.from(k, 'hex')
  })(),
  // ... other config
}
```

**Startup should FAIL** if any required variable is missing or invalid.

---

## Appendix E: Quality Assurance & Code Review Standards

### E.1 Code Review Checklist

Before merging any code, verify:

#### Stability
- [ ] **Error Handling**: All async operations wrapped in try-catch
- [ ] **Transactions**: Multi-record operations use database transactions
- [ ] **Retries**: External API calls have retry logic with exponential backoff
- [ ] **Graceful Degradation**: Service failures don't crash the application
- [ ] **Resource Cleanup**: Connections, streams, and handles are properly closed

#### Robustness
- [ ] **Type Safety**: No `any` types without justification
- [ ] **Type Assertions**: Avoid `as` assertions; use type guards or Zod
- [ ] **Null Safety**: All nullable values checked before use
- [ ] **Boundary Values**: Edge cases tested (empty, max, negative)
- [ ] **ID Validation**: All resource IDs validated before DB operations

#### Testability
- [ ] **No Global State**: Dependencies passed as arguments or injected
- [ ] **Pure Functions**: Business logic separated from I/O
- [ ] **Time Injection**: Current time passed as parameter for deterministic tests
- [ ] **Mockable**: External dependencies can be mocked

#### Maintainability
- [ ] **DRY**: No duplicated code (extract to shared module)
- [ ] **Single Responsibility**: Functions do one thing, under 30 lines
- [ ] **Named Constants**: No magic numbers or strings
- [ ] **Comments**: Complex logic explained, not just restating code

### E.2 Error Handling Standards

```typescript
// ✅ CORRECT: Structured error handling
try {
  const result = await externalApi.call()
  return { success: true, data: result }
} catch (error) {
  logger.error('API call failed', { error, context: { userId } })
  return { success: false, error: 'Service temporarily unavailable' }
}

// ❌ WRONG: Silent failure
try {
  await doSomething()
} catch {
  // ignored
}
```

#### Error Response Format
```typescript
interface ApiError {
  error: string           // User-friendly message
  code?: string          // Machine-readable code
  details?: unknown      // Only in development
}
```

#### Logging Standards
```typescript
// Always include context
logger.error('Operation failed', {
  error: error.message,
  stack: error.stack,
  context: { userId, resourceId, operation }
})
```

### E.3 Testability Requirements

#### Dependency Injection Pattern
```typescript
// ✅ CORRECT: Dependencies injected
export function createUserService(deps: {
  db: PrismaClient
  emailService: EmailService
}) {
  return {
    async createUser(data: CreateUserInput) {
      const user = await deps.db.user.create({ data })
      await deps.emailService.sendWelcome(user.email)
      return user
    }
  }
}

// ❌ WRONG: Hard dependencies
export async function createUser(data: CreateUserInput) {
  const user = await prisma.user.create({ data })  // Global prisma
  await sendEmail(user.email)  // Direct import
  return user
}
```

#### Time Injection
```typescript
// ✅ CORRECT: Time injected
export function getExpiryDate(now: Date = new Date()): Date {
  return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
}

// ❌ WRONG: Current time hardcoded
export function getExpiryDate(): Date {
  return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
}
```

### E.4 Security Testing Requirements

#### Automated Tests (CI Pipeline)
```yaml
# Required security tests
- pnpm audit                    # Dependency vulnerabilities
- pnpm test                     # Unit tests with security cases
- OWASP ZAP baseline scan      # API security scan
```

#### Test Coverage Requirements
| Category | Minimum Coverage |
|----------|-----------------|
| Authentication | 90% |
| Authorization | 90% |
| Input Validation | 80% |
| Business Logic | 70% |

#### Security Test Cases Required
```typescript
describe('Authentication', () => {
  it('rejects invalid JWT signature')
  it('rejects expired tokens')
  it('regenerates session after login')
  it('prevents session fixation')
})

describe('Authorization', () => {
  it('prevents access to other users resources')
  it('validates resource ownership')
})
```

### E.5 Security Logging Standards

#### Events to Log
| Event | Level | Fields |
|-------|-------|--------|
| Login success | INFO | userId, ip, userAgent |
| Login failure | WARN | email, ip, reason |
| Token refresh | INFO | userId |
| Permission denied | WARN | userId, resource, action |
| Rate limit exceeded | WARN | ip, endpoint |
| Config change | AUDIT | userId, change |

#### Log Format
```typescript
interface SecurityLog {
  timestamp: string
  level: 'INFO' | 'WARN' | 'ERROR' | 'AUDIT'
  event: string
  userId?: string
  ip?: string
  userAgent?: string
  details?: Record<string, unknown>
}
```

### E.6 Incident Response Checklist

When vulnerability is discovered:

1. **Immediate (0-1 hour)**
   - [ ] Document the vulnerability
   - [ ] Assess severity (CRITICAL/HIGH/MEDIUM/LOW)
   - [ ] Notify security team
   - [ ] Consider temporary mitigation (disable feature, WAF rule)

2. **Short-term (1-24 hours)**
   - [ ] Create fix in separate branch
   - [ ] Add regression test
   - [ ] Code review with security focus
   - [ ] Deploy to staging, verify fix

3. **Deployment**
   - [ ] Deploy fix to production
   - [ ] Monitor for anomalies
   - [ ] Update dependencies if needed
   - [ ] Rotate any compromised secrets

4. **Post-incident (1-7 days)**
   - [ ] Write incident report
   - [ ] Update security checklist
   - [ ] Schedule security review
   - [ ] Update lessons-learned.md

### E.7 Quality Metrics Dashboard

Track these metrics weekly:

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Test Coverage | >80% | <70% |
| TypeScript Errors | 0 | >0 |
| Lint Errors | 0 | >0 |
| Security Vulnerabilities | 0 Critical/High | Any Critical |
| Code Duplication | <5% | >10% |
| Open Security Issues | 0 | >3 |

### E.8 Code Quality Persona (Activate for Code Review)

When reviewing code quality, adopt this persona:

```
You are a senior architect reviewing for long-term maintainability. Consider:

1. STABILITY
   - Are errors handled gracefully?
   - Will this work under load?
   - What happens if external services fail?

2. TESTABILITY
   - Can I unit test this without mocking the world?
   - Are dependencies injectable?
   - Is business logic separated from I/O?

3. MAINTAINABILITY
   - Will a new developer understand this in 6 months?
   - Is there unnecessary complexity?
   - Is the code DRY?

4. EXTENSIBILITY
   - Can new features be added without major refactoring?
   - Are abstractions appropriate?
   - Is configuration externalized?

Report findings as: MUST FIX / SHOULD FIX / NICE TO HAVE
```
