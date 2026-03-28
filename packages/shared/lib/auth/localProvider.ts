import type {
  IAuthProvider,
  AuthCredentials,
  AuthSession,
  AuthUser,
  LoginResult,
  ValidationResult,
} from './provider';

export class LocalAuthProvider implements IAuthProvider {
  private sessions: Map<string, AuthSession> = new Map();

  private readonly SESSION_DURATION_MS = 24 * 60 * 60 * 1000;

  async login(credentials: AuthCredentials): Promise<LoginResult> {
    if (!credentials.email || !credentials.password) {
      return {
        success: false,
        error: 'Email and password are required',
      };
    }

    const user = this.authenticateLocalUser(credentials);
    if (!user) {
      return {
        success: false,
        error: 'Invalid email or password',
      };
    }

    const expiresAt = new Date(Date.now() + this.SESSION_DURATION_MS).toISOString();
    const token = this.generateToken(user.id, expiresAt);

    const session: AuthSession = {
      token,
      user,
      expiresAt,
    };

    this.sessions.set(token, session);

    return {
      success: true,
      session,
    };
  }

  async logout(token: string): Promise<boolean> {
    if (!this.sessions.has(token)) {
      return false;
    }
    this.sessions.delete(token);
    return true;
  }

  async validateSession(token: string): Promise<ValidationResult> {
    const session = this.sessions.get(token);

    if (!session) {
      return {
        isValid: false,
        error: 'Invalid session token',
      };
    }

    const now = new Date();
    const expiresAt = new Date(session.expiresAt);

    if (now > expiresAt) {
      this.sessions.delete(token);
      return {
        isValid: false,
        error: 'Session expired',
      };
    }

    return {
      isValid: true,
      user: session.user,
    };
  }

  private authenticateLocalUser(credentials: AuthCredentials): AuthUser | null {
    if (credentials.email === 'demo@example.com' && credentials.password === 'password') {
      return {
        id: 'demo-user-id',
        email: 'demo@example.com',
        name: 'Demo User',
      };
    }

    return null;
  }

  private generateToken(userId: string, expiresAt: string): string {
    const payload = btoa(JSON.stringify({ userId, expiresAt }));
    const signature = btoa(`${payload}.${userId}`);
    return `${payload}.${signature}`;
  }
}
