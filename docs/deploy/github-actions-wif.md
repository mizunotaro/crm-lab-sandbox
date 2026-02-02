# GitHub Actions Workload Identity Federation (WIF) for Cloud Run

This document describes how to configure GitHub Actions to deploy to Google Cloud Run using Workload Identity Federation (WIF), which is the recommended authentication method that avoids storing long-lived credentials.

## Overview

Workload Identity Federation allows GitHub Actions to authenticate with Google Cloud using a short-lived access token, eliminating the need for service account keys.

## Prerequisites

- Google Cloud project with Cloud Run enabled
- GitHub repository with Actions enabled
- Appropriate permissions to configure IAM and Workload Identity Federation

## Setup Steps

### 1. Create or Use Existing Service Account

Create a service account that will be used for deployments:

```bash
# Replace PROJECT_ID with your actual project ID
PROJECT_ID="your-project-id"
SA_NAME="github-actions-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create ${SA_NAME} \
  --display-name="GitHub Actions Deployer"
```

### 2. Grant Required Permissions to Service Account

Grant the service account permissions to deploy to Cloud Run and access required resources:

```bash
# Cloud Run Admin role (for deploying services)
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.admin"

# Cloud Build Service Account role (for building and pushing images)
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.builder"

# Service Account User role (for acting as Cloud Build service account)
gcloud iam service-accounts add-iam-policy-binding ${PROJECT_ID}@cloudbuild.gserviceaccount.com \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# TODO: Add additional roles as needed (e.g., Secret Manager, Cloud SQL, etc.)
```

### 3. Create Workload Identity Pool and Provider

Create a workload identity pool for GitHub Actions:

```bash
# Create workload identity pool
gcloud iam workload-identity-pools create github-actions-pool \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe github-actions-pool \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")

# Create workload identity provider
gcloud iam workload-identity-pools providers create github-provider \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref"

# Get provider ID
PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe github-provider \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)")
```

### 4. Configure IAM Binding

Allow the GitHub repository to impersonate the service account:

```bash
# Replace GITHUB_ORG and REPO_NAME with your GitHub org/repo
GITHUB_ORG="your-github-org"
REPO_NAME="your-repo-name"

gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${GITHUB_ORG}/${REPO_NAME}"
```

### 5. Configure GitHub Secrets

Add the following secrets to your GitHub repository settings (`Settings` > `Secrets and variables` > `Actions`):

#### Required Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|----------------|
| `GCP_WIF_PROVIDER` | Workload Identity Provider resource name | `projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider` |
| `GCP_SA_EMAIL` | Service account email | `github-actions-deployer@your-project-id.iam.gserviceaccount.com` |
| `GCP_PROJECT_ID` | GCP project ID | `your-project-id` |
| `GCP_ARTIFACT_REGISTRY_REPO` | Artifact Registry repository name | `docker-repo` |

#### Environment-Specific Secrets (Optional)

For each environment (dev/staging/production), you may need additional secrets:

| Secret Name | Description |
|-------------|-------------|
| `CLOUD_RUN_DB_URL` | Database connection URL (stored in Secret Manager) |
| `API_KEY` | API keys for third-party services |
| `ENV_VAR_*` | Environment-specific configuration |

**Note:** Sensitive values should be stored in Secret Manager and referenced in Cloud Run deployments using `--set-env-secrets`.

### 6. Update Workflow Configuration

The workflow file `.github/workflows/deploy-cloud-run.yml` is pre-configured to use WIF. Ensure the following:

- `GCP_WIF_PROVIDER` secret is set to your workload identity provider
- `GCP_SA_EMAIL` secret is set to your service account email
- `GCP_PROJECT_ID` and `GCP_ARTIFACT_REGISTRY_REPO` are configured

### 7. Test the Setup

Test the deployment workflow:

1. Go to the `Actions` tab in your GitHub repository
2. Select `Deploy to Cloud Run` workflow
3. Click `Run workflow`
4. Choose the environment, region, and service name
5. Monitor the workflow execution

## Security Best Practices

1. **Principle of Least Privilege**: Grant only the minimum permissions needed for deployment
2. **Separate Service Accounts**: Use different service accounts for different environments (dev/staging/production)
3. **Secret Management**: Store sensitive data in Secret Manager, not in GitHub secrets
4. **Branch Protection**: Require approval for production deployments
5. **Environment Rules**: Configure GitHub environment protection rules for production

## Troubleshooting

### "Permission denied" errors

Verify that the service account has the required IAM roles:
```bash
gcloud projects get-iam-policy ${PROJECT_ID} --filter="serviceAccount:${SA_EMAIL}"
```

### "Invalid token" errors

Check that the workload identity provider is correctly configured:
```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool"
```

### Repository not authorized

Verify the IAM binding includes the correct repository:
```bash
gcloud iam service-accounts get-iam-policy ${SA_EMAIL}
```

## Additional Resources

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions for Google Cloud](https://github.com/google-github-actions/auth)
- [Cloud Run Deployment](https://cloud.google.com/run/docs/deploying)

## TODO: Customization Required

- [ ] Update Docker build logic in workflow (paths, Dockerfile location)
- [ ] Configure environment-specific variables and secrets
- [ ] Implement health check verification
- [ ] Add deployment rollback mechanism
- [ ] Configure branch protection rules for production
- [ ] Set up separate service accounts for each environment
