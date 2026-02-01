import { describe, it, expect, beforeEach } from 'vitest';
import { LocalAuthProvider } from './localProvider';
import { IAuthProvider, LoginCredentials } from './provider';

describe('Auth Provider Tests', () => {
  let provider: IAuthProvider;

  beforeEach(() => {
    provider = new LocalAuthProvider();
  });

  describe('LocalAuthProvider - Login', () => {
    it('should successfully login with valid credentials', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'any-password',
      };

      const session = await provider.login(credentials);

      expect(session).toBeDefined();
      expect(session.token).toBeDefined();
      expect(session.userId).toBe('test-user-1');
      expect(session.expiresAt).toBeGreaterThan(Date.now());
    });

    it('should throw error with invalid email', async () => {
      const credentials: LoginCredentials = {
        email: 'invalid@example.com',
        password: 'any-password',
      };

      await expect(provider.login(credentials)).rejects.toThrow('Invalid credentials');
    });
  });

  describe('LocalAuthProvider - Validate Session', () => {
    it('should return user for valid session token', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'any-password',
      };

      const session = await provider.login(credentials);
      const user = await provider.validateSession(session.token);

      expect(user).toBeDefined();
      expect(user?.id).toBe('test-user-1');
      expect(user?.email).toBe('test@example.com');
      expect(user?.name).toBe('Test User');
    });

    it('should return null for invalid token', async () => {
      const user = await provider.validateSession('invalid-token');

      expect(user).toBeNull();
    });

    it('should return null for expired session', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'any-password',
      };

      const session = await provider.login(credentials);

      const providerInstance = provider as any;
      providerInstance.sessions.get(session.token).expiresAt = Date.now() - 1000;

      const user = await provider.validateSession(session.token);

      expect(user).toBeNull();
    });
  });

  describe('LocalAuthProvider - Logout', () => {
    it('should successfully logout valid session', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'any-password',
      };

      const session = await provider.login(credentials);
      await provider.logout(session.token);

      const user = await provider.validateSession(session.token);

      expect(user).toBeNull();
    });

    it('should handle logout of invalid token gracefully', async () => {
      await expect(provider.logout('invalid-token')).resolves.not.toThrow();
    });
  });

  describe('LocalAuthProvider - Get User By ID', () => {
    it('should return user for valid ID', async () => {
      const user = await provider.getUserById('test-user-1');

      expect(user).toBeDefined();
      expect(user?.id).toBe('test-user-1');
      expect(user?.email).toBe('test@example.com');
    });

    it('should return null for invalid ID', async () => {
      const user = await provider.getUserById('invalid-id');

      expect(user).toBeNull();
    });
  });

  describe('LocalAuthProvider - Multiple Sessions', () => {
    it('should create separate sessions for multiple logins', async () => {
      const credentials: LoginCredentials = {
        email: 'test@example.com',
        password: 'any-password',
      };

      const session1 = await provider.login(credentials);
      const session2 = await provider.login(credentials);

      expect(session1.token).not.toBe(session2.token);
      expect(session1.userId).toBe(session2.userId);

      const user1 = await provider.validateSession(session1.token);
      const user2 = await provider.validateSession(session2.token);

      expect(user1?.id).toBe(user2?.id);
    });
  });
});
