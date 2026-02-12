import { describe, it, expect, beforeEach } from "vitest";
import { GET } from "../../app/api/customers/[id]/activity/route";
import { NextRequest } from "next/server";

const mockCustomerId = "customer-123";

describe("GET /api/customers/:id/activity", () => {
  beforeEach(() => {
  });

  it("should return 401 when no authorization header is provided", async () => {
    const request = new NextRequest(new Request(`http://localhost:3000/api/customers/${mockCustomerId}/activity`));
    
    const response = await GET(request, { params: { id: mockCustomerId } });
    
    expect(response.status).toBe(401);
    const data = await response.json();
    expect(data).toEqual({ error: "Unauthorized" });
  });

  it("should return 401 when invalid authorization header is provided", async () => {
    const request = new NextRequest(new Request(`http://localhost:3000/api/customers/${mockCustomerId}/activity`, {
      headers: {
        authorization: "Invalid token",
      },
    }));
    
    const response = await GET(request, { params: { id: mockCustomerId } });
    
    expect(response.status).toBe(401);
    const data = await response.json();
    expect(data).toEqual({ error: "Unauthorized" });
  });

  it("should return 200 and activity timeline when authorized", async () => {
    const request = new NextRequest(new Request(`http://localhost:3000/api/customers/${mockCustomerId}/activity`, {
      headers: {
        authorization: "Bearer valid-token",
      },
    }));
    
    const response = await GET(request, { params: { id: mockCustomerId } });
    
    expect(response.status).toBe(200);
    const data = await response.json();
    
    expect(data).toHaveProperty("customerId", mockCustomerId);
    expect(data).toHaveProperty("events");
    expect(Array.isArray(data.events)).toBe(true);
    expect(data).toHaveProperty("total");
    expect(typeof data.total).toBe("number");
    
    if (data.events.length > 0) {
      const event = data.events[0];
      expect(event).toHaveProperty("id");
      expect(event).toHaveProperty("customerId");
      expect(event).toHaveProperty("type");
      expect(event).toHaveProperty("actor");
      expect(event).toHaveProperty("timestamp");
      
      expect(event.actor).toHaveProperty("id");
      expect(event.actor).toHaveProperty("name");
      expect(event.actor).toHaveProperty("role");
    }
  });

  it("should return customer-related audit events only", async () => {
    const request = new NextRequest(new Request(`http://localhost:3000/api/customers/${mockCustomerId}/activity`, {
      headers: {
        authorization: "Bearer valid-token",
      },
    }));
    
    const response = await GET(request, { params: { id: mockCustomerId } });
    const data = await response.json();
    
    expect(Array.isArray(data.events)).toBe(true);
    
    const validEventTypes = ["customer.created", "customer.updated", "customer.deleted", "customer.viewed", "customer.exported"];
    data.events.forEach((event: unknown) => {
      expect(validEventTypes).toContain((event as { type: string }).type);
    });
  });

  it("should return events in descending chronological order", async () => {
    const request = new NextRequest(new Request(`http://localhost:3000/api/customers/${mockCustomerId}/activity`, {
      headers: {
        authorization: "Bearer valid-token",
      },
    }));
    
    const response = await GET(request, { params: { id: mockCustomerId } });
    const data = await response.json();
    
    if (data.events.length > 1) {
      for (let i = 0; i < data.events.length - 1; i++) {
        const current = new Date(data.events[i].timestamp).getTime();
        const next = new Date(data.events[i + 1].timestamp).getTime();
        expect(current).toBeGreaterThanOrEqual(next);
      }
    }
  });
});
