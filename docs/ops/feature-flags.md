# Feature Flags

This document describes the environment variable-based feature flag system used in the CRM Lab Sandbox.

## Overview

Feature flags allow safe rollout of features by controlling them via environment variables. This is a minimal implementation with no external dependencies.

## Usage

### Checking a Flag

```typescript
import { isEnabled } from '@crm/shared';

if (isEnabled('CSV_IMPORT')) {
  // CSV import functionality
} else {
  // Show disabled message
}
```

### Setting Flags via Environment Variables

Flags are controlled via environment variables with the prefix `FEATURE_FLAG_`:

| Flag Name | Environment Variable | Default |
|-----------|---------------------|---------|
| CSV_IMPORT | FEATURE_FLAG_CSV_IMPORT | false |
| BULK_EXPORT | FEATURE_FLAG_BULK_EXPORT | false |

**Valid values for enabling a flag:** `1`, `true`, `TRUE` (case-insensitive)
**All other values or missing variables:** Flag is disabled

### Examples

**Enable CSV import feature:**
```bash
export FEATURE_FLAG_CSV_IMPORT=1
```

**Disable CSV import feature:**
```bash
export FEATURE_FLAG_CSV_IMPORT=0
# or
unset FEATURE_FLAG_CSV_IMPORT
```

### Adding New Flags

1. Define a new flag name (use UPPER_CASE naming convention)
2. Add documentation to this file with:
   - Flag name
   - Environment variable
   - Description
   - Risk level (low/medium/high)
   - Rollback plan
3. Use `isEnabled('YOUR_FLAG')` in the code

## Current Flags

### CSV_IMPORT

- **Environment Variable:** `FEATURE_FLAG_CSV_IMPORT`
- **Description:** Enables CSV contact import functionality
- **Risk Level:** low
- **Rollback Plan:** Disable flag by removing or setting to `0`. No data migration needed.

### BULK_EXPORT

- **Environment Variable:** `FEATURE_FLAG_BULK_EXPORT`
- **Description:** Enables bulk export of contacts (placeholder for future feature)
- **Risk Level:** low
- **Rollback Plan:** Disable flag. No data changes.

## Best Practices

1. **Default to disabled:** New features should default to off (`false`).
2. **Use clear names:** Flag names should be self-explanatory.
3. **Document risk level:** Always document the potential impact of enabling a flag.
4. **Test before enabling:** Features should be fully tested in development before flag rollout.
5. **Monitor usage:** When rolling out to production, monitor logs for errors or performance issues.

## Security Considerations

- Feature flags are **environment variables** and should be managed as configuration, not secrets.
- Never commit actual feature flag values to the repository.
- Use secret managers (e.g., GCP Secret Manager) for production environments.
- Document which flags are active in which environment.

## CI/CD Integration

Feature flags can be set in GitHub Actions workflows:

```yaml
env:
  FEATURE_FLAG_CSV_IMPORT: ${{ vars.FEATURE_FLAG_CSV_IMPORT }}
```

Or in GitHub repository variables/settings for different environments.

## Troubleshooting

### Flag Not Working

1. Check the exact spelling of the environment variable (case-sensitive).
2. Verify the value is `1`, `true`, or `TRUE` (case-insensitive).
3. Restart the application after changing environment variables.
4. Check logs for any error messages.

### Feature Still Disabled Despite Setting Flag

1. Ensure the flag is being read in the correct environment (dev/stage/prod).
2. Verify the code is using `isEnabled('FLAG_NAME')` correctly.
3. Check for any caching mechanisms that might need clearing.

## Related Files

- `packages/shared/lib/featureFlags.ts` - Feature flag implementation
- `packages/shared/lib/csvImport.ts` - Example of feature guarded by flag

## Reference

See `AGENTS.md` for project operating rules and agent guidelines.
