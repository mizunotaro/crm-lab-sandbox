import { Metadata } from "next";
import ActivityTimeline from "@/components/customers/ActivityTimeline";
import { Activity, Customer } from "@crm/shared";

async function fetchCustomer(id: string): Promise<Customer | null> {
  return {
    id,
    name: "John Doe",
    email: "john.doe@example.com",
    company: "Example Corp",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

async function fetchCustomerActivities(
  customerId: string
): Promise<Activity[]> {
  return [];
}

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const customer = await fetchCustomer(params.id);

  return {
    title: customer ? `${customer.name} - CRM` : "Customer Not Found",
  };
}

export default async function CustomerDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const customer = await fetchCustomer(params.id);

  if (!customer) {
    return (
      <div>
        <h1>Customer Not Found</h1>
      </div>
    );
  }

  const activities = await fetchCustomerActivities(customer.id);

  return (
    <div className="customer-detail">
      <div className="customer-header">
        <h1>{customer.name}</h1>
        <p>{customer.email}</p>
        {customer.company && <p>{customer.company}</p>}
      </div>

      <ActivityTimeline activities={activities} />

      <style jsx global>{`
        body {
          font-family: system-ui, -apple-system, sans-serif;
          background: #f9fafb;
          padding: 24px;
        }

        .customer-detail {
          max-width: 800px;
          margin: 0 auto;
        }

        .customer-header {
          background: #fff;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 24px;
          margin-bottom: 24px;
        }

        .customer-header h1 {
          margin: 0 0 8px 0;
          font-size: 24px;
        }

        .customer-header p {
          margin: 4px 0;
          color: #6b7280;
        }
      `}</style>
    </div>
  );
}
