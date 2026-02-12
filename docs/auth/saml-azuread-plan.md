# SAML/Azure AD Integration Plan

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Plan for enterprise-grade SAML authentication with Azure AD as Identity Provider (IdP)

---

## 0) Current State

### 0.1 Problem Statement
- Current implementation: No authentication system (practice/training app)
- Requirement: Enterprise customers expect SAML SSO with Azure AD integration
- Goal: Provide secure, standards-compliant SAML authentication that supports enterprise identity management

### 0.2 Requirements
- **SAML 2.0 compliant**: Support standard SAML 2.0 protocol
- **Azure AD integration**: Work as Service Provider (SP) with Azure AD as IdP
- **Multi-tenant support**: Enable enterprise customers to use their own Azure AD tenant
- **Security**: Signed assertions, encrypted assertions (optional but recommended), secure session management
- **User provisioning**: Support Just-In-Time (JIT) provisioning and user attribute mapping
- **Logout handling**: Support both SP-initiated and IdP-initiated Single Logout (SLO)
- **Auditing**: Log authentication events for compliance
- **GCP-compatible**: Deploy on Cloud Run with Cloud SQL

---

## 1) Architectural Decision Gates

### 1.1 Decision Gate 1: SAML Flow Type

| Flow Type | Description | Use Case | Pros | Cons |
|-----------|-------------|----------|------|------|
| **SP-initiated** | User accesses app first, redirected to IdP for login | Most common scenario | Consistent user experience, better error handling | Requires IdP metadata configuration |
| **IdP-initiated** | User clicks app tile in Azure portal, sent directly to app | Microsoft 365 app launcher scenarios | Seamless Azure Portal experience | Less common, security concerns about forged requests |

**Recommended:** Support both, prioritize **SP-initiated** for primary flow

**Decision Criteria:**
- User experience consistency
- Enterprise customer expectations (most expect both flows)
- Security considerations (SP-initiated is more predictable)

---

### 1.2 Decision Gate 2: Attribute Mapping Strategy

| Strategy | Description | Pros | Cons |
|----------|-------------|------|------|
| **Static mapping** | Hardcode Azure AD attributes to app fields | Simple, predictable | Inflexible, requires code changes |
| **Dynamic mapping (config)** | Admin can configure attribute mappings in UI | Flexible, customer control | More complex, requires storage for config |
| **Hybrid** | Core fields mapped statically, optional fields configurable | Balance of simplicity and flexibility | Still requires some implementation complexity |

**Recommended:** **Dynamic mapping** with sensible defaults

**Decision Criteria:**
- Enterprise customers expect flexibility
- Different organizations have different attribute naming conventions
- Future-proofing for different IdP types

**Default Attribute Mappings:**

| Azure AD Attribute | App Field | Notes |
|---------------------|-----------|-------|
| `userPrincipalName` | `email` | Primary identifier |
| `displayName` | `name` | Full name |
| `givenName` | `firstName` | First name |
| `surname` | `lastName` | Last name |
| `mail` | `email` (fallback) | Alternative email |
| `objectId` | `externalId` | Azure AD unique ID |
| `userPrincipalName` | `username` | Username for app |

---

### 1.3 Decision Gate 3: Logout Strategy

| Logout Type | Description | Pros | Cons |
|-------------|-------------|------|------|
| **SP-initiated SLO** | App initiates logout, sends SLO request to IdP, IdP logs out user across all apps | Best user experience, clean session cleanup | Requires IdP SLO support |
| **IdP-initiated SLO** | Azure AD initiates logout when user signs out from Azure Portal | Consistent across all apps | Less control from app side |
| **Local logout only** | Only clear app session, ignore IdP | Simplest implementation | Poor UX, user remains logged into Azure AD |

**Recommended:** Support **both SP-initiated and IdP-initiated SLO** with local logout as fallback

**Decision Criteria:**
- Enterprise security requirements
- User experience expectations
- Compliance needs (full session cleanup)

---

### 1.4 Decision Gate 4: Encryption vs Signing Only

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **Signing only** | SAML assertions are signed but not encrypted | Simpler, better performance | Assertions readable in transit/logs |
| **Signing + encryption** | SAML assertions are both signed and encrypted | Maximum security, compliance-friendly | More complex, performance overhead, certificate management |

**Recommended:** **Signing required, encryption optional** (allow customer to choose)

**Decision Criteria:**
- Most enterprise SAML implementations use signing only
- Encryption adds complexity with minimal security benefit over TLS
- Some regulated industries may require encryption (allow opt-in)

---

## 2) Implementation Options

### 2.1 Option A: Open Source SAML Library (Recommended)

#### 2.1.1 Architecture
```
Cloud Run (App) → SAML Library (Middleware) → Azure AD (IdP)
                       ↓
                   Session Storage (Cloud SQL or Redis)
```

#### 2.1.2 Library Candidates

| Library | Language | License | Pros | Cons |
|---------|----------|--------|------|------|
| `passport-saml` | Node.js | MIT | Battle-tested, Passport ecosystem | Active maintenance concerns |
| `node-saml` | Node.js | MIT | Azure AD examples available | Less popular |
| `samlify` | Node.js | MIT | TypeScript native, well-maintained | More complex API |
| `next-auth` | Node.js | ISC | Popular, built-in SAML provider | Opinionated framework, Next.js only |

**Recommended:** `samlify` for custom backend, `next-auth` if using Next.js

#### 2.1.3 Key Components

1. **SAML Service Provider (SP) Configuration**
   - SP Entity ID (unique identifier for your app)
   - Assertion Consumer Service (ACS) URL
   - Single Logout Service (SLO) URL
   - X.509 certificate for signing/encryption

2. **Azure AD Integration**
   - Azure AD Tenant ID per customer
   - Azure AD SAML metadata URL
   - Azure AD application registration
   - Certificate exchange

3. **Session Management**
   - User session storage (Cloud SQL or Redis)
   - Session ID tracking for logout
   - Token revocation handling

4. **User Provisioning**
   - User record creation/updates on first login
   - Attribute mapping from SAML assertion
   - Role/group assignment mapping

5. **Middleware Layer**
   - SAML authentication middleware
   - Request validation
   - Session establishment

#### 2.1.4 Estimated Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Planning | SAML flow design, Azure AD setup guide, data model | 8-12 hours |
| Implementation | Library integration, middleware, user provisioning | 16-24 hours |
| Testing | Unit tests, integration tests with Azure AD test tenant | 12-16 hours |
| Deployment | Staging validation, production rollout, monitoring | 4-8 hours |
| Documentation | Admin guide, customer onboarding guide, troubleshooting | 8-12 hours |
| **Total** | | **48-72 hours** |

#### 2.1.5 Pros

- ✅ **Cost-effective**: No additional infrastructure costs
- ✅ **Flexibility**: Full control over implementation
- ✅ **Multi-tenant**: Can support multiple Azure AD tenants
- ✅ **Open standards**: Compatible with other SAML IdPs
- ✅ **Portability**: Can move to other cloud providers

#### 2.1.6 Cons

- ❌ **Implementation complexity**: Requires SAML expertise
- ❌ **Maintenance**: Library updates, security patches
- ❌ **Debugging**: SAML protocol can be difficult to debug
- ❌ **Certificate management**: Need to manage certificate rotation

---

### 2.2 Option B: Auth0 / Okta (Identity Provider Proxy)

#### 2.2.1 Architecture
```
Cloud Run (App) → Auth0/Okta SDK → Auth0/Okta → Azure AD (IdP via SAML)
                                       ↓
                                   Managed SAML
```

#### 2.2.2 Implementation Approach

Use Auth0 or Okta as an identity broker:
1. App authenticates with Auth0/Okta using OIDC
2. Auth0/Okta authenticates with Azure AD via SAML
3. Auth0/Okta handles SAML complexity
4. App receives standard JWT tokens

#### 2.2.3 Estimated Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Planning | Identity broker design, Auth0/Okta configuration | 4-6 hours |
| Implementation | SDK integration, configuration | 4-8 hours |
| Testing | Integration tests, user flows | 4-6 hours |
| Deployment | Staging, production, monitoring | 2-4 hours |
| Documentation | Setup guide, customer onboarding | 4-6 hours |
| **Total** | | **18-30 hours** |

#### 2.2.4 Pros

- ✅ **Faster implementation**: SAML complexity handled by provider
- ✅ **Less maintenance**: Provider manages certificates, SAML updates
- ✅ **Features**: Built-in MFA, user management, analytics
- ✅ **Multi-protocol**: Support for OIDC, OAuth 2.0, SAML all in one
- ✅ **Compliance**: SOC 2, HIPAA compliant out-of-box

#### 2.2.5 Cons

- ❌ **Cost**: Monthly subscription per active user ($2-20+/user/month)
- ❌ **Vendor lock-in**: Tied to Auth0/Okta ecosystem
- ❌ **Latency**: Additional hop through identity broker
- ❌ **Data privacy**: User identity data flows through third party
- ❌ **Complexity for multi-tenant**: Each tenant needs Auth0/Okta account or enterprise features

---

## 3) Decision Framework

### 3.1 Decision Criteria

| Criterion | Weight | Option A (Library) | Option B (Auth0/Okta) |
|-----------|--------|-------------------|----------------------|
| **Development time** | Medium | ⚠️ 48-72 hours | ✅ 18-30 hours |
| **Monthly cost** | High | ✅ $0 | ❌ $2-20+/user/month |
| **Operational overhead** | High | ⚠️ Medium (cert rotation, maintenance) | ✅ Low (managed service) |
| **Multi-tenant complexity** | High | ✅ Straightforward | ⚠️ Complex (needs enterprise plan) |
| **Control & flexibility** | Medium | ✅ High | ⚠️ Medium |
| **Compliance** | High | ⚠️ Need to implement | ✅ Built-in |
| **Time-to-market** | Medium | ⚠️ Longer | ✅ Faster |
| **Long-term cost** | High | ✅ Lower | ❌ Higher (scales with users) |

### 3.2 Use Case Recommendations

#### Choose Option A (Library) if:
- Budget constraints (no per-user cost)
- Need full control over SAML implementation
- Multi-tenant architecture is critical
- Have development resources available
- Long-term cost predictability is important
- Want to avoid vendor lock-in

#### Choose Option B (Auth0/Okta) if:
- Need fast time-to-market
- Budget allows per-user cost
- Want minimal operational overhead
- Need built-in MFA and compliance features
- Team lacks SAML expertise
- User base is small-medium (< 10,000 users)

### 3.3 Recommended Decision: Option A (SAML Library)

**Rationale:**
- This is a practice/training app - no immediate production pressure
- Lower long-term operational cost
- Full control for learning and future customization
- Multi-tenant support is more straightforward
- No vendor lock-in for future migrations

**Caveat:** If this were a production app with tight deadlines and budget for user fees, Option B would be preferred.

---

## 4) Recommended Implementation Path

### 4.1 Phase 1: SAML Foundation - Week 1
**Effort:** 2-3 days

**Tasks:**
1. Choose and install SAML library (`samlify` recommended)
2. Set up SP metadata (Entity ID, ACS URL, SLO URL)
3. Generate X.509 certificates (signing + optional encryption)
4. Create Azure AD test tenant and register application
5. Implement SP-initiated authentication flow
6. Create user data model for SAML users

**Deliverables:**
- SAML service module with basic SP configuration
- Azure AD setup guide for test tenant
- User model with SAML attributes
- Unit tests for SAML parsing

---

### 4.2 Phase 2: User Provisioning & Session Management - Week 2
**Effort:** 2-3 days

**Tasks:**
1. Implement JIT user provisioning (create/update users on first login)
2. Create dynamic attribute mapping configuration
3. Set up session storage (Cloud SQL or Redis)
4. Implement session validation middleware
5. Add user profile management UI for SAML users
6. Create admin dashboard for viewing SAML users

**Deliverables:**
- User provisioning service
- Session management layer
- Admin UI for SAML user management
- Integration tests with Azure AD

---

### 4.3 Phase 3: Logout & Security - Week 2-3
**Effort:** 1-2 days

**Tasks:**
1. Implement SP-initiated Single Logout (SLO)
2. Implement IdP-initiated SLO
3. Add local logout as fallback
4. Implement assertion validation (signature verification)
5. Add optional encryption support
6. Create certificate rotation procedure

**Deliverables:**
- Complete logout flow
- Security audit of SAML implementation
- Certificate management documentation
- Security tests

---

### 4.4 Phase 4: Multi-tenant Support - Week 3
**Effort:** 2-3 days

**Tasks:**
1. Create tenant model (store Azure AD configuration per customer)
2. Implement tenant-aware SAML metadata (dynamic Entity ID per tenant)
3. Create tenant onboarding flow
4. Add tenant switching (for super-admins)
5. Implement tenant isolation (users only see their tenant's data)
6. Create tenant management dashboard

**Deliverables:**
- Multi-tenant SAML architecture
- Tenant onboarding wizard
- Tenant admin dashboard
- Multi-tenant tests

---

### 4.5 Phase 5: Observability & Documentation - Week 3-4
**Effort:** 1-2 days

**Tasks:**
1. Add authentication event logging
2. Create monitoring dashboards (login success/failure rates)
3. Write customer onboarding guide
4. Write troubleshooting guide
5. Create Azure AD configuration templates
6. Document security best practices

**Deliverables:**
- Logging and monitoring setup
- Customer documentation
- Runbooks for common issues
- Security checklist

---

## 5) Azure AD Setup Guide

### 5.1 Azure AD Application Registration

**Prerequisites:**
- Azure AD tenant (use free tier for testing)
- Azure AD admin access

**Steps:**

1. **Register Application in Azure AD**
   ```
   Azure Portal → Azure AD → App registrations → New registration
   - Name: Your App Name
   - Supported account types: "Accounts in this organizational directory only"
   - Redirect URI: Your ACS URL (e.g., https://yourapp.com/auth/saml/callback)
   ```

2. **Get Tenant Details**
   - Tenant ID: From Azure AD overview page
   - App (client) ID: From app registration overview
   - Object ID: From app registration overview

3. **Configure SAML SSO**
   ```
   App registration → Single sign-on → SAML
   - Set up SP metadata (upload or enter Entity ID, ACS URL, SLO URL)
   - Download Azure AD SAML metadata XML
   - Note: Azure AD will auto-generate signing certificate
   ```

4. **Configure Claims**
   ```
   Edit Claims → Add claims to include:
   - userPrincipalName (email)
   - displayName (name)
   - givenName (firstName)
   - surname (lastName)
   - objectId (externalId)
   - mail (optional email fallback)
   ```

5. **Download Required Metadata**
   - SAML metadata XML: https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml
   - Certificate: Download X.509 certificate from SAML configuration page

---

### 5.2 Environment Variables (Template)

**Required:**
```bash
# SAML Configuration
SAML_SP_ENTITY_ID=https://yourapp.com
SAML_SP_ACS_URL=https://yourapp.com/auth/saml/callback
SAML_SP_SLO_URL=https://yourapp.com/auth/saml/logout

# Azure AD (Per Tenant)
AZURE_AD_TENANT_ID=your-tenant-id
AZURE_AD_METADATA_URL=https://login.microsoftonline.com/your-tenant-id/federationmetadata/2007-06/federationmetadata.xml

# Certificates (Store in Secret Manager, never commit)
SAML_SP_PRIVATE_KEY_PATH=/path/to/private/key.pem
SAML_SP_CERTIFICATE_PATH=/path/to/certificate.pem
```

**Note:** Never commit actual certificates or private keys to repository. Use GCP Secret Manager.

---

## 6) Data Model

### 6.1 Users Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(255) UNIQUE NOT NULL,  -- Azure AD objectId
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url TEXT,
  auth_provider VARCHAR(50) DEFAULT 'saml',  -- 'saml', 'local', 'oidc'
  tenant_id UUID REFERENCES tenants(id),
  last_login_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_external_id ON users(external_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
```

### 6.2 SAML Sessions Table

```sql
CREATE TABLE saml_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  tenant_id UUID REFERENCES tenants(id) NOT NULL,
  session_index VARCHAR(255) NOT NULL,  -- From SAML assertion
  name_id VARCHAR(255) NOT NULL,  -- From SAML assertion
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_saml_sessions_user_id ON saml_sessions(user_id);
CREATE INDEX idx_saml_sessions_session_index ON saml_sessions(session_index);
```

### 6.3 Tenants Table (Multi-tenant)

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  azure_ad_tenant_id VARCHAR(255) UNIQUE NOT NULL,
  azure_ad_app_client_id VARCHAR(255) NOT NULL,
  azure_ad_metadata_url TEXT NOT NULL,
  azure_ad_domain VARCHAR(255),
  saml_entity_id VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tenants_azure_ad_tenant_id ON tenants(azure_ad_tenant_id);
```

---

## 7) Risk Assessment

### 7.1 Common Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SAML assertion replay attacks | Low | High | Use NotOnOrAfter condition, short assertion validity |
| Certificate expiration | Medium | High | Automated monitoring and renewal process |
| XML signature spoofing | Low | Critical | Use trusted SAML library, validate all signatures |
| User data inconsistency | Medium | Medium | Transactional user provisioning, unique constraints |
| Session fixation attacks | Low | High | Regenerate session ID on login, use secure cookies |
| Man-in-the-middle attacks | Low | Critical | Enforce HTTPS, validate all certificates |
| IdP misconfiguration | Medium | High | Thorough testing with Azure AD test tenant |
| Logout failure (stale sessions) | Low | Medium | Short session timeout, periodic cleanup |

### 7.2 Security Checklist

- [ ] All SAML communications over HTTPS only
- [ ] X.509 certificates for signing (mandatory)
- [ ] Optional encryption support for sensitive environments
- [ ] Signature validation on all SAML responses
- [ ] Validate assertion conditions (NotBefore, NotOnOrAfter)
- [ ] Validate audience restriction
- [ ] Validate recipient
- [ ] Prevent replay attacks (check unique message ID)
- [ ] Secure session cookies (HttpOnly, Secure, SameSite)
- [ ] Implement CSRF protection
- [ ] Certificate rotation process documented
- [ ] All credentials stored in Secret Manager
- [ ] No secrets in logs or error messages

---

## 8) Testing Strategy

### 8.1 Unit Tests
- SAML response parsing
- Attribute mapping logic
- Session validation
- User provisioning logic
- Logout flow

### 8.2 Integration Tests
- End-to-end SP-initiated authentication with Azure AD test tenant
- IdP-initiated authentication flow
- SP-initiated Single Logout
- IdP-initiated Single Logout
- Multi-tenant isolation

### 8.3 Security Tests
- Signature validation with invalid signatures
- Expired assertion rejection
- Audience restriction enforcement
- Replay attack prevention
- Certificate validation

### 8.4 Load Tests
- Concurrent login attempts
- Session creation/management under load
- SAML response parsing performance

---

## 9) Cost Estimate

### 9.1 Option A (SAML Library)

| Cost Item | Monthly Cost | Notes |
|-----------|--------------|-------|
| Cloud Run (SAML app) | $0-50 | Depends on usage |
| Cloud SQL (database) | $50-200 | Depends on instance size |
| Secret Manager | $6 | Per version |
| Azure AD (test) | Free | Free tier |
| Azure AD (production) | Free | Enterprise customers bring their own Azure AD |
| Certificate (SSL) | Free | Let's Encrypt |
| **Total** | **$56-256/month** | Excluding enterprise customer costs |

### 9.2 Option B (Auth0)

| Cost Item | Monthly Cost | Notes |
|-----------|--------------|-------|
| Auth0 (per user) | $2-20+/user | Depends on plan |
| Cloud Run (app) | $0-50 | App backend |
| Cloud SQL (database) | $50-200 | Depends on instance size |
| **Total** | **$52-250+/month + per-user fees** | Per-user fees scale with customers |

---

## 10) Success Metrics

### 10.1 Operational Metrics
- **Authentication success rate:** > 99.5%
- **Authentication latency:** < 2s p95
- **Session validation latency:** < 50ms p95
- **Logout success rate:** > 99%
- **Uptime:** > 99.9%

### 10.2 Security Metrics
- **SAML signature validation:** 100% of requests validated
- **Certificate expiration:** 0 incidents of expired certs
- **Failed login attempts:** Monitor for anomalies
- **Replay attack attempts:** 0 successful replay attacks

### 10.3 User Experience Metrics
- **First login provisioning success:** > 99%
- **Attribute mapping accuracy:** 100% of expected fields mapped
- **Logout time:** < 3s user-perceived

---

## 11) References

### 11.1 Azure AD Documentation
- [Azure AD SAML SSO Documentation](https://docs.microsoft.com/azure/active-directory/manage-apps/configure-saml-single-sign-on)
- [Azure AD SAML Protocol](https://docs.microsoft.com/azure/active-directory/develop/saml-protocol)
- [Azure AD Certificate Management](https://docs.microsoft.com/azure/active-directory/manage-apps/manage-certificates-for-federated-single-sign-on)

### 11.2 SAML Libraries
- [samlify (Node.js)](https://github.com/tngan/samlify)
- [passport-saml (Node.js)](https://github.com/node-saml/passport-saml)
- [SAML 2.0 Specification](https://www.oasis-open.org/standards#samlv2.0)

### 11.3 Security Best Practices
- [OWASP SAML Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html)
- [NIST Guidelines for SAML](https://www.nist.gov/publications/federal-information-processing-standards-fips)

### 11.4 GCP Resources
- [Cloud Run Documentation](https://cloud.google.com/run)
- [Cloud SQL Documentation](https://cloud.google.com/sql)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager)

---

## 12) Appendix: SAML Flow Diagrams

### 12.1 SP-Initiated SAML Flow

```
User              App (SP)              Azure AD (IdP)
 |                  |                      |
 |--1. Access URL-->|                      |
 |                  |--2. Redirect to IdP->|
 |                  |                      |
 |                  |                      |--3. Request Auth-->|
 |                  |                      |                   |
 |                  |<--4. SAML Response---|
 |                  |                      |
 |<--5. Set Session--|                      |
 |                  |                      |
```

**Steps:**
1. User accesses protected resource
2. App redirects to Azure AD login page with SAML request
3. Azure AD authenticates user
4. Azure AD sends SAML assertion to app (ACS URL)
5. App validates assertion, creates session, redirects user

### 12.2 IdP-Initiated SAML Flow

```
Azure AD (IdP)       App (SP)              User
    |                  |                      |
    |--1. SAML Response--------------------->|
    |                  |                      |
    |                  |--2. Validate------->|
    |                  |                      |
    |<--3. Redirect with Session-----------|
    |                  |                      |
    |                  |                      |
```

**Steps:**
1. User clicks app tile in Azure Portal, Azure AD sends SAML assertion
2. App validates assertion
3. App creates session and redirects to dashboard

### 12.3 SP-Initiated Single Logout Flow

```
User              App (SP)              Azure AD (IdP)
 |                  |                      |
 |--1. Logout------>|                      |
 |                  |--2. SAML Logout Req->|
 |                  |                      |
 |                  |                      |--3. Logout from--|
 |                  |                      |    other apps     |
 |                  |<--4. SAML Logout Res-|
 |                  |                      |
 |<--5. Redirect---<|                      |
 |                  |                      |
```

---

## 13) Appendix: Configuration Example (samlify)

```typescript
import { ServiceProvider, IdentityProvider } from 'samlify';
import * as fs from 'fs';

// Load SP certificates from Secret Manager (never commit)
const spCert = fs.readFileSync(process.env.SAML_SP_CERTIFICATE_PATH);
const spKey = fs.readFileSync(process.env.SAML_SP_PRIVATE_KEY_PATH);

// Create Service Provider
const sp = ServiceProvider({
  entityID: process.env.SAML_SP_ENTITY_ID,
  assertEndpoint: process.env.SAML_SP_ACS_URL,
  sloEndpoint: process.env.SAML_SP_SLO_URL,
  signingCert: spCert.toString(),
  privateKey: spKey.toString(),
  wantAssertionsSigned: true,
  wantMessagesSigned: true,
  isAssertionEncrypted: process.env.SAML_ENCRYPT_ASSERTIONS === 'true',
  requestSignatureAlgorithm: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
});

// Load Azure AD Identity Provider metadata
const idp = IdentityProvider({
  metadata: process.env.AZURE_AD_METADATA_URL,
});

// SAML authentication flow
async function initiateLogin(req: Request, res: Response) {
  const { id, context } = sp.createLoginRequest(idp, 'redirect');
  res.redirect(context);
}

async function handleSamlResponse(req: Request, res: Response) {
  try {
    const { extract } = await sp.parseLoginResponse(idp, 'post', req.body);
    
    // Extract user attributes from SAML assertion
    const attributes = {
      email: extract.attributes.email || extract.attributes.userPrincipalName,
      name: extract.attributes.displayName,
      firstName: extract.attributes.givenName,
      lastName: extract.attributes.surname,
      externalId: extract.attributes.objectId,
      tenantId: extract.attributes.tenantId,
    };

    // Create or update user (JIT provisioning)
    const user = await upsertUser(attributes);

    // Create session
    const session = await createSession(user);

    // Set cookie
    res.cookie('session', session.id, {
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 8 * 60 * 60 * 1000, // 8 hours
    });

    res.redirect('/dashboard');
  } catch (error) {
    logger.error('SAML response validation failed', { error });
    res.status(401).send('Authentication failed');
  }
}

async function initiateLogout(req: Request, res: Response) {
  const session = await getSession(req.cookies.session);
  const { context } = sp.createLogoutRequest(idp, 'redirect', session.sessionIndex);
  await deleteSession(session.id);
  res.redirect(context);
}

async function handleLogoutResponse(req: Request, res: Response) {
  await sp.parseLogoutResponse(idp, 'post', req.body);
  res.redirect('/login');
}
```

---

## 14) Appendix: Azure AD SAML Configuration Template

### 14.1 Azure AD Enterprise Application Settings

**Single sign-on → SAML:**

| Field | Value |
|-------|-------|
| Identifier (Entity ID) | `https://yourapp.com` |
| Reply URL (ACS URL) | `https://yourapp.com/auth/saml/callback` |
| Sign on URL | `https://yourapp.com/login` |
| Logout URL | `https://yourapp.com/auth/saml/logout` |
| Relay State | (Optional) |
| Signing Option | Sign SAML response |
| Signing Algorithm | SHA-256 |
| Encryption | Optional |

**Attributes & Claims:**

```json
{
  "claims": [
    {
      "name": "email",
      "source": "user",
      "essential": true
    },
    {
      "name": "name",
      "source": "user",
      "essential": true
    },
    {
      "name": "firstName",
      "source": "user",
      "essential": false
    },
    {
      "name": "lastName",
      "source": "user",
      "essential": false
    },
    {
      "name": "externalId",
      "source": "user",
      "essential": true
    }
  ]
}
```

---

## 15) Rollback Strategy

### 15.1 Scenarios

| Scenario | Rollback Steps | Downtime |
|----------|----------------|----------|
| SAML authentication failures | Feature flag to disable SAML, fallback to local auth | 0 min |
| Azure AD misconfiguration | Revert to previous app deployment | 2-5 min |
| Certificate expired | Use backup certificate, rotate cert | 0 min |
| User provisioning errors | Disable JIT provisioning, manual user creation | 0 min |
| Complete SAML failure | Disable SAML entirely, maintain local auth | < 1 min |

### 15.2 Feature Flag Configuration

```yaml
features:
  saml:
    enabled: true
    sp_initiated_enabled: true
    idp_initiated_enabled: true
    slo_enabled: true
    jit_provisioning_enabled: true
    encryption_enabled: false
  fallback_auth:
    enabled: true
    method: 'local'  # or 'oidc'
```

---

**Status:** Ready for review  
**Next Steps:** Create tracking issue for Phase 1 (SAML Foundation implementation)
