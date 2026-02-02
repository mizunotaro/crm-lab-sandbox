# GCP Secret Manager Mapping

This document describes how secrets should be stored in GCP Secret Manager and mapped from GitHub Secrets/Actions at deploy time.

## Overview

This project uses GCP Secret Manager for production secrets. Secrets are never committed to the repository and should be injected at deploy time via GitHub Actions.

## Secret Naming Conventions

Secrets in GCP Secret Manager follow this naming pattern:

```
projects/<PROJECT_ID>/secrets/<SECRET_NAME>/versions/<VERSION>
```

### Secret Names

| Secret Name | Environment | Purpose | Example Placeholder |
|-------------|------------|---------|---------------------|
| `db-connection-url` | production | PostgreSQL Cloud SQL connection string | `postgresql://user:****@host:5432/dbname` |
| `api-jwt-secret` | production | JWT signing key for API authentication | `<random-256-bit-key>` |
| `gcp-sa-key` | production | Google Cloud service account key JSON | `{"type": "service_account", ...}` |
| `web-vite-api-key` | production | API key for frontend services | `<api-key-string>` |

**NOTE:** Never commit actual secret values. Only use placeholders in documentation.

## Storing Secrets in GCP Secret Manager

### Prerequisites

```bash
# Install Google Cloud SDK (if not already installed)
gcloud --version

# Authenticate with GCP
gcloud auth login

# Set your project
gcloud config set project <PROJECT_ID>
```

### Create a Secret

```bash
# Create a new secret version
echo -n "<SECRET_VALUE>" | \
  gcloud secrets versions add db-connection-url \
    --project=<PROJECT_ID> \
    --data-file=-

# Create a secret with automatic versioning
gcloud secrets create api-jwt-secret \
  --project=<PROJECT_ID> \
  --replication-policy="automatic"
```

### List Secrets

```bash
# List all secrets in the project
gcloud secrets list --project=<PROJECT_ID>

# Get secret metadata
gcloud secrets describe db-connection-url --project=<PROJECT_ID>
```

### Access Secret Versions

```bash
# Access the latest version
gcloud secrets versions access latest \
  --secret=db-connection-url \
  --project=<PROJECT_ID>

# Access a specific version
gcloud secrets versions access 2 \
  --secret=db-connection-url \
  --project=<PROJECT_ID>
```

## GitHub Actions Integration

### GitHub Secrets Configuration

Store the following in GitHub Repository Settings → Secrets and variables → Actions:

| GitHub Secret Name | GCP Secret Manager Secret | Description |
|--------------------|---------------------------|-------------|
| `GCP_PROJECT_ID` | - | GCP project ID (public) |
| `GCP_SA_KEY` | `gcp-sa-key` | Base64-encoded service account key with Secret Manager access |
| `DB_CONNECTION_URL` | `db-connection-url` | PostgreSQL connection string (for testing only) |
| `API_JWT_SECRET` | `api-jwt-secret` | JWT signing key (for testing only) |

### GitHub Actions Workflow Example

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'production'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - uses: actions/checkout@v4

      - id: auth
        name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Deploy to Cloud Run
        uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: crm-api
          region: us-central1
          source: ./apps/api
          secrets: |
            DB_CONNECTION_URL=db-connection-url:latest
            API_JWT_SECRET=api-jwt-secret:latest
```

### Accessing Secrets from Cloud Run

When deploying to Cloud Run, secrets are referenced using the `--set-secrets` flag:

```bash
# Deploy with secret references
gcloud run deploy crm-api \
  --image=gcr.io/<PROJECT_ID>/crm-api:latest \
  --region=us-central1 \
  --set-secrets="DB_CONNECTION_URL=db-connection-url:latest,API_JWT_SECRET=api-jwt-secret:latest"
```

### Accessing Secrets from Application Code

#### Node.js/TypeScript (using `@google-cloud/secret-manager`)

```typescript
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

async function accessSecret(secretName: string): Promise<string> {
  const [version] = await client.accessSecretVersion({
    name: `projects/${process.env.GCP_PROJECT_ID}/secrets/${secretName}/versions/latest`
  });
  return version.payload?.data?.toString() || '';
}

// Usage
const dbUrl = await accessSecret('db-connection-url');
```

#### Environment Variable Mapping (for local development)

For local development, use a `.env.local` file (never committed):

```bash
# .env.local (add to .gitignore)
DB_CONNECTION_URL=postgresql://localhost:5432/crm_dev
API_JWT_SECRET=dev-jwt-secret-change-in-production
```

## Secret Rotation

### Manual Rotation

```bash
# 1. Create a new secret version
echo -n "<NEW_VALUE>" | \
  gcloud secrets versions add api-jwt-secret \
    --project=<PROJECT_ID> \
    --data-file=-

# 2. Deploy the new version
gcloud run deploy crm-api \
  --image=gcr.io/<PROJECT_ID>/crm-api:latest \
  --region=us-central1 \
  --set-secrets="API_JWT_SECRET=api-jwt-secret:2"

# 3. Verify the deployment
gcloud run services describe crm-api --region=us-central1
```

### Automatic Rotation (Future)

Implement secret rotation by:
1. Setting up Cloud Scheduler jobs
2. Creating rotation scripts that update secret versions
3. Triggering redeployments via Pub/Sub

## Secret Access Logs

Monitor secret access via Cloud Logging:

```bash
# View secret access logs
gcloud logging read \
  'resource.type="secret_manager_secret"' \
  --project=<PROJECT_ID> \
  --format="table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.resourceName)"
```

## Security Best Practices

1. **Never log or commit secrets**: All secrets should be externalized
2. **Use IAM least privilege**: Grant only necessary permissions
3. **Enable secret versioning**: Keep audit trail of changes
4. **Rotate secrets regularly**: Implement rotation policies
5. **Monitor access**: Set up alerts for unauthorized access
6. **Separate environments**: Use different secrets for dev/stage/prod
7. **Encrypt at rest**: GCP Secret Manager handles encryption automatically

## IAM Permissions Required

For deployment workflows, the service account should have these roles:

- `roles/secretmanager.secretAccessor` - Read secret values
- `roles/secretmanager.viewer` - List and view secret metadata
- `roles/run.developer` - Deploy to Cloud Run
- `roles/cloudbuild.builds.builder` - Build container images

## Troubleshooting

### Permission Denied

```bash
# Grant secret accessor role
gcloud secrets add-iam-policy-binding db-connection-url \
  --member='serviceAccount:<SA_EMAIL>' \
  --role='roles/secretmanager.secretAccessor' \
  --project=<PROJECT_ID>
```

### Secret Not Found

```bash
# Verify secret exists
gcloud secrets list --project=<PROJECT_ID> --filter="name:db-connection-url"

# List versions
gcloud secrets versions list db-connection-url --project=<PROJECT_ID>
```

### Cloud Run Deployment Fails

```bash
# Verify secret reference format
gcloud run services describe crm-api --region=us-central1 --format="yaml(spec.template.containers[0].env)"
```

## References

- [GCP Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [Cloud Run Secrets Documentation](https://cloud.google.com/run/docs/configuring/secrets)
- [GitHub Actions GCP Authentication](https://github.com/google-github-actions/auth)
