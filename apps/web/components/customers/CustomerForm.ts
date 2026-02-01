export function createCustomerFormSubmitHandler(
  onSubmit: (data: { name: string; email: string; tags: string[] }) => void
) {
  return (formData: { name: string; email: string; tagsInput: string }) => {
    const tags = formData.tagsInput
      .split(",")
      .map((tag) => tag.trim())
      .filter((tag) => tag.length > 0);

    onSubmit({
      name: formData.name,
      email: formData.email,
      tags
    });
  };
}

export function formatTagsForDisplay(tags: string[]): string {
  return tags.join(", ");
}

export function parseTagsFromInput(input: string): string[] {
  return input
    .split(",")
    .map((tag) => tag.trim())
    .filter((tag) => tag.length > 0);
}

export interface CustomerFormData {
  name: string;
  email: string;
  tagsInput: string;
}

export function createEmptyCustomerFormData(): CustomerFormData {
  return {
    name: "",
    email: "",
    tagsInput: ""
  };
}