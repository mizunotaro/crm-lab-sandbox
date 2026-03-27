# Incident Response Template

**Version:** 1.0  
**Last Updated:** 2026-01-31  
**Purpose:** Minimal template for handling security incidents, specifically secrets leaks and credential exposure events.

---

## 0) Immediate Actions (PAUSE Circuit Breaker)

### 0.1 Activate PAUSE
- [ ] Stop all non-critical deployments
- [ ] Suspend automated processes touching affected systems
  - Set `AI_AUTOMATION_MODE=PAUSE` (see `docs/ops/ai-automation-control.md`)
- [ ] Notify incident response team (IRT)
- [ ] Create incident ticket with severity level

### 0.2 Assign Roles
- **Incident Commander (IC):** Overall coordination
- **Technical Lead:** Investigation and remediation
- **Communications Lead:** Stakeholder notifications
- **Documentation Scribe:** Timeline and evidence logging

---

## 1) Identification Phase

### 1.1 Initial Assessment
- [ ] Determine incident type (secrets leak, credential exposure, unauthorized access)
- [ ] Estimate potential impact scope
- [ ] Identify affected systems and data
- [ ] Set severity level (P0-P4)

### 1.2 Containment Strategy
- [ ] Isolate affected systems if possible
- [ ] Revoke suspicious credentials immediately
- [ ] Disable compromised accounts
- [ ] Block malicious IPs/domains

---

## 2) Evidence Collection

### 2.1 Forensic Evidence
- [ ] Capture logs from affected systems (last 7 days recommended)
- [ ] Document incident timeline (when first detected, response actions taken)
- [ ] Record environment details (region, service, version)
- [ ] Screenshot affected UI/console outputs

### 2.2 Evidence Preservation
**IMPORTANT:** Never log or commit secrets, tokens, or credentials.

- [ ] Store evidence in secure, access-controlled location
- [ ] Hash all captured files for integrity verification
- [ ] Document chain of custody
- [ ] Use reference IDs instead of actual secrets in documentation

Example:
```
BAD: "Leaked API key: sk-1234567890abcdef"
GOOD: "Leaked credential: REF-ID-001 (rotated at 2026-01-31T14:30:00Z)"
```

---

## 3) Eradication & Recovery

### 3.1 Secrets Rotation (General Guidance)
**NOTE:** Specific rotation steps depend on the credential type and platform. Always follow platform-specific documentation.

- [ ] Identify all locations where compromised secret was used
- [ ] Generate new credentials using approved methods
- [ ] Update all applications/services using the old secret
- [ ] Verify new credentials work in staging environment first
- [ ] Deploy to production with monitoring
- [ ] Invalidate old credentials after new ones are verified

### 3.2 Platform-Specific Resources
- **GCP:** https://cloud.google.com/security-key-management
- **GitHub:** https://docs.github.com/en/authentication
- **PostgreSQL:** https://www.postgresql.org/docs/current/user-manag.html

### 3.3 Verification Steps
- [ ] Confirm no unauthorized access continues
- [ ] Verify all systems using new credentials
- [ ] Run security scans on affected codebases
- [ ] Review audit logs for other suspicious activity
- [ ] Validate containment was effective

---

## 4) Post-Incident Activity

### 4.1 Root Cause Analysis
- [ ] Document how the incident occurred
- [ ] Identify process gaps or technical vulnerabilities
- [ ] Determine if this was a one-time or systemic issue

### 4.2 Remediation Actions
- [ ] Fix technical vulnerabilities
- [ ] Update documentation/policies
- [ ] Implement additional monitoring/alerts
- [ ] Update secrets scanning processes

### 4.3 Communication
- [ ] Internal post-mortem meeting
- [ ] Update stakeholders (if required)
- [ ] Document lessons learned
- [ ] Create action items for prevention

---

## 5) Incident Report Template

### 5.1 Executive Summary
- Incident type and severity
- Impact summary
- Resolution status
- Timeline (start to close)

### 5.2 Technical Details
- Systems affected
- Vulnerabilities exploited
- Remediation steps taken
- Verification performed

### 5.3 Lessons Learned
- What worked well
- What needs improvement
- Action items with owners and due dates

---

## 6) Prevention Checklist

### 6.1 Secrets Management
- [ ] Use secret management service (e.g., GCP Secret Manager)
- [ ] Never commit secrets to version control
- [ ] Rotate credentials regularly
- [ ] Implement secrets scanning in CI/CD
- [ ] Use least-privilege access policies

### 6.2 Monitoring & Alerting
- [ ] Set up anomaly detection for unusual access patterns
- [ ] Monitor for credential usage spikes
- [ ] Alert on failed authentication attempts
- [ ] Regular audit log reviews

### 6.3 Incident Preparedness
- [ ] Maintain updated contact list for IRT
- [ ] Conduct regular incident response drills
- [ ] Keep this document accessible to all team members
- [ ] Document platform-specific recovery procedures

---

## 7) Emergency Contacts

| Role | Contact | Timezone |
|------|---------|----------|
| Incident Commander | [TBD] | [TBD] |
| Technical Lead | [TBD] | [TBD] |
| Communications Lead | [TBD] | [TBD] |

---

## 8) Quick Reference

### Severity Levels
- **P0:** Critical - Production outage or confirmed security breach
- **P1:** High - Significant service degradation or potential security issue
- **P2:** Medium - Limited impact or confirmed non-critical security issue
- **P3:** Low - Minimal impact or potential security concern
- **P4:** Informational - Documentation or process improvement

### PAUSE Triggers
- Confirmed credential leak
- Unauthorized access detected
- Suspicious activity in production
- Compliance/regulatory concern raised

### Evidence Collection Commands (Examples)
```powershell
# Capture system logs (adjust paths as needed)
Get-EventLog -LogName Application -EntryType Error,Warning -After (Get-Date).AddDays(-7) | Export-Clixml app-logs.xml

# Get process information
Get-Process | Select-Object Id, ProcessName, StartTime | Export-Csv processes.csv

# Network connections (PowerShell 7+)
Get-NetTCPConnection | Select-Object LocalAddress, RemoteAddress, State | Export-Csv connections.csv
```

---

**Related Procedures:**
- **AI Automation Control:** See `docs/ops/ai-automation-control.md` for setting AI_AUTOMATION_MODE
- **Helper Script:** See `ops/scripts/set-ai-automation-mode.ps1` for automated mode setting

**Reference:** See `AGENTS.md` §0.5 for security policies and §5.3 for dependency management.
