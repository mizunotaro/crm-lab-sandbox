# Threat Model

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Threat model for CRM Lab Sandbox application (training/practice environment)  
**Status:** Active

---

## 0) Overview

### 0.1 System Context

This threat model covers the **CRM Lab Sandbox** application, a practice environment for building enterprise-style web and mobile applications.

**Scope:**
- Web application (frontend)
- API backend (contact management)
- Mobile applications (iOS/Android) - planned
- Database: PostgreSQL (CI: GitHub Actions service container, Production: GCP Cloud SQL)
- Hosting: GCP Cloud Run (planned)

**Out of Scope:**
- Infrastructure provider security (GCP/AWS)
- Third-party service vulnerabilities (outside of direct dependencies)
- Physical security

---

## 1) Threat Identification

### 1.1 Application Boundary & Data Flow

```
[User/Clients] 
    ↓
[Web Browser / Mobile App]
    ↓ HTTPS/TLS
[API Gateway / Load Balancer] - (Planned: Cloud Armor)
    ↓
[Cloud Run Instances] - (Planned: Rate Limiting)
    ↓
[Application Code] - (Planned: CSRF, Auth, RBAC)
    ↓
[PostgreSQL Database]
```

### 1.2 Asset Inventory

| Asset | Sensitivity | Location | Threat Priority |
|-------|-------------|----------|-----------------|
| User credentials | High | Database (planned) | Critical |
| Contact data (PII) | Medium | Database | High |
| API keys | High | Secrets Manager (planned) | High |
| Configuration files | Medium | Codebase / Secret Manager | Medium |
| Audit logs | Medium | Logging service (planned) | Medium |

### 1.3 Threat Categories

Based on STRIDE model:

| Threat Category | Description | Example |
|-----------------|-------------|---------|
| **S**poofing | Impersonation of a user, system, or process | Attacker impersonating legitimate user |
| **T**ampering | Unauthorized modification of data or code | Manipulating contact records |
| **R**epudiation | Denying actions performed | User denies deleting data |
| **I**nformation Disclosure | Exposing sensitive information | Leaking contact data via API |
| **D**enial of Service | Disrupting service availability | API rate limit exhaustion, DDoS |
| **E**levation of Privilege | Gaining unauthorized permissions | Regular user accessing admin features |

---

## 2) Control Mapping

### 2.1 Controls → Threats Mapping Table

| Control | Threats Addressed | Implementation Status | Residual Risk |
|---------|-------------------|----------------------|---------------|
| **CSRF Protection** | Spoofing (session hijacking), Tampering (state-changing requests) | Not Implemented | High |
| **Security Headers** (Helmet.js) | Information Disclosure (XSS, clickjacking), Spoofing | Not Implemented | Medium-High |
| **Authentication** (JWT/Session) | Spoofing, Repudiation | Not Implemented | Critical |
| **RBAC** (Role-Based Access Control) | Elevation of Privilege, Tampering, Information Disclosure | Not Implemented | High |
| **Audit Logging** | Repudiation, Tampering detection | Not Implemented | Medium-High |
| **Rate Limiting** | Denial of Service, Abuse | Planned (see [rate-limiting-plan.md](./rate-limiting-plan.md)) | Medium |
| **Input Validation** | Tampering, XSS, SQL Injection | Partial (API contracts only) | Medium |
| **HTTPS/TLS** | Information Disclosure (transit) | Planned (GCP Cloud Run) | Low (after deployment) |
| **Environment Variables/Secrets** | Information Disclosure (credentials) | Not Implemented (needs Secret Manager) | High |
| **API Schema Validation** | Tampering, Information Disclosure | Partial (TypeScript types) | Medium |

### 2.2 Detailed Control Implementation Status

#### 2.2.1 CSRF Protection
- **Threats:** Cross-Site Request Forgery attacks
- **Status:** Not Implemented
- **Planned Implementation:**
  - Double Submit Cookie pattern or SameSite cookie attribute
  - CSRF tokens for state-changing operations (POST/PUT/DELETE)
- **Gaps:** No authentication system yet, CSRF cannot be implemented without sessions or cookies
- **Next Steps:** Implement authentication first, then add CSRF protection

#### 2.2.2 Security Headers
- **Threats:** XSS, Clickjacking, MIME sniffing, referrer leakage
- **Status:** Not Implemented
- **Planned Headers:**
  - `Content-Security-Policy` - Restrict resource loading
  - `X-Frame-Options: DENY` - Prevent clickjacking
  - `X-Content-Type-Options: nosniff` - Prevent MIME sniffing
  - `Strict-Transport-Security` - Enforce HTTPS
  - `Referrer-Policy` - Control referrer information
  - `Permissions-Policy` - Restrict browser features
- **Implementation:** Helmet.js (Node.js) or equivalent
- **Gaps:** No web framework or HTTP middleware layer yet
- **Next Steps:** Set up web framework (Express/Fastify), integrate Helmet.js

#### 2.2.3 Authentication
- **Threats:** Spoofing, Unauthorized access, Repudiation
- **Status:** Not Implemented
- **Planned Implementation:**
  - JWT-based stateless authentication
  - OAuth2/OIDC for third-party identity (optional)
  - Password hashing (bcrypt/argon2)
  - Session management with secure cookies (httpOnly, secure, SameSite)
- **Gaps:** No user model, no auth endpoints
- **Next Steps:** Create user entity, implement login/register endpoints, add JWT handling

#### 2.2.4 RBAC (Role-Based Access Control)
- **Threats:** Elevation of Privilege, Unauthorized access to resources
- **Status:** Not Implemented
- **Planned Roles:**
  - `admin` - Full access to all contacts and users
  - `user` - Read/write access to own contacts only
  - `viewer` - Read-only access to assigned contacts
- **Implementation:**
  - Role claims in JWT tokens
  - Middleware to check permissions per endpoint
  - Row-level security in PostgreSQL (for data-level access)
- **Gaps:** No roles defined in data model, no permission checking
- **Next Steps:** Define role schema, implement authorization middleware

#### 2.2.5 Audit Logging
- **Threats:** Repudiation, Undetected tampering, Compliance violations
- **Status:** Not Implemented
- **Planned Events to Log:**
  - Authentication (login, logout, failed attempts)
  - Authorization (permission denied, role changes)
  - Data access (viewing contact records)
  - Data modification (create, update, delete contacts)
  - Configuration changes
- **Implementation:**
  - Structured logging (JSON format)
  - Log to Cloud Logging or PostgreSQL audit table
  - Include: timestamp, user ID, action, resource, IP, user agent
  - Tamper-evident logs (append-only, signed)
- **Gaps:** No logging infrastructure, no audit table
- **Next Steps:** Add audit event schema, integrate logging library, set up log retention

#### 2.2.6 Rate Limiting
- **Threats:** Denial of Service, API abuse, Credential stuffing
- **Status:** Planned (see [rate-limiting-plan.md](./rate-limiting-plan.md))
- **Planned Implementation:**
  - Layer 1: Cloud Armor (IP-based, DDoS protection)
  - Layer 2: Redis-based rate limiting (per API key/user)
  - Fail-open on Redis failure
- **Gaps:** No Redis instance, no middleware integration
- **Next Steps:** Follow rate-limiting-plan.md phases

#### 2.2.7 Input Validation
- **Threats:** Tampering, XSS, SQL Injection, Injection attacks
- **Status:** Partial (TypeScript types for API contracts)
- **Current State:**
  - API contract tests in `apps/api/contract.spec.ts`
  - TypeScript interfaces for request/response
- **Gaps:**
  - No runtime validation (zod/joi/ajv)
  - No sanitization (prevent XSS, SQL injection)
- **Next Steps:** Add runtime validation library, implement request sanitization

#### 2.2.8 HTTPS/TLS
- **Threats:** Information Disclosure (transit), Man-in-the-Middle attacks
- **Status:** Planned (GCP Cloud Run provides HTTPS automatically)
- **Configuration:**
  - TLS 1.2+ minimum
  - Secure cipher suites
  - HSTS header (see Security Headers)
- **Gaps:** Not deployed yet
- **Next Steps:** Deploy to Cloud Run, enable HSTS header

#### 2.2.9 Environment Variables & Secrets Management
- **Threats:** Information Disclosure (credential leakage), Credential theft
- **Status:** Not Implemented (secrets in code or untracked)
- **Planned Implementation:**
  - GCP Secret Manager for production secrets
  - Environment variables for non-sensitive config
  - `.env` files for local development (gitignored)
  - CI secrets via GitHub Actions secrets
- **Gaps:** Secrets may be committed accidentally
- **Next Steps:** Create `.env.example`, set up Secret Manager integration

---

## 3) Remaining Gaps & Mitigation Priorities

### 3.1 Critical Priority (Immediate)

| Gap | Risk | Effort | Mitigation |
|-----|------|--------|------------|
| No authentication | Critical - anyone can access API | Medium | Implement JWT-based auth, user registration/login |
| No authorization | High - no access control | Medium | Implement RBAC middleware |
| Secrets in code | Critical - potential credential exposure | Low | Move secrets to env vars + Secret Manager |

### 3.2 High Priority (Short-term, 1-2 weeks)

| Gap | Risk | Effort | Mitigation |
|-----|------|--------|------------|
| No security headers | High - vulnerable to XSS, clickjacking | Low | Add Helmet.js middleware |
| No audit logging | Medium - cannot track user actions | Medium | Implement audit log table + logging |
| No rate limiting | High - vulnerable to DoS/abuse | Medium-High | Implement Redis-based rate limiting (Phase 1: Cloud Armor) |
| No input validation | Medium - vulnerable to injection | Low | Add runtime validation (zod) |

### 3.3 Medium Priority (Ongoing, 1-4 weeks)

| Gap | Risk | Effort | Mitigation |
|-----|------|--------|------------|
| No CSRF protection | Medium-High - session hijacking | Low | Add CSRF tokens after auth is implemented |
| Database encryption at rest | Medium - data breach risk | Low | Enable PostgreSQL encryption (GCP default) |
| API key management | Medium - key rotation needed | Medium | Implement key rotation, expiration, revocation |

### 3.4 Low Priority (Future)

| Gap | Risk | Effort | Mitigation |
|-----|------|--------|------------|
| Web Application Firewall (WAF) | Low - defense in depth | High | Consider Cloud Armor WAF rules |
| API versioning deprecation | Low - maintainability | Low | Plan for deprecation strategy |
| Content Security Policy tuning | Low - false positives | Medium | Start with strict CSP, loosen if needed |

---

## 4) Threat Scenarios & Attack Trees

### 4.1 Attack Tree: Unauthorized Access to Contact Data

```
GOAL: Access contact data without authorization
├── A: Exploit Missing Authentication
│   ├── Direct API call (currently possible)
│   └── Bypass auth (not implemented yet)
├── B: Exploit Missing Authorization
│   ├── Access others' contacts
│   └── Escalate to admin role
├── C: Steal Credentials
│   ├── Phishing (external threat)
│   └── Social engineering (external threat)
└── D: Exploit Vulnerabilities
    ├── API injection (if input validation is weak)
    └── XSS in frontend (not implemented yet)
```

**Mitigation:** Implement authentication + RBAC first (Critical priority)

### 4.2 Attack Tree: Data Tampering (Modify/Delete Contacts)

```
GOAL: Modify or delete contact data
├── A: Direct API Call (currently possible)
│   ├── No authentication required
│   └── No authorization checks
├── B: CSRF Attack
│   └── Not applicable yet (no cookies)
├── C: SQL Injection
│   └── Not applicable yet (no SQL queries implemented)
└── D: IDOR (Insecure Direct Object Reference)
    └── Possible after auth is added (need authorization checks)
```

**Mitigation:** Add authentication, RBAC, and audit logging (High priority)

### 4.3 Attack Tree: Denial of Service

```
GOAL: Make service unavailable
├── A: API Abuse
│   ├── Flood API with requests (no rate limiting)
│   └── Expensive operations (currently none)
├── B: DDoS
│   └── Direct attack (cloud infrastructure helps, but need Cloud Armor)
└── C: Resource Exhaustion
    └── Not applicable (stateless API)
```

**Mitigation:** Implement rate limiting (Cloud Armor + Redis) (High priority)

---

## 5) Security Testing & Verification

### 5.1 Planned Security Tests

| Test Type | Tool/Framework | Frequency | Status |
|-----------|----------------|-----------|--------|
| Unit Tests | Vitest | Every commit | ✅ Implemented (API contracts) |
| Integration Tests | Vitest | Every commit | ✅ Implemented (API contracts) |
| Linting | ESLint | Every commit | ❌ Not configured |
| Type Checking | TypeScript | Every commit | ✅ Implemented |
| SAST (Static Analysis) | CodeQL / SonarQube | Every PR | ❌ Not configured |
| DAST (Dynamic Analysis) | OWASP ZAP | Pre-production | ❌ Not configured |
| Dependency Scanning | Snyk / npm audit | Every PR | ❌ Not configured |
| Penetration Testing | Manual | Quarterly | ❌ Not scheduled |

### 5.2 CI/CD Security Gates

Current CI checks (see `.github/workflows/ci.yml`):
- ✅ TypeScript type checking
- ✅ Unit tests

Missing security gates:
- ❌ Linting (ESLint/Prettier)
- ❌ Dependency vulnerability scan
- ❌ Secret detection (git-secrets or truffleHog)
- ❌ License scanning (OSS compliance)

**Recommendation:** Add security gates to CI before first production deployment.

---

## 6) Incident Response & Recovery

### 6.1 Incident Categories

| Category | Examples | Severity | Response Time |
|----------|----------|----------|---------------|
| Unauthorized Access | Credential breach, privilege escalation | Critical | < 1 hour |
| Data Exfiltration | API returning sensitive data to unauthorized user | Critical | < 1 hour |
| Data Corruption | Database tampering, unauthorized modifications | High | < 4 hours |
| Denial of Service | DDoS, rate limit exhaustion | High | < 4 hours |
| Misconfiguration | Incorrect RBAC, exposed secrets | Medium | < 24 hours |
| False Positive | Security alert triggered by legitimate user | Low | < 48 hours |

### 6.2 Incident Response Steps

1. **Detection:** Automated alerts (logging, monitoring) or user reports
2. **Containment:** Block IPs, revoke sessions, disable affected features
3. **Investigation:** Review logs, analyze root cause, determine impact
4. **Eradication:** Fix vulnerability, rotate secrets, apply patches
5. **Recovery:** Restore from backups, re-enable services
6. **Lessons Learned:** Update threat model, improve controls, update documentation

### 6.3 Rollback Procedures

| Scenario | Rollback Strategy | Downtime |
|----------|-------------------|----------|
| Rate limiting causing issues | Disable via feature flag | < 1 min |
| Security headers breaking app | Remove middleware deployment | 2-5 min |
| RBAC blocking legitimate users | Revert to previous deployment | 2-5 min |
| Audit logging causing performance | Disable audit log writes | < 1 min |
| Authentication failure | Switch to backup auth method or maintenance mode | 5-10 min |

---

## 7) Compliance & Regulatory Considerations

### 7.1 Applicable Standards (Planned)

| Standard | Relevance | Implementation Status |
|----------|-----------|----------------------|
| OWASP ASVS | Application security verification | Partial (API contracts) |
| OWASP Top 10 | Web application security risks | In Progress (threat modeling) |
| GDPR | Data protection (if EU users) | Not Applicable (training environment) |
| SOC 2 | Security controls audit | Not Applicable (training environment) |
| CIS Benchmarks | Security configuration | Not Applicable (infrastructure-level) |

### 7.2 Data Protection Notes

Since this is a **training/practice environment**:
- Contact data should be treated as **test data only**
- Real PII should NOT be used in development/staging
- Production deployment requires data protection policy review

---

## 8) Review & Maintenance

### 8.1 Review Schedule

| Review Type | Frequency | Owner |
|-------------|-----------|-------|
| Threat Model Review | Quarterly or after major changes | Security Lead |
| Control Effectiveness | Monthly | QA & Reliability Agent |
| Incident Analysis | After each incident | Security Lead |
| Dependency Updates | Weekly | Implementation Engineer |

### 8.2 Change Triggers

Re-evaluate threat model when:
- New features added (e.g., file upload, real-time features)
- New dependencies introduced
- Infrastructure changes (e.g., new cloud provider)
- Security incidents or near-misses
- Compliance requirements change

---

## 9) References

### 9.1 Internal Documents
- [Rate Limiting Plan](./rate-limiting-plan.md) - Detailed rate limiting strategy
- [AGENTS.md](../AGENTS.md) - AI agent operating rules and security policies
- [PROJECT_CONTEXT.md](../PROJECT_CONTEXT.md) - Project overview and architecture (if exists)

### 9.2 External Resources
- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [STRIDE Model](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [Cloud Armor Security](https://cloud.google.com/armor/docs/security-policy-concepts)
- [GCP Security Best Practices](https://cloud.google.com/architecture/security-best-practices)

### 9.3 Tools & Frameworks
- **Helmet.js** - Security headers for Node.js/Express
- **Zod** - Runtime type validation
- **bcrypt/argon2** - Password hashing
- **JWT** - Stateless authentication
- **Redis (Memorystore)** - Rate limiting
- **TruffleHog/git-secrets** - Secret detection
- **Snyk** - Dependency scanning

---

## 10) Appendix: Security Checklist

### 10.1 Pre-Production Checklist

- [ ] Authentication implemented (JWT/session-based)
- [ ] Authorization implemented (RBAC middleware)
- [ ] Security headers configured (Helmet.js)
- [ ] CSRF protection enabled (for state-changing operations)
- [ ] Input validation & sanitization (zod)
- [ ] Rate limiting enabled (Cloud Armor + Redis)
- [ ] Audit logging configured (all critical events)
- [ ] HTTPS/TLS enforced (HSTS header)
- [ ] Secrets managed via Secret Manager (no hardcoded secrets)
- [ ] Database encryption at rest enabled
- [ ] Dependency vulnerability scan passing
- [ ] Security tests passing (SAST/DAST)
- [ ] Backup & restore procedures tested
- [ ] Incident response runbooks documented
- [ ] Security monitoring & alerting configured

### 10.2 Deployment Checklist

- [ ] Environment variables configured (no secrets in repo)
- [ ] Database migrations reviewed & tested
- [ ] Rollback plan documented
- [ ] Feature flags ready (for instant rollback)
- [ ] Monitoring dashboards set up (rate limits, errors, latency)
- [ ] Alert thresholds configured
- [ ] Log retention policy set (audit logs ≥ 90 days)
- [ ] Security headers verified (curl -I to check)
- [ ] SSL/TLS certificate valid (no warnings)
- [ ] Dependency scan results reviewed
- [ ] Peer review completed
- [ ] Security sign-off obtained

---

**Status:** Draft - Ready for review  
**Next Steps:** Prioritize Critical and High priority gaps, create tracking issues for implementation  
**Maintained By:** Security & OSS Compliance Agent (SOCA)
