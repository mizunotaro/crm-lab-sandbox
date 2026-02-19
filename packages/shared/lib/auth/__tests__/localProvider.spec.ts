import { describe, it, expect, vi, beforeEach } from 'vitest';
import { LocalAuthProvider } from '../localProvider';

describe('LocalAuthProvider', () => {
  let provider: LocalAuthProvider;

  beforeEach(() => {
    provider = new LocalAuthProvider();
  });

  describe('login', () => {
    it('should return session with valid credentials', async () => {
      const result = await provider.login({
        email: 'demo@example.com',
        password: 'password',
      });

      expect(result.success).toBe(true);
      expect(result.session).toBeDefined();
      expect(result.session?.user.email).toBe('demo@example.com');
      expect(result.session?.token).toBeDefined();
    });

    it('should return error with invalid credentials', async () => {
      const result = await provider.login({
        email: 'invalid@example.com',
        password: 'wrongpassword',
      });

      expect(result.success).toBe(false);
      expect(result.error).toBe('Invalid email or password');
      expect(result.session).toBeUndefined();
    });

    it('should return error with missing fields', async () => {
      const result1 = await provider.login({
        email: '',
        password: 'password',
      });

      expect(result1.success).toBe(false);
      expect(result1.error).toBe('Email and password are required');

      const result2 = await provider.login({
        email: 'demo@example.com',
        password: '',
      });

      expect(result2.success).toBe(false);
      expect(result2.error).toBe('Email and password are required');
    });
  });

  describe('validateSession', () => {
    it('should validate a valid session', async () => {
      const loginResult = await provider.login({
        email: 'demo@example.com',
        password: 'password',
      });

      expect(loginResult.session).toBeDefined();

      const validateResult = await provider.validateSession(loginResult.session!.token);

      expect(validateResult.isValid).toBe(true);
      expect(validateResult.user?.email).toBe('demo@example.com');
    });

    it('should return error for invalid token', async () => {
      const validateResult = await provider.validateSession('invalid-token');

      expect(validateResult.isValid).toBe(false);
      expect(validateResult.error).toBe('Invalid session token');
    });

    it('should expire session after duration', async () => {
      vi.useFakeTimers();

      const loginResult = await provider.login({
        email: 'demo@example.com',
        password: 'password',
      });

      expect(loginResult.session).toBeDefined();

      vi.advanceTimersByTime(25 * 60 * 60 * 1000);

      const validateResult = await provider.validateSession(loginResult.session!.token);

      expect(validateResult.isValid).toBe(false);
      expect(validateResult.error).toBe('Session expired');

      vi.useRealTimers();
    });
  });

  describe('logout', () => {
    it('should invalidate a valid session', async () => {
      const loginResult = await provider.login({
        email: 'demo@example.com',
        password: 'password',
      });

      expect(loginResult.session).toBeDefined();

      const logoutResult = await provider.logout(loginResult.session!.token);
      expect(logoutResult).toBe(true);

      const validateResult = await provider.validateSession(loginResult.session!.token);
      expect(validateResult.isValid).toBe(false);
    });

    it('should return false for invalid token', async () => {
      const logoutResult = await provider.logout('invalid-token');
      expect(logoutResult).toBe(false);
    });
  });
});
