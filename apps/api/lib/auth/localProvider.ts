import { IAuthProvider, AuthUser, AuthSession, LoginCredentials } from './provider';

export class LocalAuthProvider implements IAuthProvider {
  private users: Map<string, AuthUser> = new Map();
  private sessions: Map<string, AuthSession> = new Map();

  constructor() {
    this.seedTestUser();
  }

  private seedTestUser(): void {
    const testUser: AuthUser = {
      id: 'test-user-1',
      email: 'test@example.com',
      name: 'Test User',
    };
    this.users.set(testUser.id, testUser);
  }

  async login(credentials: LoginCredentials): Promise<AuthSession> {
    const user = Array.from(this.users.values()).find(
      u => u.email === credentials.email
    );

    if (!user) {
      throw new Error('Invalid credentials');
    }

    const token = crypto.randomUUID();
    const expiresAt = Date.now() + 24 * 60 * 60 * 1000;

    const session: AuthSession = {
      userId: user.id,
      token,
      expiresAt,
    };

    this.sessions.set(token, session);

    return session;
  }

  async logout(token: string): Promise<void> {
    this.sessions.delete(token);
  }

  async validateSession(token: string): Promise<AuthUser | null> {
    const session = this.sessions.get(token);
    if (!session || session.token !== token) {
      return null;
    }

    if (Date.now() > session.expiresAt) {
      this.sessions.delete(token);
      return null;
    }

    return this.users.get(session.userId) || null;
  }

  async getUserById(userId: string): Promise<AuthUser | null> {
    return this.users.get(userId) || null;
  }
}
