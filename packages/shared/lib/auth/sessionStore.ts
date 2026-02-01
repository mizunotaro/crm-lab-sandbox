export interface SessionData {
  [key: string]: unknown;
}

export interface SessionStore {
  get(sessionId: string): Promise<SessionData | null>;
  set(sessionId: string, data: SessionData, ttl?: number): Promise<void>;
  delete(sessionId: string): Promise<void>;
}

export class InMemorySessionStore implements SessionStore {
  private store = new Map<string, { data: SessionData; expires: number }>();

  async get(sessionId: string): Promise<SessionData | null> {
    const entry = this.store.get(sessionId);
    if (!entry) return null;

    if (entry.expires < Date.now()) {
      this.store.delete(sessionId);
      return null;
    }

    return entry.data;
  }

  async set(sessionId: string, data: SessionData, ttl: number = 3600000): Promise<void> {
    const expires = Date.now() + ttl;
    this.store.set(sessionId, { data, expires });
  }

  async delete(sessionId: string): Promise<void> {
    this.store.delete(sessionId);
  }
}
