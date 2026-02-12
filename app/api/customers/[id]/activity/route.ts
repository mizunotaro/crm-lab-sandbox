import { NextRequest, NextResponse } from "next/server";

export type AuditEventType = "customer.created" | "customer.updated" | "customer.deleted" | "customer.viewed" | "customer.exported";

export interface AuditEvent {
  id: string;
  customerId: string;
  type: AuditEventType;
  actor: {
    id: string;
    name: string;
    role: string;
  };
  timestamp: string;
  details?: Record<string, unknown>;
}

export interface ActivityTimelineResponse {
  customerId: string;
  events: AuditEvent[];
  total: number;
  page?: number;
  pageSize?: number;
}

async function getAuthenticatedUserId(request: NextRequest): Promise<string | null> {
  const authHeader = request.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return null;
  }
  const token = authHeader.substring(7);
  return token;
}

async function getCustomerActivity(customerId: string): Promise<AuditEvent[]> {
  return [
    {
      id: "audit-001",
      customerId,
      type: "customer.created",
      actor: {
        id: "user-001",
        name: "Admin User",
        role: "admin",
      },
      timestamp: new Date("2024-01-15T10:00:00Z").toISOString(),
      details: {
        name: "John Doe",
        email: "john@example.com",
      },
    },
    {
      id: "audit-002",
      customerId,
      type: "customer.updated",
      actor: {
        id: "user-002",
        name: "Support Staff",
        role: "support",
      },
      timestamp: new Date("2024-01-20T14:30:00Z").toISOString(),
      details: {
        field: "phone",
        oldValue: null,
        newValue: "+1-555-0100",
      },
    },
  ];
}

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
): Promise<NextResponse<ActivityTimelineResponse | { error: string }>> {
  const customerId = params.id;
  
  const userId = await getAuthenticatedUserId(request);
  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const events = await getCustomerActivity(customerId);

  const response: ActivityTimelineResponse = {
    customerId,
    events,
    total: events.length,
  };

  return NextResponse.json(response);
}
