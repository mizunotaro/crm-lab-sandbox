import { Customer } from "@crm/shared";

export interface CustomerDetailData {
  customer: Customer;
}

export function renderCustomerDetailHtml(data: CustomerDetailData): string {
  const { customer } = data;

  const tagsHtml =
    customer.tags.length === 0
      ? '<p class="text-gray-500 italic">No tags</p>'
      :       customer.tags
          .map(
            (tag: string) =>
              `<span class="rounded-full bg-blue-100 px-3 py-1 text-sm font-medium text-blue-800">${escapeHtml(
                tag
              )}</span>`
          )
          .join("");

  return `
<div class="container mx-auto p-6">
  <h1 class="mb-6 text-3xl font-bold">Customer Details</h1>
  <div class="rounded-lg border border-gray-200 p-6">
    <div class="mb-4">
      <h2 class="text-lg font-semibold">Name</h2>
      <p class="text-gray-700">${escapeHtml(customer.name)}</p>
    </div>
    <div class="mb-4">
      <h2 class="text-lg font-semibold">Email</h2>
      <p class="text-gray-700">${escapeHtml(customer.email)}</p>
    </div>
    <div class="mb-4">
      <h2 class="text-lg font-semibold">Tags</h2>
      <div class="mt-2 flex flex-wrap gap-2">
        ${tagsHtml}
      </div>
    </div>
  </div>
</div>`;
}

export function getCustomerDetailData(customerId: string): CustomerDetailData {
  return {
    customer: {
      id: customerId,
      name: "John Doe",
      email: "john.doe@example.com",
      tags: ["VIP", "Enterprise"]
    }
  };
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}