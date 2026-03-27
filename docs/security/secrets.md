# Secrets Handling Policy

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Define how secrets are managed, stored, and used across development and production environments

---

## 0) Overview

### 0.1 What is a Secret?
A secret is any sensitive information that must be protected:
- API keys and tokens
- Database credentials
- Service account keys
- Certificates and private keys
- OAuth client secrets
- Webhook signing secrets
- Encryption keys

### 0.2 Single Source of Truth (SSOT)
This project uses **two** secret management systems, each serving specific purposes:

| System | Purpose | Environment | Examples |
|--------|---------|-------------|----------|
| **GitHub Secrets** | CI/CD secrets, PR automation | GitHub Actions | Deploy keys, test database credentials |
| **GCP Secret Manager** | Production secrets, runtime configuration | GCP Cloud Run / Cloud SQL | Production DB passwords, API keys |

> **Never** store secrets in code, environment files, or public documentation.

---

## 1) GitHub Secrets (CI/CD)

### 1.1 When to Use
- GitHub Actions workflows
- Deploying to staging/production
- Running tests in CI that require external services
- Automating PR operations

### 1.2 Secret Naming Convention
Use descriptive, environment-specific prefixes:

```
PRODUCTION_DB_HOST
STAGING_DB_HOST
TEST_DB_HOST
DEPLOY_KEY_STAGING
DEPLOY_KEY_PRODUCTION
CLOUDRUN_SA_KEY
```

### 1.3 Access Control
- **Maintainers:** Can view and modify all secrets
- **Developers:** Cannot view secrets, can only use them in workflows
- **External collaborators:** No access to secrets

### 1.4 Workflow Usage Example

```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Cloud Run
        run: |
          gcloud auth activate-service-account --key-file=${{ secrets.CLOUDRUN_SA_KEY }}
          gcloud run deploy ${{ secrets.SERVICE_NAME }} --image=${{ secrets.IMAGE_URL }}
```

---

## 2) GCP Secret Manager (Production)

### 2.1 When to Use
- Production Cloud Run services
- Production Cloud SQL databases
- Third-party API integrations
- Any secret needed at runtime

### 2.2 Secret Naming Convention
Use hierarchical naming with environment and service context:

```
projects/<project-id>/secrets/production-db-host
projects/<project-id>/secrets/production-db-password
projects/<project-id>/secrets/stripe-api-key
projects/<project-id>/secrets/external-service-webhook-secret
```

### 2.3 Access via IAM
Configure IAM roles for Secret Manager access:

| Role | Purpose |
|------|---------|
| `roles/secretmanager.secretAccessor` | Read-only access to secrets |
| `roles/secretmanager.secretVersionManager` | Add/update secret versions |
| `roles/secretmanager.admin` | Full access (limit to humans) |

### 2.4 Code Usage Example

```typescript
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

async function getSecret(name: string): Promise<string> {
  const [version] = await client.accessSecretVersion({
    name: `projects/${process.env.PROJECT_ID}/secrets/${name}/versions/latest`,
  });
  return version.payload?.data?.toString() || '';
}

// Usage
const dbPassword = await getSecret('production-db-password');
```

---

## 3) DOs and DON'Ts

### 3.1 DO
- ✅ Use GitHub Secrets for CI/CD workflows
- ✅ Use GCP Secret Manager for production runtime secrets
- ✅ Rotate secrets periodically (recommended: every 90 days)
- ✅ Grant least-privilege access (read-only for services)
- ✅ Use environment-specific secrets (dev/staging/prod)
- ✅ Audit secret access via Cloud Audit Logs
- ✅ Enable secret versioning for rollbacks
- ✅ Use placeholder values in documentation (e.g., `YOUR_API_KEY_HERE`)

### 3.2 DON'T
- ❌ Commit `.env` files or any secret values to the repository
- ❌ Print or log secrets in console outputs, logs, or error messages
- ❌ Share secrets via chat, email, or issue comments
- ❌ Use the same secret across multiple environments
- ❌ Hardcode secrets in application code
- ❌ Check in service account keys or certificates
- ❌ Use secrets in client-side code (frontend apps)
- ❌ Commit secrets in Git history (even if deleted later)

### 3.3 Placeholder Examples
When documenting or testing, use these placeholder patterns:

| Secret Type | Placeholder Pattern |
|-------------|---------------------|
| API Key | `api-key-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |
| Database Password | `db-p@ssw0rd-12345` |
| Service Account Key | `[SERVICE_ACCOUNT_KEY_JSON]` |
| OAuth Secret | `oauth-client-secret-abc123` |
| Webhook URL | `https://example.com/webhook/YOUR_TOKEN` |

---

## 4) Incident Response: Secret Leak

### 4.1 Immediate Actions (First 15 Minutes)
1. **Stop the leak:**
   - Remove secret from public location (repository, issue, PR comment)
   - Delete the file/content if possible
   - Force-push to remove from Git history if committed

2. **Rotate the secret:**
   - Generate new secret value
   - Update in secret manager (GitHub Secrets or GCP Secret Manager)
   - Redeploy affected services

3. **Notify stakeholders:**
   - Alert maintainers and security team
   - If production API key: notify third-party provider to revoke old key
   - Document the incident timestamp

### 4.2 Post-Incident Actions (Within 24 Hours)
1. **Investigation:**
   - Determine scope of exposure (who saw it, when, how)
   - Check logs for unauthorized access using the leaked secret
   - Review access controls that allowed the leak

2. **Remediation:**
   - Add pre-commit hooks to prevent future leaks
   - Update developer onboarding documentation
   - Consider implementing secret scanning tools (e.g., truffleHog, gitleaks)

3. **Documentation:**
   - Create incident report
   - Update security lessons learned
   - Share findings with team to prevent recurrence

### 4.3 Communication Template

```markdown
## Security Incident: Secret Leak

**Severity:** High  
**Status:** Mitigated  
**Timeline:** YYYY-MM-DD HH:MM UTC

### Summary
Brief description of what was leaked and where.

### Affected Systems
- [ ] GitHub repository
- [ ] CI/CD workflows
- [ ] Production services
- [ ] Third-party APIs

### Actions Taken
1. Secret rotated at HH:MM
2. Services redeployed at HH:MM
3. Leaked content removed at HH:MM
4. Third-party notified at HH:MM

### Investigation
[Details about root cause]

### Prevention Measures
[Changes to prevent recurrence]
```

---

## 5) Security Best Practices

### 5.1 Pre-Commit Protection
Add `.pre-commit-config.yaml` to detect secrets before committing:

```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

### 5.2 GitHub Secret Scanning
- Enable GitHub Advanced Security secret scanning
- Configure custom patterns for project-specific secrets
- Set up alerts for detected secrets

### 5.3 Access Audit
Regularly review:
- Who has access to GitHub Secrets (Maintainers list)
- IAM policies for GCP Secret Manager access
- Secret version history for unauthorized changes
- Audit logs for secret access (who, when, which secret)

### 5.4 Secret Rotation Schedule
| Secret Type | Rotation Frequency |
|-------------|-------------------|
| Database passwords | Every 90 days |
| API keys | Every 90 days or upon suspicion of leak |
| Service account keys | Every 90-180 days |
| OAuth client secrets | Every 90-180 days |
| TLS/SSL certificates | Before expiration (typically 1 year) |

---

## 6) Tools and References

### 6.1 Secret Scanning Tools
- **gitleaks**: Detect secrets in Git history
- **truffleHog**: Search for high-entropy strings
- **detect-secrets**: Pre-commit hook for secret detection
- **GitHub Secret Scanning**: Built-in secret detection

### 6.2 GCP Documentation
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Secret Manager Best Practices](https://cloud.google.com/secret-manager/docs/best-practices)
- [IAM Roles for Secret Manager](https://cloud.google.com/secret-manager/docs/access-control)

### 6.3 GitHub Documentation
- [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)

### 6.4 Security Standards
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [NIST SP 800-57: Key Management](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)

---

## 7) FAQ

### Q1: Can I use `.env` files for local development?
**A:** Yes, but never commit them to the repository. Add `.env` to `.gitignore` and provide a `.env.example` file with placeholder values.

### Q2: How do I share secrets with new team members?
**A:** For CI/CD secrets, maintainers can add the team member to the repository with appropriate permissions. For production secrets, grant IAM roles for GCP Secret Manager access. Never share secrets via chat or email.

### Q3: What if I accidentally commit a secret?
**A:** See Section 4 (Incident Response). Immediately rotate the secret, remove it from the repository history, and notify the security team.

### Q4: Can I use the same secret for staging and production?
**A:** No. Always use separate secrets for each environment to prevent accidental production exposure during testing.

### Q5: How do I handle secrets in local development?
**A:** Use a local `.env` file (gitignored) or a local secrets manager like `envchain`, `direnv`, or GCP Secret Manager CLI for development.

---

**Status:** Active  
**Next Review:** 2026-05-01  
**Maintained By:** Security & OSS Compliance Agent (SOCA)
