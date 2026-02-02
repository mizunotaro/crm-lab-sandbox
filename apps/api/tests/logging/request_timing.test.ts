import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { withTiming, createTimedWrapper } from '../../middleware';
import { Logger } from '../../lib/logging/logger';

describe('Request Timing Middleware', () => {
  let testLogger: Logger;

  beforeEach(() => {
    testLogger = new Logger(true);
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('withTiming', () => {
    it('should log durationMs and statusCode for successful operation', async () => {
      const mockFn = async () => ({ success: true, data: 'test' });
      
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      await withTiming(mockFn, { operationName: 'testOperation', loggerInstance: testLogger });
      
      expect(consoleLogSpy).toHaveBeenCalled();
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('durationMs');
      expect(logData).toHaveProperty('statusCode', 200);
      expect(logData).toHaveProperty('operationName', 'testOperation');
      expect(typeof logData.durationMs).toBe('number');
      expect(logData.durationMs).toBeGreaterThanOrEqual(0);
    });

    it('should log durationMs and statusCode for failed operation', async () => {
      const mockFn = async () => {
        throw new Error('Test error');
      };
      
      const consoleErrorSpy = vi.spyOn(console, 'error');
      
      await expect(withTiming(mockFn, { operationName: 'testOperation', loggerInstance: testLogger }))
        .rejects.toThrow('Test error');
      
      expect(consoleErrorSpy).toHaveBeenCalled();
      const logCall = consoleErrorSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('durationMs');
      expect(logData).toHaveProperty('statusCode', 500);
      expect(logData).toHaveProperty('operationName', 'testOperation');
      expect(typeof logData.durationMs).toBe('number');
      expect(logData.durationMs).toBeGreaterThanOrEqual(0);
    });

    it('should respect logSuccess option', async () => {
      const mockFn = async () => ({ success: true, data: 'test' });
      
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      await withTiming(mockFn, { operationName: 'testOperation', logSuccess: false, loggerInstance: testLogger });
      
      expect(consoleLogSpy).not.toHaveBeenCalled();
    });

    it('should respect logError option', async () => {
      const mockFn = async () => {
        throw new Error('Test error');
      };
      
      const consoleErrorSpy = vi.spyOn(console, 'error');
      
      await expect(withTiming(mockFn, { operationName: 'testOperation', logError: false, loggerInstance: testLogger }))
        .rejects.toThrow('Test error');
      
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    });
  });

  describe('createTimedWrapper', () => {
    it('should create a wrapped function that logs timing', async () => {
      const mockFn = async (input: string) => ({ result: input });
      
      const wrappedFn = createTimedWrapper(mockFn, 'wrappedOperation', testLogger);
      
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      const result = await wrappedFn('test');
      
      expect(result).toEqual({ result: 'test' });
      expect(consoleLogSpy).toHaveBeenCalled();
      
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('durationMs');
      expect(logData).toHaveProperty('statusCode', 200);
      expect(logData).toHaveProperty('operationName', 'wrappedOperation');
    });
  });

  describe('Logger sensitive field filtering', () => {
    it('should not log sensitive fields', () => {
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      testLogger.info('Test message', {
        username: 'testuser',
        email: 'test@example.com',
        password: 'secret123',
        accessToken: 'token123',
        apiKey: 'key123',
      });
      
      expect(consoleLogSpy).toHaveBeenCalled();
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('username', 'testuser');
      expect(logData).toHaveProperty('email', 'test@example.com');
      expect(logData).not.toHaveProperty('password');
      expect(logData).not.toHaveProperty('accessToken');
      expect(logData).not.toHaveProperty('apiKey');
    });

    it('should filter case-insensitive sensitive fields', () => {
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      testLogger.info('Test message', {
        PASSWORD: 'secret123',
        AccessToken: 'token123',
      });
      
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).not.toHaveProperty('PASSWORD');
      expect(logData).not.toHaveProperty('AccessToken');
    });

    it('should filter secret field', () => {
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      testLogger.info('Test message', {
        secret: 'mysecret',
        normal: 'value',
      });
      
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('normal', 'value');
      expect(logData).not.toHaveProperty('secret');
    });

    it('should filter refreshToken field', () => {
      const consoleLogSpy = vi.spyOn(console, 'log');
      
      testLogger.info('Test message', {
        refreshToken: 'refresh123',
        normal: 'value',
      });
      
      const logCall = consoleLogSpy.mock.calls[0]?.[0] as string;
      const logData = JSON.parse(logCall);
      
      expect(logData).toHaveProperty('normal', 'value');
      expect(logData).not.toHaveProperty('refreshToken');
    });
  });
});
