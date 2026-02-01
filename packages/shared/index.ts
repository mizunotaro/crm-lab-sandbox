export interface Customer {
  id: string;
  name: string;
  email: string;
  tags: string[];
}

export interface CustomerFormData {
  name: string;
  email: string;
  tags: string;
}
