import { SessionStore, SessionData, InMemorySessionStore } from "./sessionStore";

export class SessionManager {
  private store: SessionStore;

  constructor(store?: SessionStore) {
    this.store = store ?? new InMemorySessionStore();
  }

  async get(sessionId: string): Promise<SessionData | null> {
    return this.store.get(sessionId);
  }

  async set(sessionId: string, data: SessionData, ttl?: number): Promise<void> {
    return this.store.set(sessionId, data, ttl);
  }

  async delete(sessionId: string): Promise<void> {
    return this.store.delete(sessionId);
  }
}
