export type FeatureFlagName = 'CSV_IMPORT' | 'BULK_EXPORT' | string;

export function isEnabled(flagName: FeatureFlagName): boolean {
  const envVarName = `FEATURE_FLAG_${flagName}`;
  const envValue = process.env[envVarName];

  if (envValue === undefined) {
    return false;
  }

  return envValue === '1' || envValue === 'true' || envValue === 'TRUE';
}
