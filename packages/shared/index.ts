export const sharedHello = "shared";

export { isEnabled } from './lib/featureFlags';
export type { FeatureFlagName } from './lib/featureFlags';
export { importContactsFromCsv } from './lib/csvImport';
export type { Contact, CsvImportResult } from './lib/csvImport';

export type {
  AuthUser,
  AuthCredentials,
  AuthSession,
  LoginResult,
  ValidationResult,
  IAuthProvider,
} from './lib/auth/provider';
export { LocalAuthProvider } from './lib/auth/localProvider';
