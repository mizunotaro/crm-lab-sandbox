# Data Export Operations

**Version:** 1.0  
**Last Updated:** 2026-01-31  
**Purpose:** Operational guidance for periodic data exports, secure storage, retention, and access control.

---

## 0) Overview

This document defines operational procedures for exporting contact data from the CRM system, including:
- Export execution
- Secure storage
- Access logging
- Retention policies
- Cleanup procedures

> **Scope:** Contact management data exports (CSV format primarily).  
> **Platform:** GCP (Cloud Storage for storage, Cloud SQL as data source).

---

## 1) Export Execution

### 1.1 Export Triggers

Data exports may be triggered by:
- **Scheduled exports:** Automated daily/weekly/monthly exports
- **On-demand exports:** User-initiated exports via UI
- **Compliance exports:** Legal/regulatory data requests

### 1.2 Export Format and Contents

- **Format:** CSV (Comma-Separated Values)
- **Encoding:** UTF-8
- **Compression:** Optional gzip compression for large exports
- **Contents:** Contact fields (name, email, phone, company, tags, created_at, updated_at)
- **Metadata:** Export timestamp, export ID, requester (if applicable)

### 1.3 Export Procedures

#### Scheduled Exports

1. **Preparation**
   - [ ] Verify storage bucket has sufficient quota
   - [ ] Confirm export schedule is active
   - [ ] Check retention compliance for data being exported

2. **Execution**
   - [ ] Trigger export job via automated workflow
   - [ ] Monitor job completion status
   - [ ] Verify file integrity post-export (checksum verification)

3. **Post-Export Validation**
   - [ ] Confirm file created in designated bucket/path
   - [ ] Verify record count matches source
   - [ ] Check for encoding issues or corruption
   - [ ] Log export completion with timestamp and file reference

#### On-Demand Exports

1. **Authorization**
   - [ ] Verify user has export permissions
   - [ ] Document export request purpose (if compliance-related)
   - [ ] Record requester identity and timestamp

2. **Execution**
   - [ ] Initiate export via UI or API
   - [ ] Provide unique export ID to requester
   - [ ] Monitor for completion

3. **Access Control**
   - [ ] Store export in requester-specific path
   - [ ] Apply appropriate ACLs (Access Control Lists)
   - [ ] Generate secure download link if needed
   - [ ] Set expiration for download links (max 24 hours recommended)

---

## 2) Secure Storage

### 2.1 Storage Location

- **Primary Storage:** GCP Cloud Storage (bucket: `${EXPORT_BUCKET_NAME}`)
- **Folder Structure:**
  ```
  /exports/
    /scheduled/
      /daily/
        /YYYY/
          /MM/
            /YYYY-MM-DD.csv
      /weekly/
        /YYYY/
          /WW/
            /YYYY-WW.csv
      /monthly/
        /YYYY/
          /YYYY-MM.csv
    /on-demand/
      /user-{user-id}/
        /{export-id}/
          /{export-id}.csv
    /compliance/
      /{request-id}/
        /{request-id}.csv
        /request-metadata.json
  ```

### 2.2 Security Controls

#### Encryption at Rest
- [ ] Enable Cloud Storage default encryption (Google-managed or customer-managed keys)
- [ ] Verify encryption status on export bucket
- [ ] Document key rotation schedule (if customer-managed keys)

#### Access Control
- [ ] Apply principle of least privilege
- [ ] Use IAM roles and permissions
- [ ] Restrict bucket access to service accounts only
- [ ] Implement VPC Service Controls if required

**Recommended IAM Roles:**
- **Export Service Account:** `roles/storage.objectAdmin` (scoped to export bucket only)
- **Auditor Role:** `roles/storage.objectViewer` (read-only for audit purposes)
- **Compliance Team:** Custom role with limited access to compliance exports

#### Bucket Policies
- [ ] Disable public access
- [ ] Enable uniform bucket-level access
- [ ] Set up retention policies where legally required
- [ ] Configure object lifecycle rules for automated cleanup

---

## 3) Access Logging

### 3.1 Logging Requirements

All access to exported data must be logged and retained for audit purposes.

### 3.2 Access Logs

#### What to Log
- **Timestamp:** Date and time of access
- **Actor:** User or service account accessing the data
- **Action:** Read, download, delete, or list
- **Resource:** Export file path and export ID
- **Source IP:** IP address of requestor (for human access)
- **Outcome:** Success or failure

#### Log Storage
- **Destination:** Cloud Logging (Audit Logs)
- **Retention:** Minimum 1 year for access logs
- **Format:** Structured JSON for easy querying

### 3.3 Monitoring and Alerts

#### Critical Access Patterns to Monitor
- [ ] Unusual access times (e.g., access outside business hours)
- [ ] Large volume downloads in short timeframes
- [ ] Access from unexpected geographic regions
- [ ] Failed access attempts (potential unauthorized access)
- [ ] Bulk export requests

#### Alert Configuration
- [ ] Set up alerts for access from unauthorized IPs
- [ ] Alert on multiple failed access attempts (>5 within 1 hour)
- [ ] Alert on exports to compliance folder for review
- [ ] Alert on access to exports older than retention period

### 3.4 Audit Review

#### Regular Reviews
- **Weekly:** Review access to compliance exports
- **Monthly:** Review overall access patterns
- **Quarterly:** Full access audit and rights review

#### Audit Report Contents
- Total exports created during period
- Breakdown by export type (scheduled/on-demand/compliance)
- Top users by export access count
- Anomalies or suspicious activity
- Retention compliance status
- Recommendations for improvements

---

## 4) Retention Policies

### 4.1 Retention Periods

| Export Type | Default Retention | Legal Hold Override |
|-------------|-------------------|---------------------|
| Daily scheduled exports | 90 days | Indefinite (with hold) |
| Weekly scheduled exports | 1 year | Indefinite (with hold) |
| Monthly scheduled exports | 2 years | Indefinite (with hold) |
| On-demand exports | 30 days | Indefinite (with hold) |
| Compliance exports | 7 years or per legal requirement | Indefinite |

### 4.2 Lifecycle Management

#### Automated Cleanup
- [ ] Configure Cloud Storage lifecycle rules
- [ ] Apply age-based deletion according to retention periods
- [ ] Override retention for exports under legal hold
- [ ] Log all deletions for audit purposes

#### Manual Cleanup Exceptions
Only manually delete exports when:
- Data subject request (GDPR/right to be forgotten) is approved
- Legal hold is lifted and retention period expired
- Corrupted or invalid export files identified

---

## 5) Security Checklist

### 5.1 Pre-Export Checklist
- [ ] Exporter has appropriate permissions
- [ ] Storage bucket encryption enabled
- [ ] Sufficient storage quota available
- [ ] No active security incidents affecting data source
- [ ] Backup or DR plan tested (if critical export)

### 5.2 Post-Export Checklist
- [ ] File stored in correct bucket/path
- [ ] Access logs enabled and recording
- [ ] Appropriate ACLs applied
- [ ] Export ID recorded in tracking system
- [ ] Retention policy tag applied (if applicable)

### 5.3 Access Review Checklist (Monthly)
- [ ] Review all access logs for anomalies
- [ ] Verify only authorized users have access
- [ ] Confirm no public access exists
- [ ] Check for stale access permissions
- [ ] Validate retention compliance

---

## 6) Emergency Procedures

### 6.1 Unauthorized Access Detected

1. **Immediate Actions**
   - [ ] Revoke access to affected export files
   - [ ] Suspend export operations if source is compromised
   - [ ] Initiate incident response (see `docs/ops/incident-response.md`)
   - [ ] Document scope and impact

2. **Containment**
   - [ ] Change storage bucket permissions if needed
   - [ ] Rotate storage encryption keys (if customer-managed)
   - [ ] Block suspicious IP ranges
   - [ ] Reset credentials for compromised accounts

3. **Recovery**
   - [ ] Verify source data integrity
   - [ ] Re-run exports if needed
   - [ ] Update monitoring/alerts to prevent recurrence
   - [ ] Complete incident report

### 6.2 Export Failure

1. **Diagnosis**
   - [ ] Check Cloud Storage bucket health
   - [ ] Verify service account permissions
   - [ ] Review error logs in Cloud Logging
   - [ ] Confirm data source connectivity

2. **Resolution**
   - [ ] Address root cause (permissions, quota, connectivity)
   - [ ] Re-attempt export
   - [ ] Update documentation if systematic issue found
   - [ ] Alert if export SLA impacted

---

## 7) Related Documentation

- `docs/ops/incident-response.md` — Security incident handling
- `AGENTS.md` — Security policies (§0.5) and release guidelines (§9)
- `ops/issues/gcp-serverless-crm-poc/spec-009-contact-management.md` — Contact management system spec

---

## 8) Contact Information

| Role | Responsibility | Contact |
|------|----------------|---------|
| DevOps Engineer | Export workflows and storage | [TBD] |
| Security Engineer | Access control and monitoring | [TBD] |
| Compliance Officer | Retention policy and legal holds | [TBD] |
| Database Administrator | Data source queries | [TBD] |

---

## 9) Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-31 | 1.0 | Initial creation | AI Agent |

---

**NOTE:** Never commit actual credentials, API keys, or secrets to this repository. Use environment variable placeholders (e.g., `${EXPORT_BUCKET_NAME}`) in operational procedures.
