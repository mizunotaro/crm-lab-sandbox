export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

export interface AuthCredentials {
  email: string;
  password: string;
}

export interface AuthSession {
  token: string;
  user: AuthUser;
  expiresAt: string;
}

export interface LoginResult {
  success: boolean;
  session?: AuthSession;
  error?: string;
}

export interface ValidationResult {
  isValid: boolean;
  user?: AuthUser;
  error?: string;
}

export interface IAuthProvider {
  login(credentials: AuthCredentials): Promise<LoginResult>;
  logout(token: string): Promise<boolean>;
  validateSession(token: string): Promise<ValidationResult>;
}
