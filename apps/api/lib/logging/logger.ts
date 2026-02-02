export interface LogEntry {
  level: 'info' | 'warn' | 'error';
  message: string;
  durationMs?: number;
  statusCode?: number;
  [key: string]: any;
}

export class Logger {
  private shouldLogOutput: boolean;

  constructor(shouldLogOutput = true) {
    this.shouldLogOutput = shouldLogOutput;
  }

  private shouldLog(key: string): boolean {
    const sensitiveKeys = ['password', 'token', 'secret', 'apiKey', 'accessToken', 'refreshToken'];
    return !sensitiveKeys.some(sensitive => key.toLowerCase().includes(sensitive.toLowerCase()));
  }

  private sanitize(data: Record<string, any>): Record<string, any> {
    const sanitized: Record<string, any> = {};
    for (const [key, value] of Object.entries(data)) {
      if (this.shouldLog(key)) {
        sanitized[key] = value;
      }
    }
    return sanitized;
  }

  private log(entry: LogEntry): void {
    if (!this.shouldLogOutput) {
      return;
    }

    const sanitizedEntry = this.sanitize(entry);
    const timestamp = new Date().toISOString();
    const logLine = JSON.stringify({ timestamp, ...sanitizedEntry });
    
    switch (entry.level) {
      case 'error':
        console.error(logLine);
        break;
      case 'warn':
        console.warn(logLine);
        break;
      default:
        console.log(logLine);
    }
  }

  info(message: string, data: Record<string, any> = {}): void {
    this.log({ level: 'info', message, ...data });
  }

  warn(message: string, data: Record<string, any> = {}): void {
    this.log({ level: 'warn', message, ...data });
  }

  error(message: string, data: Record<string, any> = {}): void {
    this.log({ level: 'error', message, ...data });
  }
}

export const logger = new Logger();
