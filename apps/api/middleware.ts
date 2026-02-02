import { logger, Logger as LoggerClass } from './lib/logging/logger';

export interface TimingOptions {
  operationName: string;
  logSuccess?: boolean;
  logError?: boolean;
  loggerInstance?: LoggerClass;
}

export async function withTiming<T>(
  fn: () => Promise<T>,
  options: TimingOptions
): Promise<T> {
  const startTime = performance.now();
  const { operationName, logSuccess = true, logError = true, loggerInstance = logger } = options;

  try {
    const result = await fn();
    const durationMs = performance.now() - startTime;

    if (logSuccess) {
      loggerInstance.info(`${operationName} completed`, {
        operationName,
        durationMs,
        statusCode: 200,
      });
    }

    return result;
  } catch (error) {
    const durationMs = performance.now() - startTime;
    const statusCode = (error as any)?.statusCode || 500;

    if (logError) {
      loggerInstance.error(`${operationName} failed`, {
        operationName,
        durationMs,
        statusCode,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    throw error;
  }
}

export function createTimedWrapper<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  operationName: string,
  loggerInstance?: LoggerClass
): T {
  return (async (...args: Parameters<T>) => {
    return withTiming(() => fn(...args), { operationName, loggerInstance });
  }) as T;
}
