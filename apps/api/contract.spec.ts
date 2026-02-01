import { describe, it, expect, beforeEach } from 'vitest';
import { contactApi, isApiError } from './contacts';

describe('API Contract Tests - Contact Management', () => {
  beforeEach(() => {
    const api = contactApi as any;
    api.contacts = [];
  });

  describe('Response Structure Contracts', () => {
    it('should return valid API response shape for successful operations', async () => {
      const result = await contactApi.listContacts();
      
      expect(result).toMatchObject({
        data: expect.any(Array),
        success: true,
        timestamp: expect.any(String),
      });
      
      expect(result.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    });

    it('should return valid error response shape for failed operations', async () => {
      const result = await contactApi.getContact('nonexistent-id');
      
      expect(result).toMatchObject({
        error: {
          code: expect.any(String),
          message: expect.any(String),
        },
        success: false,
        timestamp: expect.any(String),
      });
    });
  });

  describe('listContacts Endpoint', () => {
    it('should return empty array when no contacts exist', async () => {
      const result = await contactApi.listContacts();
      
      expect(result.success).toBe(true);
      expect(result.data).toEqual([]);
      expect(Array.isArray(result.data)).toBe(true);
    });

    it('should return array of contacts when contacts exist', async () => {
      await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      const result = await contactApi.listContacts();
      
      expect(result.success).toBe(true);
      expect(result.data).toHaveLength(1);
      expect(result.data[0]).toMatchObject({
        id: expect.any(String),
        name: 'Test User',
        email: 'test@example.com',
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      });
    });
  });

  describe('getContact Endpoint', () => {
    it('should return contact with correct structure when found', async () => {
      const created = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      const result = await contactApi.getContact(created.data.id);
      
      if (result.success) {
        expect(result.data).toMatchObject({
          id: created.data.id,
          name: 'Test User',
          email: 'test@example.com',
          createdAt: expect.any(String),
          updatedAt: expect.any(String),
        });
      } else {
        throw new Error('Expected successful response');
      }
    });

    it('should return error response when contact not found', async () => {
      const result = await contactApi.getContact('nonexistent-id');
      
      if (isApiError(result)) {
        expect(result.error.code).toBe('NOT_FOUND');
        expect(result.error.message).toContain('not found');
      } else {
        throw new Error('Expected error response');
      }
    });
  });

  describe('createContact Endpoint', () => {
    it('should return created contact with id and timestamps', async () => {
      const result = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
      });
      
      expect(result.success).toBe(true);
      expect(result.data).toMatchObject({
        id: expect.any(String),
        name: 'Test User',
        email: 'test@example.com',
        phone: '+1234567890',
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      });
      
      expect(result.data.id).toMatch(/^[a-f0-9-]{36}$/);
      expect(result.data.createdAt).toBe(result.data.updatedAt);
    });

    it('should create contact without optional phone field', async () => {
      const result = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      expect(result.success).toBe(true);
      expect(result.data.phone).toBeUndefined();
    });
  });

  describe('updateContact Endpoint', () => {
    it('should return updated contact with changed fields', async () => {
      const created = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      await new Promise(resolve => setTimeout(resolve, 1));
      
      const result = await contactApi.updateContact(created.data.id, {
        name: 'Updated User',
        phone: '+9876543210',
      });
      
      if (result.success) {
        expect(result.data).toMatchObject({
          id: created.data.id,
          name: 'Updated User',
          email: 'test@example.com',
          phone: '+9876543210',
          createdAt: created.data.createdAt,
          updatedAt: expect.any(String),
        });
        
        expect(result.data.updatedAt).not.toBe(result.data.createdAt);
      } else {
        throw new Error('Expected successful response');
      }
    });

    it('should return error when updating nonexistent contact', async () => {
      const result = await contactApi.updateContact('nonexistent-id', {
        name: 'Updated User',
      });
      
      if (isApiError(result)) {
        expect(result.error.code).toBe('NOT_FOUND');
      } else {
        throw new Error('Expected error response');
      }
    });
  });

  describe('deleteContact Endpoint', () => {
    it('should return confirmation with deleted id', async () => {
      const created = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      const result = await contactApi.deleteContact(created.data.id);
      
      if (result.success) {
        expect(result.data).toEqual({ id: created.data.id });
      } else {
        throw new Error('Expected successful response');
      }
    });

    it('should return error when deleting nonexistent contact', async () => {
      const result = await contactApi.deleteContact('nonexistent-id');
      
      if (isApiError(result)) {
        expect(result.error.code).toBe('NOT_FOUND');
      } else {
        throw new Error('Expected error response');
      }
    });

    it('should actually remove the contact', async () => {
      const created = await contactApi.createContact({
        name: 'Test User',
        email: 'test@example.com',
      });
      
      await contactApi.deleteContact(created.data.id);
      const getAfterDelete = await contactApi.getContact(created.data.id);
      
      if (isApiError(getAfterDelete)) {
        expect(getAfterDelete.error.code).toBe('NOT_FOUND');
      } else {
        throw new Error('Expected error response');
      }
    });
  });
});
