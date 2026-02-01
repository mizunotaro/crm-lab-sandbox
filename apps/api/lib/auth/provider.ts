export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

export interface AuthSession {
  userId: string;
  token: string;
  expiresAt: number;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface IAuthProvider {
  login(credentials: LoginCredentials): Promise<AuthSession>;
  logout(token: string): Promise<void>;
  validateSession(token: string): Promise<AuthUser | null>;
  getUserById(userId: string): Promise<AuthUser | null>;
}
