export interface Contact {
  id: string;
  name: string;
  email: string;
  phone?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateContactRequest {
  name: string;
  email: string;
  phone?: string;
}

export interface UpdateContactRequest {
  name?: string;
  email?: string;
  phone?: string;
}

export interface ApiResponse<T> {
  data: T;
  success: true;
  timestamp: string;
}

export interface ErrorResponse {
  error: {
    code: string;
    message: string;
  };
  success: false;
  timestamp: string;
}

export type ApiResult<T> = ApiResponse<T> | ErrorResponse;

export function isApiError<T>(result: ApiResult<T>): result is ErrorResponse {
  return result.success === false;
}

export class ContactApi {
  private contacts: Contact[] = [];

  /**
   * Computes a monotonic updatedAt timestamp for a contact.
   * Ensures updatedAt is strictly greater than the previous updatedAt (or createdAt).
   */
  private computeNextUpdatedAt(existing: Contact): string {
    const nowMs = Date.now();
    const prevIso = existing.updatedAt || existing.createdAt;
    const prevMs = Date.parse(prevIso);
    const safePrevMs = Number.isFinite(prevMs) ? prevMs : 0;
    const nextMs = Math.max(nowMs, safePrevMs + 1);
    return new Date(nextMs).toISOString();
  }

  async listContacts(): Promise<ApiResponse<Contact[]>> {
    return {
      data: this.contacts,
      success: true,
      timestamp: new Date().toISOString(),
    };
  }

  async getContact(id: string): Promise<ApiResult<Contact>> {
    const contact = this.contacts.find(c => c.id === id);
    if (!contact) {
      return {
        error: {
          code: 'NOT_FOUND',
          message: `Contact with id ${id} not found`,
        },
        success: false,
        timestamp: new Date().toISOString(),
      };
    }
    return {
      data: contact,
      success: true,
      timestamp: new Date().toISOString(),
    };
  }

  async createContact(request: CreateContactRequest): Promise<ApiResponse<Contact>> {
    const nowIso = new Date().toISOString();
    const contact: Contact = {
      id: crypto.randomUUID(),
      name: request.name,
      email: request.email,
      phone: request.phone,
      createdAt: nowIso,
      updatedAt: nowIso,
    };
    this.contacts.push(contact);
    return {
      data: contact,
      success: true,
      timestamp: new Date().toISOString(),
    };
  }

  async updateContact(id: string, request: UpdateContactRequest): Promise<ApiResult<Contact>> {
    const index = this.contacts.findIndex(c => c.id === id);
    if (index === -1) {
      return {
        error: {
          code: 'NOT_FOUND',
          message: `Contact with id ${id} not found`,
        },
        success: false,
        timestamp: new Date().toISOString(),
      };
    }
    const existing = this.contacts[index];
    this.contacts[index] = {
      ...existing,
      ...request,
      updatedAt: this.computeNextUpdatedAt(existing),
    };
    return {
      data: this.contacts[index],
      success: true,
      timestamp: new Date().toISOString(),
    };
  }

  async deleteContact(id: string): Promise<ApiResult<{ id: string }>> {
    const index = this.contacts.findIndex(c => c.id === id);
    if (index === -1) {
      return {
        error: {
          code: 'NOT_FOUND',
          message: `Contact with id ${id} not found`,
        },
        success: false,
        timestamp: new Date().toISOString(),
      };
    }
    this.contacts.splice(index, 1);
    return {
      data: { id },
      success: true,
      timestamp: new Date().toISOString(),
    };
  }
}

export const contactApi = new ContactApi();
